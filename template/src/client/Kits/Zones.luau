--!strict
-- UI del bloque Zones (mundos o biomas que se abren):
-- - Puertas (KitGate, atributo Zone): en este cliente, la de una zona abierta deja de chocar, se
--   vuelve casi invisible y pierde su cartel y su prompt; el servidor igual vigila las regiones.
-- - Ventana "Worlds" con cada zona en orden: abierta, lo que pide (precio, estadística con su barra o
--   renacimientos) y el botón para abrirla o ir a renacer.
-- - Al abrirse una (KitFx "ZoneOpened"): popup de premio con su nombre.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local PlayerState = require("../PlayerState")
local Sound = require("../UI/Sound")
local KitState = require("./KitState")
local KitUi = require("./KitUi")
local Stats = require("./Stats")

local Zones = {}

local OPEN_TRANSPARENCY = 0.85
local SIGN_TAG = "HitSign"

function Zones.start(_hud: HudController.Hud)
	local cfg = KitConfig.zones
	if not cfg or #cfg.list == 0 then
		return
	end
	local ordered = table.clone(cfg.list)
	table.sort(ordered, function(a, b)
		return a.order < b.order
	end)
	local unlocked: { [string]: boolean } = {}
	local original: { [BasePart]: { transparency: number, collide: boolean } } = {}

	local function isOpen(id: string): boolean
		return unlocked[id] == true or (ordered[1] ~= nil and ordered[1].id == id)
	end

	-- Puertas ----------------------------------------------------------------------------------------
	local function applyGate(gate: Instance)
		local id = gate:GetAttribute("Zone")
		if typeof(id) ~= "string" then
			return
		end
		local open = isOpen(id)
		local parts: { BasePart } = {}
		if gate:IsA("BasePart") then
			table.insert(parts, gate)
		end
		for _, child in gate:GetDescendants() do
			if child:IsA("BasePart") then
				table.insert(parts, child)
			elseif child:IsA("ProximityPrompt") then
				child.Enabled = not open
			end
		end
		for _, part in parts do
			local saved = original[part]
			if not saved then
				saved = { transparency = part.Transparency, collide = part.CanCollide }
				original[part] = saved
			end
			part.CanCollide = if open then false else saved.collide
			part.Transparency = if open then math.max(saved.transparency, OPEN_TRANSPARENCY) else saved.transparency
		end
		-- El cartel con el precio sobra en una puerta abierta (solo en este cliente).
		if open and gate:HasTag(SIGN_TAG) then
			gate:RemoveTag(SIGN_TAG)
		end
	end

	local function applyAll()
		for _, gate in CollectionService:GetTagged(Tags.GATE) do
			applyGate(gate)
		end
	end
	CollectionService:GetInstanceAddedSignal(Tags.GATE):Connect(function(gate: Instance)
		task.defer(applyGate, gate)
	end)

	-- Ventana Worlds ---------------------------------------------------------------------------------
	local list = KitUi.listWindow({ name = "Worlds", title = UiText.WORLDS, icon = "map", variant = "Cyan" })

	local function rebirths(): number
		local state = PlayerState.get()
		return if state then state.rebirths else 0
	end

	local function row(zone: KitTypes.ZoneDef, index: number): KitUi.Row
		local title = if zone.difficulty then zone.difficulty .. " " .. zone.name else zone.name
		if isOpen(zone.id) then
			return {
				id = zone.id,
				icon = "teleport",
				title = title,
				variant = "Accept",
				buttons = { { text = UiText.ZONE_OPEN, variant = "Neutral", icon = "check", onClick = function() end } },
			}
		end
		local before = ordered[index - 1]
		local reachable = before == nil or isOpen(before.id)
		local price = zone.price
		local stat = zone.stat
		local needRebirths = zone.rebirths
		local r: KitUi.Row = { id = zone.id, icon = "lock", title = title, variant = if reachable then "Info" else "Neutral", buttons = {} }
		if not reachable then
			r.detail = UiText.ERR_ORDER
			r.buttons = { { text = UiText.LOCKED, variant = "Neutral", icon = "lock", onClick = function()
				KitUi.error("ORDER")
			end } }
		elseif stat then
			local have = Stats.value(stat.id)
			r.level = { value = math.min(have, stat.value), max = stat.value }
			r.detail = string.format(UiText.ZONE_STAT_PROGRESS, Format.number(have), Format.number(stat.value), Stats.label(stat.id))
			r.buttons = { { text = UiText.LOCKED, variant = "Neutral", icon = "lock", onClick = function()
				KitUi.error("REQUIREMENT")
			end } }
		elseif needRebirths then
			local have = rebirths()
			r.level = { value = math.min(have, needRebirths), max = needRebirths }
			r.detail = string.format(UiText.ZONE_REBIRTH_PROGRESS, have, needRebirths)
			r.buttons = { { text = UiText.REBIRTH, variant = "Purple", icon = "rebirth", onClick = function()
				Sound.play("Click")
				Bus.call("OpenRebirth")
			end } }
		end
		if price and reachable then
			local text, icon = KitUi.price(price)
			r.detail = r.detail or text
			local unlock: KitUi.RowButton = {
				text = text,
				variant = "Premium",
				icon = icon,
				onClick = function()
					Sound.play("Click")
					if not KitUi.canPay(price) then
						KitUi.notEnough(price.currency)
						return
					end
					local ok, reason = KitUi.invoke("UnlockZone", zone.id)
					if not ok then
						if reason == "NOT_ENOUGH" then
							KitUi.notEnough(price.currency)
						else
							KitUi.error(reason)
						end
					end
				end,
			}
			table.insert(r.buttons, 1, unlock)
		end
		return r
	end

	local function render()
		local rows: { KitUi.Row } = {}
		for index, zone in ordered do
			table.insert(rows, row(zone, index))
		end
		list.setRows(rows)
	end

	local menu = KitUi.menuButton("Worlds", UiText.WORLDS, "map", "Cyan", 6)
	if menu then
		menu.Activated:Connect(function()
			Sound.play("Click")
			if list.isOpen() then
				list.close()
			else
				render()
				list.open()
			end
		end)
	end
	Bus.handle("OpenWorlds", function()
		render()
		list.open()
	end)

	KitState.on("zones", function(state: KitTypes.ZonesState)
		unlocked = state.unlocked or {}
		applyAll()
		if list.isOpen() then
			render()
		end
	end)
	applyAll()

	Bus.on("Kit:ZoneOpened", function(payload: any)
		if typeof(payload) ~= "table" or typeof(payload.name) ~= "string" then
			return
		end
		Sound.play("LevelUp")
		Bus.call("ShowReward", {
			title = string.format(UiText.ZONE_OPENED, payload.name),
			lines = { { icon = "teleport", text = payload.name, kind = "item" } },
			source = "Zone",
		})
	end)
	-- Lo que piden cambia con la plata y las estadísticas: la ventana abierta se pone al día.
	task.spawn(function()
		while true do
			task.wait(1)
			if list.isOpen() then
				render()
			end
		end
	end)
end

return Zones
