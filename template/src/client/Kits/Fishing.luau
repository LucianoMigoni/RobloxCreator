--!strict
-- UI del bloque Fishing (Fish It!, Fisch):
-- - "Cast" en la barra de acción cerca del agua (KitWater, al alcance de la caña). Lanzado, espera la
--   picada; al picar (KitFx "Bite") el botón pasa a "REEL!", late, suena y aparece "!" sobre la cabeza:
--   hay `reelSeconds` para tocarlo. Tocar mientras espera no hace nada (no arruina el lance).
-- - Lo pescado: popup con nombre, mutación y kilos si es nuevo o raro; si no, un aviso corto.
-- - Ventana "Rods" (menú, Bus "OpenRods" o un puesto con Window "Rods"): la equipada, las que tiene y
--   las que se compran, con monedas o por Robux.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local ActionBar = require("./ActionBar")
local Gear = require("./Gear")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Fishing = {}

local player = Players.LocalPlayer

local DEFAULT_RANGE = 40
local CHECK_EVERY = 0.25
local BUTTON = "Fish"

-- Distancia al borde del agua más cercana (como la mide el servidor).
local function waterDistance(root: BasePart): number
	local best = math.huge
	for _, water in CollectionService:GetTagged(Tags.WATER) do
		local part = if water:IsA("BasePart") then water else water:FindFirstChildWhichIsA("BasePart", true)
		if part then
			local relative = part.CFrame:PointToObjectSpace(root.Position)
			local clamped = Vector3.new(
				math.clamp(relative.X, -part.Size.X / 2, part.Size.X / 2),
				math.clamp(relative.Y, -part.Size.Y / 2, part.Size.Y / 2),
				math.clamp(relative.Z, -part.Size.Z / 2, part.Size.Z / 2)
			)
			best = math.min(best, (relative - clamped).Magnitude)
		end
	end
	return best
end

