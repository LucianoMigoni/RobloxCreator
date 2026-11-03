--!strict
-- UI del bloque Rolls (huevos, dados, cofres, puestos de compra):
-- - Ventana de cada estación (prompt "RollStation" o Bus "OpenRoll"): todas las probabilidades con la
--   suerte del jugador, sumando exactamente 100 % (regla de los aleatorios pagos), las de las
--   mutaciones, los botones x1/x3/x8 con su precio (el que pide pase muestra el candado y lo ofrece),
--   la tirada gratis con su reloj y "Auto" con su pase.
-- - Revelado (KitFx "Rolled"): lo de la estación tiembla, destello, y aparece lo que salió con el color
--   de su rareza, "NEW!" y rayos para lo raro; tocar saltea. Con muchas, se ven las mejores 12.
-- A quien PolicyService no le permite aleatorios pagos no se le ofrecen (el servidor igual lo rechaza).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local PaidRandom = require(ReplicatedStorage.Shared.Lib.PaidRandom)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local RollRules = require(ReplicatedStorage.Shared.Lib.RollRules)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Effects = require("../UI/Effects")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local KitState = require("./KitState")
local KitUi = require("./KitUi")

local Rolls = {}

local player = Players.LocalPlayer

local MAX_SHOWN = 12
local SHAKE_SECONDS = 1.1
local SHOW_SECONDS = 2.4
local AUTO_SHOW_SECONDS = 1.2
local AUTO_GAP = 0.4

local RARITY_VARIANTS: { [string]: UIKit.Variant } = {
	Common = "Neutral",
	Uncommon = "Accept",
	Rare = "Info",
	Epic = "Purple",
	Legendary = "Premium",
	Mythic = "Pink",
	Secret = "Rainbow",
}

local rarities: { string } = {}
for _, tier in RarityConfig.TIERS do
	table.insert(rarities, tier.id)
end
local LEGENDARY_RANK = table.find(rarities, "Legendary") or math.huge

