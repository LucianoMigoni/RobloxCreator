--!strict
-- Tienda estilo hit (ShopConfig, roblox-ui-designer/references/hud-hits.md §Tienda): una sola lista con
-- secciones, sin pestañas, como Steal An Egg, Anime Dice y Throw Food For Animals:
-- 1. Destacado: la oferta de ShopConfig.FEATURED con arte, reloj (solo si termina de verdad) y precio;
--    el anuncio con premio y la suscripción VIP.
-- 2. Impulsos, impulsos para todo el servidor, plata y gemas (lo que daría hoy: "≈ $1.2M"), giros, pases
--    (con regalo al lado) y lo del kit.
-- Precios: los del Dashboard (GetProductInfoAsync), porque Roblox los ajusta por región y con pruebas de
-- precio; `robux` de la configuración es solo el de respaldo.
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
local Workspace = game:GetService("Workspace")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local RewardText = require(ReplicatedStorage.Shared.Lib.RewardText)
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

-- Secciones en orden. Las categorías de ShopConfig.Product van a la suya; "Featured" va arriba.
type Section = { id: string, title: string, columns: number, aspect: number, variant: UIKit.Variant }
local SECTIONS: { Section } = {
	{ id = "Boosts", title = UiText.SECTION_BOOSTS, columns = 4, aspect = 0.78, variant = "Accept" },
	{ id = "Server", title = UiText.SECTION_SERVER, columns = 2, aspect = 1.25, variant = "Pink" },
	{ id = "Currency", title = UiText.SECTION_CASH, columns = 3, aspect = 0.86, variant = "Info" },
	{ id = "Spins", title = UiText.SECTION_SPINS, columns = 3, aspect = 0.86, variant = "Cyan" },
	{ id = "Passes", title = UiText.SECTION_PASSES, columns = 3, aspect = 0.8, variant = "Purple" },
	{ id = "Kit", title = UiText.SECTION_SPECIAL, columns = 3, aspect = 0.86, variant = "Premium" },
}

local prices: { [string]: number } = {} -- "Product:123" / "GamePass:45" → precio del Dashboard
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

local function productByKey(key: string): ShopConfig.Product?
	for _, product in ShopConfig.PRODUCTS do
		if product.key == key then
			return product
		end
	end
	return nil
end

