--!strict
-- Tienda estilo hit (ShopConfig): pestañas por categoría, tarjetas con ícono grande, efecto en una
-- línea y píldora de precio verde con R$. El precio que se muestra es el del Dashboard
-- (GetProductInfoAsync); `robux` de la configuración es solo el de respaldo.
-- - Productos: PromptProductPurchase; el servidor entrega por ProcessReceipt y muestra el premio.
-- - Pases: PromptGamePassPurchase; "OWNED" si ya lo tiene. Botón de regalo si hay producto `giftOf`.
-- - Suscripción del juego: PromptSubscriptionPurchase.
-- - Anuncio con premio: se pregunta si hay anuncio al abrir la tienda (regla de AdService) y se
--   muestra la tarjeta solo si está disponible.
-- - Azar pago (`random`): oculto a quien PolicyService no se lo permite (atributo PaidRandomRestricted).
-- - Productos de una sola vez: ocultos después de comprarlos.

local AdService = game:GetService("AdService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Bus = require("../Bus")
local PlayerState = require("../PlayerState")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")
local Hud = require("./HudController")

local ShopController = {}

local player = Players.LocalPlayer

local TABS: { UIKit.Tab } = {
	{ id = "Featured", label = UiText.TAB_FEATURED, icon = "star" },
	{ id = "Passes", label = UiText.TAB_PASSES, icon = "crown" },
	{ id = "Boosts", label = UiText.TAB_BOOSTS, icon = "money_boost" },
	{ id = "Currency", label = UiText.TAB_CURRENCY, icon = "cash" },
	{ id = "Server", label = UiText.TAB_SERVER, icon = "friends" },
	{ id = "Spins", label = UiText.TAB_SPINS, icon = "spin" },
}

local VARIANT_BY_TAB: { [string]: UIKit.Variant } = {
	Featured = "Orange",
	Passes = "Purple",
	Boosts = "Accept",
	Currency = "Info",
	Server = "Pink",
	Spins = "Cyan",
	Kit = "Premium",
}

local prices: { [string]: number } = {} -- "product:123" / "pass:45" → precio del Dashboard
local function fetchPrice(kind: Enum.InfoType, id: number, onPrice: (number) -> ())
	local key = kind.Name .. ":" .. id
	local cached = prices[key]
	if cached then
		onPrice(cached)
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, id, kind)
		if ok and typeof(info) == "table" and typeof(info.PriceInRobux) == "number" then
			prices[key] = info.PriceInRobux
			onPrice(info.PriceInRobux)
		end
	end)
end

