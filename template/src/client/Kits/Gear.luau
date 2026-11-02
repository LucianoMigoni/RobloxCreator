--!strict
-- Filas de las tiendas de equipo de los bloques (cañas de pesca, herramientas de búsqueda): la equipada,
-- las que tiene (Equip), las que se compran con monedas del juego y las que solo salen por Robux (un
-- producto de ShopConfig que entrega "<prefijo>:<id>"). El mismo remote compra o equipa.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local Sound = require("../UI/Sound")
local KitUi = require("./KitUi")

export type Item = { id: string, name: string, price: KitTypes.Price? }

local Gear = {}

-- `remote`: "BuyRod" o "BuyTool". `prefix`: "Rod" o "Tool" (premio de los productos). `detail`: la
-- línea de cada una ("Luck x1.5 · Speed x1.2"). `icon`: el de la tienda.
function Gear.rows(items: { Item }, owned: { [string]: boolean }, current: string?, remote: string, prefix: string, icon: string, detail: (Item) -> string): { KitUi.Row }
	local rows: { KitUi.Row } = {}
	for _, item in items do
		local id = item.id
		local row: KitUi.Row = { id = id, icon = icon, title = item.name, detail = detail(item), buttons = {} }
		local function buy()
			Sound.play("Click")
			local ok, reason = KitUi.invoke(remote, id)
			if ok then
				Sound.play("Equip")
			elseif reason == "NOT_ENOUGH" and item.price then
				KitUi.notEnough(item.price.currency)
			else
				KitUi.error(reason)
			end
		end
		if current == id then
			row.variant = "Accept"
			row.buttons = { { text = UiText.EQUIPPED, variant = "Neutral", icon = "check", onClick = function() end } }
		elseif owned[id] then
			row.buttons = { { text = UiText.EQUIP, variant = "Accept", onClick = buy } }
		else
			local price = item.price
			if price then
				local text, priceIcon = KitUi.price(price)
				row.buttons = {
					{
						text = text,
						variant = if KitUi.canPay(price) then "Premium" else "Neutral",
						icon = priceIcon,
						onClick = function()
							if not KitUi.canPay(price) then
								KitUi.notEnough(price.currency)
								return
							end
							buy()
						end,
					},
				}
			end
			local product = KitUi.productFor(prefix .. ":" .. id)
			if product then
				table.insert(row.buttons, { robux = product, variant = "Accept", onClick = function()
					KitUi.buyProduct(product)
				end })
			end
			if #row.buttons == 0 then
				row.variant = "Neutral"
				row.buttons = { { text = UiText.LOCKED, variant = "Neutral", icon = "lock", onClick = function()
					KitUi.error("NOT_FOR_SALE")
				end } }
			end
		end
		table.insert(rows, row)
	end
	return rows
end

return Gear