function Fishing.start(_hud: HudController.Hud)
	local cfg = KitConfig.fishing
	if not cfg then
		return
	end
	local range = cfg.castRange or DEFAULT_RANGE
	local state: "idle" | "waiting" | "bite" = "idle"
	local biteUntil = 0
	local stopPulse: Juice.Stop? = nil
	local mark: BillboardGui? = nil
	local fishing: KitTypes.FishingState? = nil

	local function clearMark()
		local m = mark
		if m then
			m:Destroy()
			mark = nil
		end
	end

	local function setState(new: "idle" | "waiting" | "bite")
		state = new
		if stopPulse then
			stopPulse()
			stopPulse = nil
		end
		local button = ActionBar.get(BUTTON)
		if new == "idle" then
			ActionBar.setText(BUTTON, UiText.CAST)
			if button then
				UIKit.recolor(button, "Info")
			end
			clearMark()
		elseif new == "waiting" then
			ActionBar.setText(BUTTON, UiText.WAITING)
			if button then
				UIKit.recolor(button, "Neutral")
			end
		else
			ActionBar.setText(BUTTON, UiText.REEL)
			if button then
				UIKit.recolor(button, "Premium")
				stopPulse = Juice.pulse(button, 0.12, 0.4)
			end
		end
	end

	local function showMark()
		clearMark()
		local character = player.Character
		local head = if character then character:FindFirstChild("Head") else nil
		if not head or not head:IsA("BasePart") then
			return
		end
		local gui = Instance.new("BillboardGui")
		gui.Name = "Bite"
		gui.Adornee = head
		gui.Size = UDim2.fromScale(2.5, 2.5)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		gui.AlwaysOnTop = true
		gui.ResetOnSpawn = false
		UIKit.label(gui, "Mark", "!", { Size = UDim2.fromScale(1, 1) }, 200, UIKit.TitleFont).TextColor3 = Color3.fromRGB(255, 70, 70)
		gui.Parent = player:WaitForChild("PlayerGui")
		mark = gui
	end

	ActionBar.add(BUTTON, {
		text = UiText.CAST,
		icon = "fishing",
		variant = "Info",
		order = 3,
		key = Enum.KeyCode.R,
		onClick = function()
			if state == "waiting" then
				local button = ActionBar.get(BUTTON)
				if button then
					Juice.shake(button)
				end
				return
			end
			if state == "bite" then
				setState("idle")
				local ok, reason = KitUi.invoke("ReelLine")
				-- "Muy temprano" y "se escapó" ya los avisa el servidor (KitFx).
				if not ok and reason ~= "TOO_EARLY" and reason ~= "ESCAPED" then
					KitUi.error(reason)
				end
				return
			end
			local ok, reason = KitUi.invoke("CastLine")
			if ok then
				Sound.play("Whoosh")
				setState("waiting")
			else
				KitUi.error(reason)
			end
		end,
	})
	ActionBar.show(BUTTON, false)

	-- Cerca del agua aparece el botón; lejos, se va (salvo con un lance en curso).
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local near = root ~= nil and root:IsA("BasePart") and waterDistance(root) <= range
			ActionBar.show(BUTTON, near or state ~= "idle")
			if state == "bite" and os.clock() > biteUntil then
				setState("idle")
			end
		end
	end)

	Bus.on("Kit:Bite", function(payload: any)
		local seconds = if typeof(payload) == "table" and typeof(payload.reelSeconds) == "number" then payload.reelSeconds else cfg.reelSeconds
		biteUntil = os.clock() + seconds
		setState("bite")
		Sound.play("Notify")
		Juice.fovPunch(4, 0.25)
		showMark()
	end)
	Bus.on("Kit:Caught", function(payload: any)
		setState("idle")
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			KitUi.announce({ kind = payload.kind, variant = payload.variant, size = payload.size, weight = payload.weight, isNew = payload.isNew == true }, "Fish")
		end
	end)
	Bus.on("Kit:TooEarly", function()
		setState("idle")
		KitUi.error("TOO_EARLY")
	end)
	Bus.on("Kit:Escaped", function()
		setState("idle")
		KitUi.error("ESCAPED")
	end)
	player.CharacterAdded:Connect(function()
		setState("idle")
	end)

	-- Ventana de cañas.
	local list = KitUi.listWindow({ name = "Rods", title = UiText.RODS, icon = "fishing", variant = "Cyan" })
	local items: { Gear.Item } = {}
	local byId: { [string]: KitTypes.FishingRod } = {}
	for _, rod in cfg.rods do
		table.insert(items, { id = rod.id, name = rod.name, price = rod.price })
		byId[rod.id] = rod
	end
	local function render()
		local s = fishing
		list.setRows(Gear.rows(items, if s then s.owned else {}, if s then s.rod else nil, "BuyRod", "Rod", "fishing", function(item: Gear.Item): string
			local rod = byId[item.id]
			return string.format(UiText.ROD_STATS, Format.multiplier(rod.luck), Format.multiplier(rod.speed))
		end))
	end
	local function open()
		render()
		list.open()
	end
	if #cfg.rods > 1 then
		local menu = KitUi.menuButton("Rods", UiText.RODS, "fishing", "Cyan", 7)
		if menu then
			menu.Activated:Connect(function()
				Sound.play("Click")
				if list.isOpen() then
					list.close()
				else
					open()
				end
			end)
		end
	end
	Bus.handle("OpenRods", open)
	KitState.on("fishing", function(s: KitTypes.FishingState)
		fishing = s
		if list.isOpen() then
			render()
		end
	end)
	Bus.on("Kit:RodBought", function(payload: any)
		local rod = if typeof(payload) == "table" then byId[payload.id] else nil
		if rod then
			Sound.play("Purchase")
			KitUi.notify(string.format(UiText.NEW_GEAR, rod.name), "Accept", "fishing")
		end
	end)
	-- La plata cambia lo que alcanza: la ventana abierta se pone al día.
	player.AttributeChanged:Connect(function()
		if list.isOpen() then
			render()
		end
	end)
end

return Fishing