function ShopController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Shop", title = UiText.SHOP_TITLE, icon = "shop", variant = "Close" })
	local content = UIKit.new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 0.84),
		ZIndex = 21,
	}, body) :: Frame

	local hasKit = false
	for _, product in ShopConfig.PRODUCTS do
		if product.category == "Kit" then
			hasKit = true
		end
	end
	local tabs = table.clone(TABS)
	if hasKit then
		table.insert(tabs, 2, { id = "Kit", label = UiText.TAB_KIT, icon = "egg_gold" })
	end

	local current = "Featured"
	local adAvailable = false
	local grid: ScrollingFrame? = nil

	local function incomeAmount(minutes: number): number
		local perSecond = player:GetAttribute("Income")
		local base = math.max(EconomyConfig.MIN_INCOME_PER_SECOND, if typeof(perSecond) == "number" then perSecond else 0)
		return base * 60 * minutes
	end

	local function describe(product: ShopConfig.Product): string
		-- "Get $1.2M" es más tentador que "2 hours of earnings": se muestra lo que daría hoy.
		for _, reward in product.grant do
			if reward.incomeMinutes and reward.currency then
				local currency = EconomyConfig.CURRENCIES[reward.currency]
				return "≈ " .. Format.money(incomeAmount(reward.incomeMinutes), currency.symbol)
			end
		end
		return product.desc
	end

	local function priceButton(card: Frame, text: string, onActivated: () -> ())
		local footer = card:FindFirstChild("Footer") :: Frame
		local button = UIKit.pricePill(footer, "Buy", text, nil, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.95, 1),
			ZIndex = 4,
		})
		button.Activated:Connect(function()
			Sound.play("Click")
			onActivated()
		end)
		return button
	end

	local function productCard(parent: Instance, product: ShopConfig.Product, order: number)
		local card = UIKit.card(parent, {
			name = product.key,
			title = product.name,
			desc = describe(product),
			icon = product.icon,
			variant = VARIANT_BY_TAB[product.category] or "Info",
			layoutOrder = order,
		})
		if product.tag then
			UIKit.ribbon(card, product.tag, "Orange")
			Juice.shine(card, 3)
		end
		if product.productId == 0 then
			local footer = card:FindFirstChild("Footer") :: Frame
			UIKit.label(footer, "Soon", UiText.UNAVAILABLE, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 22)
			return
		end
		local button = priceButton(card, tostring(product.robux), function()
			MarketplaceService:PromptProductPurchase(player, product.productId)
		end)
		fetchPrice(Enum.InfoType.Product, product.productId, function(price)
			UIKit.setText(button, "R$ " .. Format.commas(price))
		end)
	end

	local function passCard(parent: Instance, pass: ShopConfig.Pass, order: number, owned: boolean, giftKey: string?)
		local card = UIKit.card(parent, {
			name = pass.key,
			title = pass.name,
			desc = pass.desc,
			icon = pass.icon,
			variant = "Purple",
			layoutOrder = order,
		})
		local footer = card:FindFirstChild("Footer") :: Frame
		if owned then
			local done = UIKit.button({ name = "Owned", text = UiText.OWNED, variant = "Neutral", parent = footer, size = UDim2.fromScale(0.95, 1), aspectRatio = 3 })
			done.AnchorPoint = Vector2.new(0.5, 0.5)
			done.Position = UDim2.fromScale(0.5, 0.5)
			done.ZIndex = 4
		elseif pass.passId == 0 then
			UIKit.label(footer, "Soon", UiText.UNAVAILABLE, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 22)
		else
			local button = priceButton(card, tostring(pass.robux), function()
				MarketplaceService:PromptGamePassPurchase(player, pass.passId)
			end)
			fetchPrice(Enum.InfoType.GamePass, pass.passId, function(price)
				UIKit.setText(button, "R$ " .. Format.commas(price))
			end)
		end
		if giftKey then
			local gift = UIKit.button({
				name = "Gift",
				text = "",
				variant = "Pink",
				icon = "gift",
				anchorPoint = Vector2.new(0.5, 0.5),
				position = UDim2.fromScale(0.9, 0.1),
				size = UDim2.fromScale(0.26, 0.26),
				aspectRatio = 1,
				parent = card,
			})
			gift.ZIndex = 6
			gift.Activated:Connect(function()
				Sound.play("Click")
				Bus.call("OpenGift", pass.key)
			end)
		end
	end

	local function adCard(parent: Instance)
		local card = UIKit.card(parent, {
			name = "RewardedAd",
			title = "FREE 2x Money",
			desc = UiText.AD_INFO,
			icon = "money_boost",
			variant = "Accept",
			layoutOrder = -1,
		})
		UIKit.ribbon(card, "FREE", "Accept")
		local footer = card:FindFirstChild("Footer") :: Frame
		local watch = UIKit.button({ name = "Watch", text = UiText.WATCH_AD, variant = "Info", parent = footer, size = UDim2.fromScale(0.95, 1), aspectRatio = 3 })
		watch.AnchorPoint = Vector2.new(0.5, 0.5)
		watch.Position = UDim2.fromScale(0.5, 0.5)
		watch.ZIndex = 4
		watch.Activated:Connect(function()
			Sound.play("Click")
			adAvailable = false
			card.Visible = false
			task.spawn(function()
				pcall(function()
					return Net.func("WatchRewardedAd"):InvokeServer()
				end)
			end)
		end)
	end

	local function render()
		if grid then
			grid:Destroy()
		end
		local state = PlayerState.get()
		local restricted = player:GetAttribute("PaidRandomRestricted") == true
		local list = UIKit.grid(content, "Grid", UDim2.fromScale(0.3, 0), 0.78)
		list.ZIndex = 21
		grid = list
		local order = 0
		if current == "Passes" then
			local gifts: { [string]: boolean } = {}
			for _, product in ShopConfig.PRODUCTS do
				if product.giftOf and product.productId ~= 0 then
					gifts[product.giftOf] = true
				end
			end
			for _, pass in ShopConfig.PASSES do
				order += 1
				local owned = player:GetAttribute(pass.attribute) == true
				passCard(list, pass, order, owned, if gifts[pass.key] then pass.key else nil)
			end
			return
		end
		if current == "Featured" then
			if adAvailable then
				adCard(list)
			end
			for _, sub in ShopConfig.SUBSCRIPTIONS do
				order += 1
				local card = UIKit.card(list, { name = sub.key, title = sub.name, desc = sub.desc, icon = sub.icon, variant = "Premium", layoutOrder = order })
				UIKit.ribbon(card, "VIP", "Purple")
				Juice.shine(card, 3)
				local footer = card:FindFirstChild("Footer") :: Frame
				if player:GetAttribute(sub.attribute) == true then
					UIKit.label(footer, "Owned", UiText.OWNED_PASS, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 24)
				elseif sub.subscriptionId == "" then
					UIKit.label(footer, "Soon", UiText.UNAVAILABLE, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 22)
				else
					priceButton(card, UiText.BUY, function()
						MarketplaceService:PromptSubscriptionPurchase(player, sub.subscriptionId)
					end)
				end
			end
		end
		for _, product in ShopConfig.PRODUCTS do
			local hidden = product.giftOf ~= nil
				or (product.random and restricted)
				or (product.once and state ~= nil and state.boughtOnce[product.key] == true)
				or product.key == "OfflineDouble" -- se ofrece en el cartel de bienvenida
			if product.category == current and not hidden then
				order += 1
				productCard(list, product, order)
			end
		end
	end

	local tabControl = UIKit.tabs(body, tabs, function(id: string)
		Sound.play("Tab")
		current = id
		render()
	end)
	tabControl.frame.ZIndex = 22

	local function open(tab: string?)
		if tab then
			current = tab
			tabControl.select(tab)
		end
		render()
		UIKit.open(window)
		-- Regla de AdService: preguntar si hay anuncio cuando se abre la tienda, no antes.
		task.spawn(function()
			local ok, result = pcall(AdService.GetAdAvailabilityNowAsync, AdService, Enum.AdFormat.RewardedVideo)
			local available = ok and typeof(result) == "table" and result.AdAvailabilityResult == Enum.AdAvailabilityResult.IsAvailable
			if available ~= adAvailable then
				adAvailable = available
				if current == "Featured" and UIKit.isOpen(window) then
					render()
				end
			end
		end)
	end

	local button = hud.addButton("left", { name = "Shop", label = UiText.SHOP, icon = "shop", variant = "Close", layoutOrder = 1 })
	button.Activated:Connect(function()
		Sound.play("Click")
		if UIKit.isOpen(window) then
			UIKit.close(window)
		else
			open(nil)
		end
	end)
	Bus.handle("OpenShop", open)

	PlayerState.Changed:Connect(function(_state: Types.PlayerSnapshot)
		if UIKit.isOpen(window) then
			render()
		end
	end)
	-- Pases comprados: el servidor pone el atributo; la tarjeta pasa a OWNED.
	player.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, 4) == "Pass" and UIKit.isOpen(window) then
			render()
		end
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, _productId: number, purchased: boolean)
		if userId == player.UserId and purchased then
			Sound.play("Cash")
		end
	end)
end

return ShopController