function ShopController.start(hud: Hud.Hud)
	local window, body = UIKit.window(hud.screen, { name = "Shop", title = UiText.SHOP, icon = "shop", variant = "Accept" })
	local adAvailable = false
	local list: ScrollingFrame? = nil
	local anchors: { [string]: Frame } = {}
	local stopClocks: (() -> ())? = nil

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

	local function soon(footer: Frame)
		UIKit.label(footer, "Soon", UiText.UNAVAILABLE, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 24)
	end

	local function buyButton(footer: Frame, robux: number, width: number?): TextButton
		return UIKit.priceButton(footer, "Buy", robux, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromScale(width or 1, 1),
			ZIndex = 4,
		})
	end

	local function productCard(parent: Instance, product: ShopConfig.Product, variant: UIKit.Variant, order: number)
		local card = UIKit.card(parent, {
			name = product.key,
			title = product.name,
			desc = describe(product),
			icon = product.icon,
			variant = variant,
			layoutOrder = order,
		})
		if product.tag then
			UIKit.ribbon(card, product.tag, "Close")
			Juice.shine(card, 3)
		end
		local footer = card:FindFirstChild("Footer") :: Frame
		if product.productId == 0 then
			soon(footer)
			return
		end
		local button = buyButton(footer, product.robux)
		button.Activated:Connect(function()
			Sound.play("Click")
			MarketplaceService:PromptProductPurchase(player, product.productId)
		end)
		fetchPrice(Enum.InfoType.Product, product.productId, function(price)
			UIKit.setPrice(button, price)
		end)
	end

	local function passCard(parent: Instance, pass: ShopConfig.Pass, order: number, owned: boolean, giftable: boolean)
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
			UIKit.label(footer, "Owned", UiText.OWNED, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 30)
		elseif pass.passId == 0 then
			soon(footer)
		else
			local button = buyButton(footer, pass.robux, if giftable then 0.66 else 1)
			button.Activated:Connect(function()
				Sound.play("Click")
				MarketplaceService:PromptGamePassPurchase(player, pass.passId)
			end)
			fetchPrice(Enum.InfoType.GamePass, pass.passId, function(price)
				UIKit.setPrice(button, price)
			end)
		end
		if giftable then
			local gift = UIKit.giftButton(footer, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.3, 1), -- cuadrado: lo limita el alto del pie
				ZIndex = 4,
			})
			gift.Activated:Connect(function()
				Sound.play("Click")
				Bus.call("OpenGift", pass.key)
			end)
		end
	end

	-- Oferta destacada ancha, con rayos detrás del arte, contenido, reloj si termina y precio con ancla.
	local function featuredCard(parent: Instance, product: ShopConfig.Product, featured: ShopConfig.Featured, order: number): (() -> ())?
		local small = UIKit.isSmallScreen()
		local card = UIKit.new("Frame", { Name = "Featured", Size = UDim2.new(0.96, 0, 0, 200), LayoutOrder = order }, parent) :: Frame
		UIKit.style(card, "Purple", 0.06, 0.012, "checker")
		UIKit.fitHeight(card, if small then 2 else 2.6)
		local art = UIKit.new("Frame", {
			Name = "Art",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.02, 0.55),
			Size = UDim2.fromScale(0.28, 0.8),
			ZIndex = 3,
		}, card) :: Frame
		UIKit.sunburst(art, Color3.fromRGB(255, 200, 120), 1.1, 0.35)
		UIKit.icon(art, product.icon, { Size = UDim2.fromScale(1, 1), ZIndex = 4 })
		UIKit.ribbon(card, UiText.TAG_NEW, "Close").Position = UDim2.fromScale(0.08, 0.1)
		local title = UIKit.label(card, "Title", featured.title or product.name, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0.3, 0.06),
			Size = UDim2.fromScale(0.42, 0.2),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
		}, 64)
		title.TextColor3 = Color3.fromRGB(255, 176, 46)
		-- Lo que trae, con íconos (RewardText), en una fila.
		local parts = UIKit.new("Frame", {
			Name = "Parts",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.3, 0.34),
			Size = UDim2.fromScale(0.68, 0.3),
			ZIndex = 4,
		}, card) :: Frame
		UIKit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, parts)
		local income = player:GetAttribute("Income")
		for i, reward in product.grant do
			for j, part in RewardText.parts(reward, if typeof(income) == "number" then income else 0) do
				local tile = UIKit.new("Frame", {
					Name = "Part" .. i .. "_" .. j,
					Size = UDim2.fromScale(1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					LayoutOrder = i * 10 + j,
					ZIndex = 4,
				}, parts) :: Frame
				UIKit.style(tile, "Dark", 0.18, 0.04)
				UIKit.icon(tile, part.icon, { Position = UDim2.fromScale(0.12, 0.04), Size = UDim2.fromScale(0.76, 0.66), ZIndex = 5 })
				UIKit.label(tile, "Text", part.text, {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 0.97),
					Size = UDim2.fromScale(0.94, 0.3),
					ZIndex = 6,
				}, 26)
			end
		end
		-- Reloj y "Limited time!" solo si la oferta termina de verdad.
		local stop: (() -> ())? = nil
		local endsAt = featured.endsAt
		if endsAt then
			UIKit.label(card, "Limited", UiText.LIMITED, {
				Position = UDim2.fromScale(0.3, 0.24),
				Size = UDim2.fromScale(0.3, 0.1),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 4,
			}, 34)
			local clock = UIKit.label(card, "Clock", "", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(0.97, 0.07),
				Size = UDim2.fromScale(0.3, 0.16),
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 4,
			}, 48)
			local running = true
			task.spawn(function()
				while running and card.Parent do
					clock.Text = Format.duration(math.max(0, endsAt - Workspace:GetServerTimeNow()))
					task.wait(1)
				end
			end)
			stop = function()
				running = false
			end
		end
		local footer = UIKit.new("Frame", {
			Name = "Footer",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(0.97, 0.93),
			Size = if small then UDim2.fromScale(0.34, 0.28) else UDim2.fromScale(0.3, 0.22),
			ZIndex = 4,
		}, card) :: Frame
		if product.productId == 0 then
			soon(footer)
		else
			local button = UIKit.priceButton(footer, "Buy", product.robux, { Size = UDim2.fromScale(1, 1), ZIndex = 5 }, "Accept", featured.anchor)
			Juice.shine(button, 2.5)
			button.Activated:Connect(function()
				Sound.play("Click")
				MarketplaceService:PromptProductPurchase(player, product.productId)
			end)
			fetchPrice(Enum.InfoType.Product, product.productId, function(price)
				UIKit.setPrice(button, price)
			end)
		end
		return stop
	end

	local function adCard(parent: Instance, order: number)
		local card = UIKit.card(parent, {
			name = "RewardedAd",
			title = "FREE 2x Money",
			desc = UiText.AD_INFO,
			icon = "money_boost",
			variant = "Accept",
			layoutOrder = order,
		})
		UIKit.ribbon(card, "FREE", "Close")
		local footer = card:FindFirstChild("Footer") :: Frame
		local watch = UIKit.button({ name = "Watch", text = UiText.WATCH_AD, variant = "Pink", parent = footer, size = UDim2.fromScale(1, 1), aspectRatio = 3.2 })
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
		if stopClocks then
			stopClocks()
			stopClocks = nil
		end
		if list then
			list:Destroy()
		end
		local scroll = UIKit.list(body, "List")
		scroll.ZIndex = 21
		list = scroll
		table.clear(anchors)
		local state = PlayerState.get()
		local restricted = player:GetAttribute("PaidRandomRestricted") == true
		local order = 0
		local function hidden(product: ShopConfig.Product): boolean
			return product.giftOf ~= nil
				or (product.random == true and restricted)
				or (product.once == true and state ~= nil and state.boughtOnce[product.key] == true)
				or product.key == "OfflineDouble" -- se ofrece en el cartel de bienvenida
		end

		-- 1. Destacado
		local head = UIKit.section(scroll, UiText.SECTION_FEATURED, 0, Color3.fromRGB(255, 217, 58))
		anchors.Featured = head
		order = 1
		local featured = ShopConfig.FEATURED
		local featuredProduct = if featured then productByKey(featured.key) else nil
		if featured and featuredProduct and not hidden(featuredProduct) then
			stopClocks = featuredCard(scroll, featuredProduct, featured, order)
			order += 1
		end
		local small = UIKit.isSmallScreen()
		local extras = UIKit.row(scroll, "FeaturedRow", order, if small then 2 else 3, 0.86)
		order += 1
		local extraCount = 0
		if adAvailable then
			adCard(extras, 1)
			extraCount += 1
		end
		for i, sub in ShopConfig.SUBSCRIPTIONS do
			local card = UIKit.card(extras, { name = sub.key, title = sub.name, desc = sub.desc, icon = sub.icon, variant = "Premium", layoutOrder = 10 + i })
			UIKit.ribbon(card, "VIP", "Purple")
			Juice.shine(card, 3)
			local footer = card:FindFirstChild("Footer") :: Frame
			if player:GetAttribute(sub.attribute) == true then
				UIKit.label(footer, "Owned", UiText.OWNED_PASS, { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, 30)
			elseif sub.subscriptionId == "" then
				soon(footer)
			else
				local buy = UIKit.button({ name = "Buy", text = UiText.BUY, variant = "Accept", parent = footer, size = UDim2.fromScale(1, 1), aspectRatio = 3.2 })
				buy.ZIndex = 4
				buy.Activated:Connect(function()
					Sound.play("Click")
					MarketplaceService:PromptSubscriptionPurchase(player, sub.subscriptionId)
				end)
			end
			extraCount += 1
		end
		if extraCount == 0 then
			extras:Destroy()
		end

		-- 2. El resto, por categoría
		local gifts: { [string]: boolean } = {}
		for _, product in ShopConfig.PRODUCTS do
			if product.giftOf and product.productId ~= 0 then
				gifts[product.giftOf] = true
			end
		end
		for _, section in SECTIONS do
			local items = 0
			local row: Frame? = nil
			local function ensureRow(): Frame
				if not row then
					local title = UIKit.section(scroll, section.title, order)
					anchors[section.id] = title
					order += 1
					-- En el teléfono, 2 columnas y tarjetas más altas: el botón de compra llega a 44 px.
					row = if small
						then UIKit.row(scroll, section.id, order, math.min(section.columns, 2), math.min(section.aspect, 0.95))
						else UIKit.row(scroll, section.id, order, section.columns, section.aspect)
					order += 1
				end
				return row :: Frame
			end
			if section.id == "Passes" then
				for _, pass in ShopConfig.PASSES do
					items += 1
					passCard(ensureRow(), pass, items, player:GetAttribute(pass.attribute) == true, gifts[pass.key] == true)
				end
			else
				for _, product in ShopConfig.PRODUCTS do
					if product.category == section.id and product.key ~= (featured and featured.key) and not hidden(product) then
						items += 1
						productCard(ensureRow(), product, section.variant, items)
					end
				end
			end
		end
	end

	-- Abre la tienda en una sección ("Currency", "Passes"...): baja hasta su título.
	local function open(section: string?)
		render()
		UIKit.open(window)
		if section then
			task.defer(function()
				local anchor = anchors[section]
				local scroll = list
				if anchor and scroll then
					local y = anchor.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
					scroll.CanvasPosition = Vector2.new(0, math.max(0, y))
				end
			end)
		end
		-- Regla de AdService: preguntar si hay anuncio cuando se abre la tienda, no antes.
		task.spawn(function()
			local ok, result = pcall(AdService.GetAdAvailabilityNowAsync, AdService, Enum.AdFormat.RewardedVideo)
			local available = ok and typeof(result) == "table" and result.AdAvailabilityResult == Enum.AdAvailabilityResult.IsAvailable
			if available ~= adAvailable then
				adAvailable = available
				if UIKit.isOpen(window) then
					render()
				end
			end
		end)
	end

	local button = hud.addButton("left", { name = "Shop", label = UiText.SHOP, icon = "shop", variant = if hud.menuStyle == "tile" then "Rainbow" else "Accept", layoutOrder = 1 })
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