function Rolls.start(hud: HudController.Hud)
	local cfg = KitConfig.rolls
	local unitsCfg = KitConfig.units
	if not cfg or not unitsCfg then
		return
	end
	local defs: { [string]: KitTypes.RollDef } = {}
	for _, def in cfg.list do
		defs[def.id] = def
	end
	local unitDefs: { [string]: KitTypes.UnitDef } = {}
	for _, def in unitsCfg.list do
		unitDefs[def.id] = def
	end
	local nextFree: { [string]: number } = {}
	local current: KitTypes.RollDef? = nil
	local auto: string? = nil -- id de la tirada en automático

	local function owns(pass: string): boolean
		return KitUi.ownsPass(pass)
	end

	local function luck(): number
		local value = player:GetAttribute("Mult_" .. (cfg.luckStat or "Luck"))
		return if typeof(value) == "number" and value > 0 then value else 1
	end

	local function restricted(def: KitTypes.RollDef): boolean
		return PaidRandom.roll(def, EconomyConfig.isPurchasable) and player:GetAttribute("PaidRandomRestricted") == true
	end

	-- Ventana ----------------------------------------------------------------------------------------
	local window, body = UIKit.window(hud.screen, { name = "Roll", title = "", icon = "egg", variant = "Purple" })
	local head = window:FindFirstChild("Head") :: Frame
	local titleLabel = head:FindFirstChild("Title") :: TextLabel
	local iconHolder = window:FindFirstChild("Icon")
	local note = UIKit.label(body, "Note", "", {
		Size = UDim2.fromScale(1, 0.08),
		ZIndex = 22,
	}, 30)
	local odds = UIKit.grid(body, "Odds", UDim2.fromScale(0.18, 0), 0.78)
	odds.Position = UDim2.fromScale(0, 0.09)
	odds.Size = UDim2.fromScale(1, 0.65)
	odds.ZIndex = 21
	local buttons = UIKit.new("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 0.23),
		ZIndex = 22,
	}, body) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, buttons)

	local request: (def: KitTypes.RollDef, count: number, isAuto: boolean) -> boolean
	local freeButtons: { TextButton } = {} -- las gratis: su reloj se actualiza sin rehacerlas

	local function freeText(def: KitTypes.RollDef): string
		local ready = RollRules.freeReady(nextFree[def.id], os.time())
		return if ready then UiText.FREE else string.format(UiText.FREE_IN, Format.clock((nextFree[def.id] or 0) - os.time()))
	end

	local function renderOdds(def: KitTypes.RollDef)
		for _, child in odds:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local entries = UnitMath.entries(def.pool, unitDefs, rarities, unitsCfg.luckyFrom)
		local shown = Rarity.percentages(entries, luck())
		table.sort(shown, function(a, b)
			return a.chance > b.chance
		end)
		for order, entry in shown do
			local unit = unitDefs[entry.id]
			if unit then
				local cell = UIKit.new("Frame", { Name = entry.id, LayoutOrder = order, ZIndex = 22 }, odds) :: Frame
				UIKit.style(cell, RARITY_VARIANTS[unit.rarity] or "Info", 0.14, 0.04)
				UIKit.icon(cell, unit.icon or "pets", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.05),
					Size = UDim2.fromScale(0.6, 0.6),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ZIndex = 23,
				})
				UIKit.label(cell, "Name", unit.name, {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.64),
					Size = UDim2.fromScale(0.92, 0.17),
					ZIndex = 24,
				}, 24)
				UIKit.label(cell, "Chance", entry.text, {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.81),
					Size = UDim2.fromScale(0.86, 0.15),
					ZIndex = 24,
				}, 26).TextColor3 = Color3.fromRGB(255, 230, 90)
			end
		end
		-- Mutaciones (y suerte), en una línea.
		local parts: { string } = {}
		if unitsCfg.mutations then
			local list: { Rarity.Entry } = {}
			for _, v in RarityConfig.MUTATIONS do
				table.insert(list, { id = v.id, weight = v.weight, lucky = v.lucky })
			end
			for _, p in Rarity.percentages(list, luck()) do
				if p.id ~= "Normal" then
					table.insert(parts, p.id .. " " .. p.text)
				end
			end
		end
		local luckText = string.format(UiText.LUCK_NOW, Format.multiplier(luck()))
		note.Text = if #parts > 0 then luckText .. " · " .. string.format(UiText.MUTATIONS, table.concat(parts, " · ")) else luckText
	end

	local function renderButtons(def: KitTypes.RollDef)
		for _, child in buttons:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(freeButtons)
		if restricted(def) then
			UIKit.label(buttons, "Restricted", UiText.ERR_RESTRICTED, { Size = UDim2.fromScale(0.8, 0.8), ZIndex = 23 }, 32)
			return
		end
		local count = #def.amounts + (if cfg.autoPass then 1 else 0)
		local width = math.min(0.24, (1 - 0.02 * (count - 1)) / math.max(count, 1))
		local function add(name: string, text: string, variant: UIKit.Variant, icon: string?, order: number, onClick: () -> ()): TextButton
			local button = UIKit.button({
				name = name,
				text = text,
				variant = variant,
				icon = icon,
				aspectRatio = 0,
				size = UDim2.fromScale(width, 0.9),
				layoutOrder = order,
				parent = buttons,
			})
			button.ZIndex = 23
			button.Activated:Connect(onClick)
			return button
		end
		for order, amount in def.amounts do
			local pass = amount.pass
			local locked = pass ~= nil and not owns(pass)
			local price = def.price
			local text: string
			local icon: string? = nil
			if locked then
				text = string.format(UiText.OPEN_COUNT, amount.count)
				icon = "lock"
			elseif price then
				local total, currencyIcon = KitUi.price({ currency = price.currency, amount = price.amount * amount.count })
				text = string.format(UiText.OPEN_COUNT, amount.count) .. " · " .. total
				icon = currencyIcon
			else
				text = freeText(def)
				icon = "gift"
			end
			local button = add("Open" .. amount.count, text, if locked then "Neutral" else "Accept", icon, order, function()
				Sound.play("Click")
				if locked and pass then
					KitUi.buyPass(pass)
					return
				end
				request(def, amount.count, false)
			end)
			if not price and not locked then
				table.insert(freeButtons, button)
			end
		end
		local autoPass = cfg.autoPass
		if autoPass then
			local on = auto == def.id
			add("Auto", if on then UiText.AUTO_ON else UiText.AUTO, if on then "Premium" else "Info", if owns(autoPass) then "egg" else "lock", 99, function()
				Sound.play("Click")
				if not owns(autoPass) then
					KitUi.buyPass(autoPass)
					return
				end
				if auto == def.id then
					auto = nil
				else
					auto = def.id
					task.spawn(function()
						while auto == def.id do
							if not request(def, RollRules.best(def, owns), true) then
								auto = nil
								break
							end
							task.wait(AUTO_GAP)
						end
						if current == def and UIKit.isOpen(window) then
							renderButtons(def)
						end
					end)
				end
				renderButtons(def)
			end)
		end
	end

	local function open(id: any)
		local def = if typeof(id) == "string" then defs[id] else nil
		if not def then
			return
		end
		if current ~= def and auto then
			auto = nil
		end
		current = def
		titleLabel.Text = def.name
		if iconHolder then
			UIKit.setIcon(iconHolder, def.look or "egg")
		end
		renderOdds(def)
		renderButtons(def)
		UIKit.open(window)
	end

	-- Revelado ---------------------------------------------------------------------------------------
	local queue: { { roll: string, results: { KitTypes.RollResult } } } = {}
	local revealing = false
	local revealDone = Instance.new("BindableEvent")

	local function resultCard(parent: Instance, result: KitTypes.RollResult, order: number): Frame?
		local unit = unitDefs[result.kind]
		if not unit then
			return nil
		end
		local card = UIKit.new("Frame", { Name = "Result" .. order, LayoutOrder = order, ZIndex = 93 }, parent) :: Frame
		UIKit.style(card, RARITY_VARIANTS[unit.rarity] or "Info", 0.14, 0.04)
		UIKit.icon(card, unit.icon or "pets", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.62, 0.62),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = 94,
		})
		local name = UIKit.label(card, "Name", UnitMath.name(unit, result), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.65),
			Size = UDim2.fromScale(0.92, 0.17),
			ZIndex = 95,
		}, 30)
		name.TextColor3 = KitUi.variantColor(result.variant) or UIKit.TEXT_COLOR
		local rarity = UIKit.label(card, "Rarity", unit.rarity, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.82),
			Size = UDim2.fromScale(0.8, 0.13),
			ZIndex = 95,
		}, 24)
		rarity.TextColor3 = KitUi.rarityColor(unit.rarity)
		if result.isNew then
			KitUi.raise(UIKit.ribbon(card, UiText.NEW_UNIT, "Close"), 96)
		end
		return card
	end

	local function reveal(roll: string, results: { KitTypes.RollResult })
		revealing = true
		local def = defs[roll]
		local quick = auto ~= nil
		local overlay = UIKit.new("TextButton", {
			Name = "Reveal",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 90,
		}, hud.screen) :: TextButton
		local skip = false
		overlay.Activated:Connect(function()
			skip = true
		end)
		UIKit.label(overlay, "Skip", UiText.TAP_TO_SKIP, {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.97),
			Size = UDim2.fromScale(0.4, 0.05),
			ZIndex = 96,
		}, 28)
		-- 1. Tiembla lo de la estación.
		if not quick then
			local holder = UIKit.icon(overlay, if def then def.look or "egg" else "egg", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.48),
				Size = UDim2.fromScale(0.34, 0.34),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 92,
			})
			Sound.play("Riser")
			local stopWiggle = Juice.wiggle(holder, 14, 0.18)
			local started = os.clock()
			while os.clock() - started < SHAKE_SECONDS and not skip do
				task.wait(0.05)
			end
			stopWiggle()
			holder:Destroy()
			Sound.play("EggCrack")
			Juice.flash(hud.screen, Color3.new(1, 1, 1), 0.35)
		end
		-- 2. Lo que salió: las mejores primero.
		local sorted = table.clone(results)
		table.sort(sorted, function(a, b)
			local ra = UnitMath.rank(rarities, if unitDefs[a.kind] then unitDefs[a.kind].rarity else nil)
			local rb = UnitMath.rank(rarities, if unitDefs[b.kind] then unitDefs[b.kind].rarity else nil)
			if ra ~= rb then
				return ra > rb
			end
			return a.uid < b.uid
		end)
		local best = sorted[1]
		local bestRank = if best and unitDefs[best.kind] then UnitMath.rank(rarities, unitDefs[best.kind].rarity) else 0
		local shownCount = math.min(#sorted, MAX_SHOWN)
		local columns = if shownCount <= 1 then 1 elseif shownCount <= 4 then shownCount elseif shownCount <= 8 then 4 else 6
		-- Ancho por columnas y alto de cada ficha según su ancho (UIKit.fitCells), en cualquier pantalla.
		local area = UIKit.new("Frame", {
			Name = "Results",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.47),
			Size = UDim2.fromScale(math.min(0.9, 0.15 * columns), 0.8),
			ZIndex = 92,
		}, overlay) :: Frame
		local layout = UIKit.new("UIGridLayout", {
			CellSize = UDim2.new(1 / columns - 0.02, 0, 0, 100),
			CellPadding = UDim2.new(0.02, 0, 0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, area) :: UIGridLayout
		UIKit.fitCells(layout, 0.78)
		local stops: { Juice.Stop } = {}
		for i = 1, shownCount do
			local card = resultCard(area, sorted[i], i)
			if card then
				Juice.bounceIn(card, (i - 1) * 0.05)
				local unit = unitDefs[sorted[i].kind]
				if unit and UnitMath.rank(rarities, unit.rarity) >= LEGENDARY_RANK then
					table.insert(stops, Effects.rays(card, KitUi.rarityColor(unit.rarity), 1.6))
				end
			end
		end
		if #sorted > MAX_SHOWN then
			UIKit.label(overlay, "More", string.format(UiText.MORE_RESULTS, #sorted - MAX_SHOWN), {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.88),
				Size = UDim2.fromScale(0.3, 0.06),
				ZIndex = 96,
			}, 40)
		end
		if bestRank >= LEGENDARY_RANK then
			Sound.play("Legendary")
			Effects.confetti(hud.screen, 50)
			Juice.cameraShake(0.4, 0.4)
		else
			Sound.play("Reveal")
		end
		if best then
			KitUi.cheer({ kind = best.kind, variant = best.variant })
		end
		skip = false
		local started = os.clock()
		local wait = if quick then AUTO_SHOW_SECONDS else SHOW_SECONDS
		while os.clock() - started < wait and not skip do
			task.wait(0.05)
		end
		for _, stop in stops do
			stop()
		end
		local fade = TweenService:Create(overlay, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		overlay:Destroy()
		revealing = false
		revealDone:Fire()
	end

	local function nextReveal()
		if revealing then
			return
		end
		local item = table.remove(queue, 1)
		if item then
			task.spawn(function()
				reveal(item.roll, item.results)
				nextReveal()
			end)
		end
	end

	-- Pide la tirada. Devuelve si salió (en automático espera a que termine el revelado).
	request = function(def: KitTypes.RollDef, count: number, isAuto: boolean): boolean
		local price = def.price
		if price and not KitUi.canPay({ currency = price.currency, amount = price.amount * count }) then
			KitUi.notEnough(price.currency)
			return false
		end
		local ok, result = KitUi.invoke("RequestRoll", def.id, count, isAuto)
		if not ok then
			if result == "NOT_ENOUGH" and price then
				KitUi.notEnough(price.currency)
			else
				KitUi.error(if typeof(result) == "string" then result else nil)
			end
			return false
		end
		if UIKit.isOpen(window) and not isAuto then
			UIKit.close(window)
		end
		if isAuto then
			-- Espera al revelado de esta tirada antes de la siguiente.
			task.wait(0.1)
			while revealing or #queue > 0 do
				revealDone.Event:Wait()
			end
		end
		return true
	end

	Bus.on("Kit:Rolled", function(payload: any)
		if typeof(payload) ~= "table" or typeof(payload.roll) ~= "string" or typeof(payload.results) ~= "table" then
			return
		end
		table.insert(queue, { roll = payload.roll, results = payload.results })
		nextReveal()
	end)

	Bus.handle("OpenRoll", open)
	KitState.on("rolls", function(state: KitTypes.RollsState)
		nextFree = state.nextFree or {}
		local def = current
		if def and UIKit.isOpen(window) then
			renderButtons(def)
		end
	end)
	-- Pases, suerte y el reloj de la gratis.
	player.AttributeChanged:Connect(function(name: string)
		local def = current
		if not def or not UIKit.isOpen(window) then
			return
		end
		if string.sub(name, 1, 4) == "Pass" then
			renderButtons(def)
		elseif name == "Mult_" .. (cfg.luckStat or "Luck") then
			renderOdds(def)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local def = current
			if def and not def.price and UIKit.isOpen(window) then
				for _, button in freeButtons do
					UIKit.setText(button, freeText(def))
				end
			end
		end
	end)
end

return Rolls
