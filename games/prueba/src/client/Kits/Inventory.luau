--!strict
-- Inventario de unidades del armador (mascotas, peces, criaturas, cultivos): grilla con lo mejor
-- primero y panel de la elegida con las acciones de los bloques que usa la receta:
-- - Equip / Unequip (equip), Place / Pick Up en la base (plots), Sell (sell), Merge (merge) y el
--   candado para cuidarla (no se vende ni se fusiona con "todo").
-- - Arriba: cuántas tiene ("12/50"), equipadas o la fusión en curso, "Equip Best", "Sell All" y lo
--   del momento: "Finish Now" con una fusión esperando o el próximo espacio de la base.
-- - Avisos de lo vendido y lo fusionado (KitFx "Sold", "Merged", "MergeStarted").
-- Botón del menú con el nombre de las unidades (units.label); también abre con Bus "OpenInventory" y
-- desde el puesto de venta (KitShopStand con Window "Sell"). Las fichas se crean una vez por unidad y
-- se actualizan: un inventario de cientos no se rehace en cada cambio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local RarityConfig = require(ReplicatedStorage.Shared.Config.RarityConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local PaidRandom = require(ReplicatedStorage.Shared.Lib.PaidRandom)
local Rarity = require(ReplicatedStorage.Shared.Lib.Rarity)
local UnitMath = require(ReplicatedStorage.Shared.Lib.UnitMath)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local KitState = require("./KitState")
local KitUi = require("./KitUi")
local Units = require("./Units")

type Unit = KitTypes.Unit

local Inventory = {}

local player = Players.LocalPlayer

-- Color de la ficha según la rareza, como en los hits.
local RARITY_VARIANTS: { [string]: UIKit.Variant } = {
	Common = "Neutral",
	Uncommon = "Accept",
	Rare = "Info",
	Epic = "Purple",
	Legendary = "Premium",
	Mythic = "Pink",
	Secret = "Rainbow",
}
local SELECTED_STROKE = Color3.new(1, 1, 1)

local rarities: { string } = {}
for _, tier in RarityConfig.TIERS do
	table.insert(rarities, tier.id)
end

type Tile = { button: TextButton, equipped: Frame, placed: Frame, locked: Frame }

function Inventory.start(hud: HudController.Hud)
	local cfg = KitConfig.units
	if not cfg then
		return
	end
	local equipCfg = KitConfig.equip
	local plotsCfg = KitConfig.plots
	local sellCfg = KitConfig.sell
	local mergeCfg = KitConfig.merge
	local mutations, sizes = Units.variants()
	local main = EconomyConfig.CURRENCIES[EconomyConfig.MAIN]

	local window, body = UIKit.window(hud.screen, { name = "Inventory", title = cfg.label, icon = "pets", variant = "Info" })

	-- Arriba: contador, estado y botones.
	local top = UIKit.new("Frame", { Name = "Top", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.16), ZIndex = 21 }, body) :: Frame
	local countLabel = UIKit.label(top, "Count", "", {
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0.36, 0.56),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	}, 40)
	local statusLabel = UIKit.label(top, "Status", "", {
		Position = UDim2.fromScale(0, 0.56),
		Size = UDim2.fromScale(0.36, 0.42),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	}, 28)
	local actions = UIKit.new("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.62, 1),
		ZIndex = 22,
	}, top) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, actions)
	local function topButton(name: string, text: string, variant: UIKit.Variant, icon: string?, order: number): TextButton
		local button = UIKit.button({
			name = name,
			text = text,
			variant = variant,
			icon = icon,
			aspectRatio = 0,
			size = UDim2.fromScale(0.31, 0.92),
			layoutOrder = order,
			parent = actions,
		})
		button.ZIndex = 23
		return button
	end
	local equipBest = topButton("EquipBest", UiText.EQUIP_BEST, "Accept", "star", 1)
	equipBest.Visible = equipCfg ~= nil
	local sellAll = topButton("SellAll", UiText.PROMPT_SELL, "Premium", "cash", 2)
	sellAll.Visible = sellCfg ~= nil
	local finishNow = topButton("FinishNow", UiText.FINISH_NOW, "Pink", "timer", 3)
	finishNow.Visible = false
	local buySlot = topButton("BuySlot", "", "Info", "base", 3)
	buySlot.Visible = false
	-- Con chance de mutación, la fusión es aleatorio pago (Lib/PaidRandom): todos los resultados y su
	-- probabilidad a un toque, antes de fusionar. A quien PolicyService lo restringe le sale siempre Normal.
	local mutationChance = if mergeCfg and mergeCfg.mode == "tier" then mergeCfg.mutationChance else nil
	local mergeOdds = topButton("MergeOdds", UiText.MERGE_ODDS, "Purple", "merge", 0)
	mergeOdds.Visible = mutationChance ~= nil and mutationChance > 0
	local oddsWindow = if mergeOdds.Visible then KitUi.listWindow({ name = "MergeOdds", title = UiText.MERGE_ODDS, icon = "merge", variant = "Purple" }) else nil
	-- Los botones de arriba se reparten el ancho si son más de tres.
	local topButtons = { equipBest, sellAll, finishNow, buySlot, mergeOdds }
	local function fitTop()
		local shown = 0
		for _, button in topButtons do
			if button.Visible then
				shown += 1
			end
		end
		local width = math.min(0.31, (1 - 0.02 * math.max(0, shown - 1)) / math.max(1, shown))
		for _, button in topButtons do
			button.Size = UDim2.fromScale(width, 0.92)
		end
	end

	-- Grilla a la izquierda y panel de la elegida a la derecha.
	local content = UIKit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.18),
		Size = UDim2.fromScale(1, 0.82),
		ZIndex = 21,
	}, body) :: Frame
	local grid = UIKit.grid(content, "Grid", UDim2.fromScale(0.3, 0), 0.8)
	grid.Size = UDim2.fromScale(0.63, 1)
	grid.ZIndex = 21
	local empty = UIKit.label(content, "Empty", UiText.EMPTY_INVENTORY, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.315, 0.4),
		Size = UDim2.fromScale(0.56, 0.14),
		ZIndex = 22,
	}, 36)
	local panel = UIKit.new("Frame", {
		Name = "Panel",
		Position = UDim2.fromScale(0.65, 0),
		Size = UDim2.fromScale(0.35, 1),
		ZIndex = 22,
	}, content) :: Frame
	UIKit.style(panel, "Dark", 0.08, 0.03)
	local preview = UIKit.new("Frame", {
		Name = "Preview",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.03),
		Size = UDim2.fromScale(0.9, 0.33),
		ZIndex = 23,
	}, panel) :: Frame
	local nameLabel = UIKit.label(panel, "Name", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.37),
		Size = UDim2.fromScale(0.92, 0.09),
		ZIndex = 23,
	}, 36, UIKit.TitleFont)
	local rarityLabel = UIKit.label(panel, "Rarity", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromScale(0.8, 0.06),
		ZIndex = 23,
	}, 26)
	local detailLabel = UIKit.label(panel, "Detail", "", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.86, 0.065),
		ZIndex = 23,
	}, 28)
	detailLabel.TextColor3 = UIKit.MONEY_COLOR
	local hint = UIKit.label(panel, "Hint", UiText.TAP_TO_SEE, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.12),
		ZIndex = 23,
	}, 30)
	local lockButton = UIKit.button({
		name = "Lock",
		text = "",
		variant = "Neutral",
		icon = "lock",
		aspectRatio = 1,
		anchorPoint = Vector2.new(1, 0),
		position = UDim2.fromScale(0.97, 0.02),
		size = UDim2.fromScale(0.22, 0.22),
		parent = panel,
	})
	lockButton.SizeConstraint = Enum.SizeConstraint.RelativeXX
	lockButton.ZIndex = 26

	local function actionButton(name: string, variant: UIKit.Variant, icon: string?): TextButton
		local button = UIKit.button({ name = name, text = "", variant = variant, icon = icon, aspectRatio = 0, parent = panel })
		button.ZIndex = 24
		return button
	end
	local equipButton = actionButton("Equip", "Accept", nil)
	local placeButton = actionButton("Place", "Info", "base")
	local sellButton = actionButton("Sell", "Premium", "cash")
	local mergeButton = actionButton("Merge", "Purple", "merge")
	local present: { TextButton } = {}
	if equipCfg then
		table.insert(present, equipButton)
	end
	if plotsCfg then
		table.insert(present, placeButton)
	end
	if sellCfg then
		table.insert(present, sellButton)
	end
	if mergeCfg then
		table.insert(present, mergeButton)
	end
	-- Hasta 2 acciones: una por fila y a lo ancho; más: de a dos.
	for i, button in present do
		if #present <= 2 then
			button.Position = UDim2.fromScale(0.03, 0.6 + (i - 1) * 0.2)
			button.Size = UDim2.fromScale(0.94, 0.18)
		else
			local column = (i - 1) % 2
			local line = (i - 1) // 2
			button.Position = UDim2.fromScale(0.03 + column * 0.48, 0.6 + line * 0.2)
			button.Size = UDim2.fromScale(0.46, 0.18)
		end
	end

	-- Estado ------------------------------------------------------------------------------------------
	local list: { Unit } = {}
	local maxUnits = cfg.maxInventory
	local equipState: KitTypes.EquipState? = nil
	local plotsState: KitTypes.PlotsState? = nil
	local mergeState: KitTypes.MergeState? = nil
	local selected: number? = nil
	local tiles: { [number]: Tile } = {}
	local stopPulse: Juice.Stop? = nil

	local function find(uid: number?): Unit?
		if uid == nil then
			return nil
		end
		for _, unit in list do
			if unit.uid == uid then
				return unit
			end
		end
		return nil
	end

	local function score(unit: Unit): number
		local def = KitUi.unitDef(unit.kind)
		if not def then
			return 0
		end
		if def.income then
			return UnitMath.income(def, unit, mutations, sizes)
		elseif def.power then
			return UnitMath.power(def, unit, mutations, sizes)
		elseif def.value then
			return UnitMath.value(def, unit, mutations, sizes)
		end
		return 0
	end

	local function rank(unit: Unit): number
		local def = KitUi.unitDef(unit.kind)
		return UnitMath.rank(rarities, if def then def.rarity else nil)
	end

	local function sellValue(unit: Unit): number
		local def = KitUi.unitDef(unit.kind)
		if not def or not def.value or not sellCfg then
			return 0
		end
		local mult = player:GetAttribute("Mult_" .. (sellCfg.stat or "Money"))
		return UnitMath.value(def, unit, mutations, sizes) * (sellCfg.multiplier or 1) * (if typeof(mult) == "number" then mult else 1)
	end

	local function equippedCount(): number
		local n = 0
		for _, unit in list do
			if unit.equipped then
				n += 1
			end
		end
		return n
	end

	-- Cuántas iguales hay para fusionar con esta (y cuántas hacen falta). nil: no se fusiona.
	local function mergeInfo(unit: Unit): (number?, number)
		local m = mergeCfg
		local def = KitUi.unitDef(unit.kind)
		if not m or not def then
			return nil, 0
		end
		if m.mode == "tier" then
			local tier = def.tier
			local hasNext = false
			if tier then
				for _, other in cfg.list do
					if other.tier == tier + 1 then
						hasNext = true
					end
				end
			end
			if not hasNext then
				return nil, m.count
			end
		else
			local chain = m.variantChain or {}
			local index = table.find(chain, unit.variant or "Normal")
			if not index or chain[index + 1] == nil then
				return nil, m.count
			end
		end
		local variant = if m.mode == "variant" then unit.variant or "Normal" else nil
		local have = 0
		for _, other in list do
			local sameVariant = variant == nil or (other.variant or "Normal") == variant
			if other.kind == unit.kind and sameVariant and not other.locked and not other.equipped then
				have += 1
			end
		end
		return have, m.count
	end

	local function setStroke(button: GuiObject, on: boolean)
		local border = button:FindFirstChild("Border") :: UIStroke?
		if border then
			border.Color = if on then SELECTED_STROKE else UIKit.STROKE_COLOR
		end
	end

	local function badge(parent: Instance, icon: string, x: number): Frame
		local frame = UIKit.icon(parent, icon, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(x, 0.03),
			Size = UDim2.fromScale(0.26, 0.26),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = 25,
			Visible = false,
		})
		return frame
	end

	local choose: (uid: number?) -> ()

	local function makeTile(unit: Unit): Tile
		local def = KitUi.unitDef(unit.kind)
		local button = UIKit.new("TextButton", { Name = tostring(unit.uid), Text = "", AutoButtonColor = false, ZIndex = 22 }, grid) :: TextButton
		UIKit.style(button, (if def then RARITY_VARIANTS[def.rarity] else nil) or "Info", 0.14, 0.04)
		UIKit.icon(button, KitUi.unitIcon(unit.kind), {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.06),
			Size = UDim2.fromScale(0.62, 0.62),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			ZIndex = 23,
		})
		local name = UIKit.label(button, "Name", if def then UnitMath.name(def, unit) else unit.kind, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.66),
			Size = UDim2.fromScale(0.92, 0.17),
			ZIndex = 24,
		}, 26)
		local color = KitUi.variantColor(unit.variant)
		if color then
			name.TextColor3 = color
		end
		local detail = UIKit.label(button, "Detail", if def then Units.detail(def, unit) or "" else "", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.83),
			Size = UDim2.fromScale(0.86, 0.13),
			ZIndex = 24,
		}, 22)
		detail.TextColor3 = UIKit.MONEY_COLOR
		UIKit.bounce(button)
		local uid = unit.uid
		button.Activated:Connect(function()
			Sound.play("Click")
			choose(if selected == uid then nil else uid)
		end)
		return {
			button = button,
			equipped = badge(button, "check", 0.04),
			placed = badge(button, "base", 0.04),
			locked = badge(button, "lock", 0.7),
		}
	end

	local function renderPanel()
		local unit = find(selected)
		if stopPulse then
			stopPulse()
			stopPulse = nil
		end
		for _, child in preview:GetChildren() do
			child:Destroy()
		end
		local def = if unit then KitUi.unitDef(unit.kind) else nil
		local shown = unit ~= nil and def ~= nil
		hint.Visible = not shown
		nameLabel.Visible = shown
		rarityLabel.Visible = shown
		detailLabel.Visible = shown
		lockButton.Visible = shown
		for _, button in present do
			button.Visible = shown
		end
		if not unit or not def then
			return
		end
		local model = Units.model(def)
		if model then
			UIKit.viewport(preview, model, false, { ZIndex = 23 })
		else
			UIKit.icon(preview, KitUi.unitIcon(unit.kind), { ZIndex = 23 })
		end
		nameLabel.Text = UnitMath.name(def, unit)
		nameLabel.TextColor3 = KitUi.variantColor(unit.variant) or UIKit.TEXT_COLOR
		rarityLabel.Text = def.rarity
		rarityLabel.TextColor3 = KitUi.rarityColor(def.rarity)
		detailLabel.Text = Units.detail(def, unit) or ""
		UIKit.recolor(lockButton, if unit.locked then "Premium" else "Neutral")
		-- Equip
		UIKit.setText(equipButton, if unit.equipped then UiText.UNEQUIP else UiText.EQUIP)
		UIKit.recolor(equipButton, if unit.slot ~= nil or unit.equipped then "Neutral" else "Accept")
		-- Place / Pick Up
		UIKit.setText(placeButton, if unit.slot ~= nil then UiText.PICK_UP else UiText.PLACE)
		UIKit.recolor(placeButton, if unit.equipped then "Neutral" else "Info")
		-- Sell
		local value = sellValue(unit)
		sellButton.Visible = sellCfg ~= nil and def.value ~= nil
		UIKit.setText(sellButton, string.format(UiText.SELL_FOR, Format.money(value, main.symbol)))
		UIKit.recolor(sellButton, if unit.locked or unit.equipped then "Neutral" else "Premium")
		-- Merge
		local have, need = mergeInfo(unit)
		mergeButton.Visible = mergeCfg ~= nil and have ~= nil
		local pending = mergeState ~= nil and mergeState.pending ~= nil
		UIKit.setText(mergeButton, if have and have >= need then UiText.MERGE else string.format(UiText.MERGE_COUNT, have or 0, need))
		UIKit.recolor(mergeButton, if have and have >= need and not pending then "Purple" else "Neutral")
		if have and have >= need and not pending then
			stopPulse = Juice.pulse(mergeButton, 0.05)
		end
	end

	local function renderTop()
		countLabel.Text = #list .. "/" .. maxUnits
		local pending = if mergeState then mergeState.pending else nil
		if pending then
			statusLabel.Text = string.format(UiText.MERGING, Format.clock(pending.readyAt - os.time()))
		elseif equipCfg and equipState then
			statusLabel.Text = string.format(UiText.EQUIPPED_COUNT, equippedCount(), equipState.slots)
		else
			statusLabel.Text = ""
		end
		finishNow.Visible = pending ~= nil
		local price = if plotsState then plotsState.nextPrice else nil
		buySlot.Visible = pending == nil and price ~= nil and plotsState ~= nil and plotsState.plot ~= nil
		if price then
			UIKit.setText(buySlot, string.format(UiText.BUY_SLOT, Format.money(price, main.symbol)))
		end
		fitTop()
	end

	local function render()
		local seen: { [number]: boolean } = {}
		local sorted = table.clone(list)
		local scores: { [number]: number } = {}
		local ranks: { [number]: number } = {}
		for _, unit in sorted do
			scores[unit.uid] = score(unit)
			ranks[unit.uid] = rank(unit)
		end
		table.sort(sorted, function(a, b)
			if (a.equipped == true) ~= (b.equipped == true) then
				return a.equipped == true
			end
			if scores[a.uid] ~= scores[b.uid] then
				return scores[a.uid] > scores[b.uid]
			end
			if ranks[a.uid] ~= ranks[b.uid] then
				return ranks[a.uid] > ranks[b.uid]
			end
			return a.uid < b.uid
		end)
		for order, unit in sorted do
			seen[unit.uid] = true
			local tile = tiles[unit.uid]
			if not tile then
				tile = makeTile(unit)
				tiles[unit.uid] = tile
			end
			tile.button.LayoutOrder = order
			tile.equipped.Visible = unit.equipped == true
			tile.placed.Visible = unit.slot ~= nil and not unit.equipped
			tile.locked.Visible = unit.locked == true
			setStroke(tile.button, unit.uid == selected)
		end
		for uid, tile in tiles do
			if not seen[uid] then
				tile.button:Destroy()
				tiles[uid] = nil
			end
		end
		if selected and not seen[selected] then
			selected = nil
		end
		empty.Visible = #list == 0
		renderTop()
		renderPanel()
	end

	choose = function(uid: number?)
		selected = uid
		for id, tile in tiles do
			setStroke(tile.button, id == uid)
		end
		local tile = if uid then tiles[uid] else nil
		if tile then
			Juice.pop(tile.button, 0.06)
		end
		renderPanel()
	end

	-- Acciones ----------------------------------------------------------------------------------------
	local function sellFar()
		KitUi.error("SELL_FAR")
		local pass = if sellCfg then sellCfg.anywherePass else nil
		if pass and not KitUi.ownsPass(pass) then
			task.delay(0.8, function()
				KitUi.buyPass(pass)
			end)
		end
	end

	local function handleSell(ok: boolean, result: any)
		if not ok then
			if result == "SELL_FAR" then
				sellFar()
			else
				KitUi.error(if typeof(result) == "string" then result else nil)
			end
		end
	end

	equipButton.Activated:Connect(function()
		local unit = find(selected)
		if not unit then
			return
		end
		Sound.play("Click")
		if unit.equipped then
			KitUi.ask("UnequipUnit", unit.uid)
			return
		end
		if unit.slot ~= nil then
			KitUi.error("PLACED")
			return
		end
		local slots = if equipState then equipState.slots else 0
		if equippedCount() >= slots then
			Sound.play("Error")
			KitUi.notify(UiText.EQUIP_FULL, "Close", "pets")
			return
		end
		local ok, reason = KitUi.invoke("EquipUnit", unit.uid)
		if ok then
			Sound.play("Equip")
		elseif reason == "FULL" then
			KitUi.notify(UiText.EQUIP_FULL, "Close", "pets")
		else
			KitUi.error(reason)
		end
	end)
	placeButton.Activated:Connect(function()
		local unit = find(selected)
		if not unit then
			return
		end
		Sound.play("Click")
		if unit.slot ~= nil then
			KitUi.ask("StoreUnit", unit.uid)
		elseif unit.equipped then
			KitUi.error("EQUIPPED")
		elseif KitUi.ask("PlaceUnit", unit.uid) then
			Sound.play("Equip")
		end
	end)
	sellButton.Activated:Connect(function()
		local unit = find(selected)
		if not unit then
			return
		end
		Sound.play("Click")
		if unit.equipped then
			KitUi.error("EQUIPPED")
			return
		end
		if unit.locked then
			Sound.play("Error")
			KitUi.notify(UiText.UNLOCK_FIRST, "Close", "lock")
			return
		end
		handleSell(KitUi.invoke("SellUnits", { unit.uid }))
	end)
	mergeButton.Activated:Connect(function()
		local unit = find(selected)
		local m = mergeCfg
		if not unit or not m then
			return
		end
		Sound.play("Click")
		if mergeState and mergeState.pending then
			KitUi.error("BUSY")
			return
		end
		local have, need = mergeInfo(unit)
		if not have then
			KitUi.error("MAX")
			return
		end
		if have < need then
			Sound.play("Error")
			KitUi.notify(string.format(UiText.MERGE_NEED, need - have), "Close", "merge")
			return
		end
		local ok, reason = KitUi.invoke("MergeUnits", unit.kind, if m.mode == "variant" then unit.variant or "Normal" else nil)
		if not ok then
			if reason == "FAR" then
				Sound.play("Error")
				KitUi.notify(UiText.MERGE_FAR, "Close", "merge")
			else
				KitUi.error(reason)
			end
		end
	end)
	lockButton.Activated:Connect(function()
		local unit = find(selected)
		if unit then
			Sound.play("Click")
			KitUi.fire("LockUnit", unit.uid, not unit.locked)
		end
	end)
	equipBest.Activated:Connect(function()
		Sound.play("Click")
		if KitUi.ask("EquipBest") then
			Sound.play("Equip")
		end
	end)
	sellAll.Activated:Connect(function()
		Sound.play("Click")
		handleSell(KitUi.invoke("SellAll"))
	end)
	finishNow.Activated:Connect(function()
		KitUi.buyProduct("FinishMerge")
	end)
	mergeOdds.Activated:Connect(function()
		local w = oddsWindow
		if not w or not mutationChance then
			return
		end
		Sound.play("Click")
		local chance = if player:GetAttribute("PaidRandomRestricted") == true then 0 else mutationChance
		local rows: { KitUi.Row } = {}
		for _, p in Rarity.percentages(PaidRandom.mergeOdds(chance, mutations)) do
			table.insert(rows, { id = p.id, icon = "merge", title = p.id, titleColor = KitUi.variantColor(p.id), detail = p.text, buttons = {} })
		end
		w.setRows(rows)
		w.setNote(UiText.MERGE_ODDS_NOTE)
		w.open()
	end)
	buySlot.Activated:Connect(function()
		Sound.play("Click")
		local ok, reason = KitUi.invoke("BuySlot")
		if ok then
			Sound.play("Purchase")
		elseif reason == "NOT_ENOUGH" then
			KitUi.notEnough(EconomyConfig.MAIN)
		else
			KitUi.error(reason)
		end
	end)

	-- Ventana y estado --------------------------------------------------------------------------------
	local function open()
		render()
		UIKit.open(window)
	end
	local menu = KitUi.menuButton("Inventory", cfg.label, "pets", "Info", 2)
	if menu then
		menu.Activated:Connect(function()
			Sound.play("Click")
			if UIKit.isOpen(window) then
				UIKit.close(window)
			else
				open()
			end
		end)
	end
	Bus.handle("OpenInventory", open)
	Bus.handle("OpenSell", open)

	local dirty = false
	KitState.on("units", function(units: KitTypes.UnitsState, state: any)
		list = units.list
		maxUnits = units.max
		local kit = state.kit
		equipState = kit.equip
		plotsState = kit.plots
		mergeState = kit.merge
		if UIKit.isOpen(window) then
			render()
		else
			dirty = true
		end
	end)
	UIKit.PopupToggled:Connect(function(popup: GuiObject, isOpen: boolean)
		if popup == window and isOpen and dirty then
			dirty = false
			render()
		end
	end)
	-- El reloj de la fusión.
	task.spawn(function()
		while true do
			task.wait(1)
			if UIKit.isOpen(window) and mergeState and mergeState.pending then
				renderTop()
			end
		end
	end)
	-- Los multiplicadores cambian lo que paga vender.
	player.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, 5) == "Mult_" and UIKit.isOpen(window) then
			renderPanel()
		end
	end)

	-- Avisos del servidor -----------------------------------------------------------------------------
	Bus.on("Kit:Sold", function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local currency = EconomyConfig.CURRENCIES[payload.currency or EconomyConfig.MAIN] or main
		Sound.play("Cash")
		KitUi.notify(string.format(UiText.SOLD, payload.count or 0, Format.money(payload.amount or 0, currency.symbol)), "Accept", currency.icon)
		KitUi.coinsTo(payload.currency or EconomyConfig.MAIN, math.clamp(payload.count or 1, 3, 10))
	end)
	Bus.on("Kit:Merged", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.kind) == "string" then
			KitUi.showUnit({ kind = payload.kind, variant = payload.variant, size = payload.size, isNew = payload.isNew == true }, "Merge")
		end
	end)
	Bus.on("Kit:MergeStarted", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.readyAt) == "number" then
			Sound.play("Whoosh")
			KitUi.notify(string.format(UiText.MERGING, Format.clock(payload.readyAt - os.time())), "Purple", "merge")
		end
	end)
end

return Inventory
