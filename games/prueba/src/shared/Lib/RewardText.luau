--!strict
-- Cómo se ve un premio antes de reclamarlo (calendario diario, regalos por tiempo, misiones, ruleta,
-- ofertas): partes con ícono y texto corto ("$12.5K", "2x Money 15m", "+3 Spins"). Los premios en
-- minutos de ganancia se muestran con lo que valdrían hoy. Sin Roblox (tests/RewardText.spec.luau):
-- las configuraciones se cargan solo si no se pasa `catalog`.

local Types = require("../Types")
local Format = require("./Format")

local RewardText = {}

export type Part = { icon: string, text: string }

export type Catalog = {
	currencies: { [string]: { symbol: string, icon: string } },
	timed: { [string]: { label: string, icon: string } },
	server: { [string]: { label: string, icon: string } },
	minIncome: number,
}

local cached: Catalog? = nil

local function defaultCatalog(): Catalog
	if not cached then
		local EconomyConfig = require("../Config/EconomyConfig")
		local BoostConfig = require("../Config/BoostConfig")
		cached = {
			currencies = EconomyConfig.CURRENCIES :: any,
			timed = BoostConfig.TIMED :: any,
			server = BoostConfig.SERVER :: any,
			minIncome = EconomyConfig.MIN_INCOME_PER_SECOND,
		}
	end
	return cached :: Catalog
end

function RewardText.parts(reward: Types.Reward, incomePerSecond: number?, catalog: Catalog?): { Part }
	local c = catalog or defaultCatalog()
	local out: { Part } = {}
	local currencyId = reward.currency
	if currencyId then
		local currency = c.currencies[currencyId]
		if currency then
			local amount = reward.amount or 0
			if reward.incomeMinutes then
				amount += reward.incomeMinutes * 60 * math.max(c.minIncome, incomePerSecond or 0)
			end
			table.insert(out, { icon = currency.icon, text = Format.money(math.floor(amount), currency.symbol) })
		end
	end
	if reward.boost and reward.seconds then
		local def = c.timed[reward.boost]
		if def then
			table.insert(out, { icon = def.icon, text = def.label .. " " .. Format.short(reward.seconds) })
		end
	end
	if reward.serverBoost and reward.seconds then
		local def = c.server[reward.serverBoost]
		if def then
			table.insert(out, { icon = def.icon, text = def.label .. " " .. Format.short(reward.seconds) })
		end
	end
	if reward.spins and reward.spins > 0 then
		table.insert(out, { icon = "spin", text = "+" .. reward.spins .. (if reward.spins == 1 then " Spin" else " Spins") })
	end
	if reward.item then
		local count = reward.count or 1
		table.insert(out, { icon = "gift", text = (reward.label or reward.item) .. (if count > 1 then " x" .. count else "") })
	end
	return out
end

-- El ícono principal de un premio (para la casilla del calendario o la ruleta).
function RewardText.icon(reward: Types.Reward, catalog: Catalog?): string
	local parts = RewardText.parts(reward, 0, catalog)
	return if parts[1] then parts[1].icon else "gift"
end

return RewardText
