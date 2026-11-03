--!strict
-- UI del bloque Steal (como Steal An Egg o Steal a Brainrot):
-- - Robando (KitFx "Carrying"): aviso y flechas en el piso hasta la base propia; se van al entregar o
--   al caerse lo robado. Robado con éxito: popup con lo conseguido.
-- - Te roban (KitFx "BeingStolen"): alarma con el nombre del ladrón y la cámara tiembla; "Push" en la
--   barra de acción cuando hay alguien a tu alcance, para empujar al más cercano (PushPlayer).
-- - Por qué se cayó lo robado (DIED, PUSHED, TIMEOUT, GONE, LEFT, FULL) y si frenaste al ladrón.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local ActionBar = require("./ActionBar")
local KitUi = require("./KitUi")

local Steal = {}

local player = Players.LocalPlayer

local BUTTON = "Push"
local CHECK_EVERY = 0.2

local function root(p: Player): BasePart?
	local character = p.Character
	local part = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if part and part:IsA("BasePart") then part else nil
end

-- La base propia: el KitSpawn de la base cuyo dueño es este jugador.
local function homeSpawn(): BasePart?
	for _, plot in CollectionService:GetTagged(Tags.PLOT) do
		if plot:GetAttribute(Tags.OWNER) == player.UserId then
			for _, part in plot:GetDescendants() do
				if part:IsA("BasePart") and part:HasTag(Tags.SPAWN) then
					return part
				end
			end
			return plot:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	return nil
end

function Steal.start(_hud: HudController.Hud)
	local cfg = KitConfig.steal
	if not cfg then
		return
	end
	local range = cfg.pushRange
	local target: Player? = nil

	ActionBar.add(BUTTON, {
		text = UiText.PROMPT_PUSH,
		icon = "battle",
		variant = "Close",
		order = 5,
		key = Enum.KeyCode.Q,
		onClick = function()
			local t = target
			if t then
				KitUi.fire("PushPlayer", t.UserId)
				local button = ActionBar.get(BUTTON)
				if button then
					Juice.pop(button, 0.12)
				end
			end
		end,
	})
	ActionBar.show(BUTTON, false)
	-- "Push" aparece con alguien a tu alcance (el servidor igual mide la distancia).
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			local mine = root(player)
			local best: Player? = nil
			local bestDistance = range
			if mine then
				for _, other in Players:GetPlayers() do
					local theirs = if other ~= player then root(other) else nil
					if theirs then
						local distance = (theirs.Position - mine.Position).Magnitude
						if distance <= bestDistance then
							best = other
							bestDistance = distance
						end
					end
				end
			end
			target = best
			ActionBar.show(BUTTON, best ~= nil)
		end
	end)

	local function clearPath()
		Bus.call("ShowPath", nil)
	end

	Bus.on("Kit:Carrying", function(payload: any)
		local name = if typeof(payload) == "table" and typeof(payload.name) == "string" then payload.name else ""
		Sound.play("Whoosh")
		KitUi.notify(string.format(UiText.CARRYING, name), "Premium", "base")
		local spawn = homeSpawn()
		if spawn then
			Bus.call("ShowPath", spawn)
		end
	end)
	Bus.on("Kit:Stole", function(payload: any)
		clearPath()
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			KitUi.showUnit({ kind = payload.kind, variant = payload.variant, size = payload.size }, "Steal")
		end
	end)
	Bus.on("Kit:StealFailed", function(payload: any)
		clearPath()
		local reason = if typeof(payload) == "table" then payload.reason else nil
		local text = if reason == "PUSHED" or reason == "DIED" then UiText.DROPPED
			elseif reason == "TIMEOUT" then UiText.TOO_SLOW
			elseif reason == "LEFT" then UiText.OWNER_LEFT
			elseif reason == "FULL" then UiText.INVENTORY_FULL
			else UiText.ERR_GONE
		Sound.play("Error")
		KitUi.notify(text, "Close", "battle")
	end)
	Bus.on("Kit:BeingStolen", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		Sound.play("Error")
		Juice.cameraShake(0.3, 0.35)
		KitUi.notify(string.format(UiText.STEALING_YOURS, tostring(payload.thief), tostring(payload.name)), "Close", "lock")
	end)
	Bus.on("Kit:StealStopped", function(payload: any)
		local reason = if typeof(payload) == "table" then payload.reason else nil
		if reason == "PUSHED" or reason == "DIED" or reason == "TIMEOUT" then
			Sound.play("Reward")
			KitUi.notify(UiText.STOPPED_THIEF, "Accept", "shield")
		end
	end)
	Bus.on("Kit:WasStolen", function(payload: any)
		if typeof(payload) == "table" then
			Sound.play("Error")
			KitUi.notify(string.format(UiText.WAS_STOLEN, tostring(payload.thief), tostring(payload.name)), "Close", "lock")
		end
	end)
	Bus.on("Kit:Pushed", function(payload: any)
		if typeof(payload) == "table" then
			Sound.play("Whoosh")
			Juice.cameraShake(0.6, 0.35)
			KitUi.notify(string.format(UiText.PUSHED_BY, tostring(payload.by)), "Close", "battle")
		end
	end)
end

return Steal
