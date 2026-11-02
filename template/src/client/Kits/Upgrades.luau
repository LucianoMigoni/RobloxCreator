--!strict
-- UI del bloque Upgrades (mejoras con niveles): ventana con cada mejora, su nivel en una barra, lo que
-- hace y el precio del siguiente; las de escalera por Robux (`robux`) muestran su producto. Abre desde
-- el menú, con Bus "OpenUpgrades" o desde los puestos (KitUpgradeStation; con atributo Upgrade, esa
-- mejora va primera). Aviso al subir de nivel (KitFx "Upgraded").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Ladder = require(ReplicatedStorage.Shared.Lib.Ladder)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Sound = require("../UI/Sound")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Upgrades = {}

local player = Players.LocalPlayer

function Upgrades.start(_hud: HudController.Hud)
	local defs = KitConfig.upgrades
	if not defs or #defs == 0 then
		return
	end
	local byId: { [string]: KitTypes.UpgradeDef } = {}
	for _, def in defs do
		byId[def.id] = def
	end
	local levels: { [string]: number } = {}
	local first: string? = nil -- la del puesto, arriba

	local list = KitUi.listWindow({ name = "Upgrades", title = UiText.UPGRADES_SIGN, icon = "boost", variant = "Orange" })

	local function row(def: KitTypes.UpgradeDef): KitUi.Row
		local level = levels[def.id] or 0
		local maxed = level >= def.maxLevel
		local r: KitUi.Row = {
			id = def.id,
			icon = def.icon or "boost",
			title = string.format(UiText.UPGRADE_LEVEL, def.name, level),
			detail = def.desc,
			level = { value = level, max = def.maxLevel },
			variant = if maxed then "Accept" else "Info",
			buttons = {},
		}
		if maxed then
			r.buttons = { { text = UiText.MAX_LEVEL, variant = "Neutral", icon = "star", onClick = function()
				KitUi.error("MAX")
			end } }
			return r
		end
		if not def.robux then
			local amount = Ladder.price(level + 1, def.prices, def.base, def.growth)
			if amount then
				local price: KitTypes.Price = { currency = def.currency or EconomyConfig.MAIN, amount = amount }
				local text, icon = KitUi.price(price)
				table.insert(r.buttons, {
					text = text,
					variant = if KitUi.canPay(price) then "Premium" else "Neutral",
					icon = icon,
					onClick = function()
						Sound.play("Click")
						if not KitUi.canPay(price) then
							KitUi.notEnough(price.currency)
							return
						end
						local ok, reason = KitUi.invoke("BuyUpgrade", def.id)
						if not ok then
							if reason == "NOT_ENOUGH" then
								KitUi.notEnough(price.currency)
							else
								KitUi.error(reason)
							end
						end
					end,
				})
			end
		end
		local product = KitUi.productFor("Upgrade:" .. def.id)
		if product then
			table.insert(r.buttons, { robux = product, variant = "Accept", onClick = function()
				KitUi.buyProduct(product)
			end })
		end
		if #r.buttons == 0 then
			r.buttons = { { text = UiText.LOCKED, variant = "Neutral", icon = "lock", onClick = function()
				KitUi.error("NOT_FOR_SALE")
			end } }
		end
		return r
	end

	local function render()
		local rows: { KitUi.Row } = {}
		local top = if first then byId[first] else nil
		if top then
			table.insert(rows, row(top))
		end
		for _, def in defs do
			if def ~= top then
				table.insert(rows, row(def))
			end
		end
		list.setRows(rows)
	end

	local function open(id: any)
		first = if typeof(id) == "string" and byId[id] then id else nil
		render()
		list.open()
	end
	local menu = KitUi.menuButton("Upgrades", UiText.UPGRADES_SIGN, "boost", "Orange", 8)
	if menu then
		menu.Activated:Connect(function()
			Sound.play("Click")
			if list.isOpen() then
				list.close()
			else
				open(nil)
			end
		end)
	end
	Bus.handle("OpenUpgrades", open)

	KitState.on("upgrades", function(state: KitTypes.UpgradesState)
		levels = state.levels or {}
		if list.isOpen() then
			render()
		end
	end)
	player.AttributeChanged:Connect(function()
		if list.isOpen() then
			render()
		end
	end)
	Bus.on("Kit:Upgraded", function(payload: any)
		local def = if typeof(payload) == "table" then byId[payload.id] else nil
		if def then
			Sound.play("LevelUp")
			KitUi.notify(string.format(UiText.UPGRADED, def.name, payload.level or 0), "Orange", def.icon or "boost")
		end
	end)
end

return Upgrades
