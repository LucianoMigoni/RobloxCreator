--!strict
-- Números y tiempos como los muestran los hits: "$9,861", "$356.6K", "$1.43B", "36.76Qa", "1 in 9,342,584",
-- "2h 28m 42s", "09:20:37". Sin Roblox: se prueba en tests/Format.spec.luau.

local Format = {}

-- Debajo de esto se muestra el número entero con comas ("$56,261"); arriba, con sufijo ("$356.6K").
Format.FULL_BELOW = 100_000

local SUFFIXES = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg",
}

function Format.commas(n: number): string
	local negative = n < 0
	local digits = string.format("%.0f", math.floor(math.abs(n)))
	local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if negative then "-" else "") .. out
end

local function trim(text: string): string
	if text:find("%.") then
		text = text:gsub("0+$", ""):gsub("%.$", "")
	end
	return text
end

-- 3 o 4 cifras significativas: 1.43B, 36.76Qa, 533.5T, 356.6K.
function Format.number(n: number): string
	if n ~= n then
		return "0"
	end
	local abs = math.abs(n)
	if abs < Format.FULL_BELOW then
		return Format.commas(n)
	end
	if abs == math.huge then
		return if n > 0 then "∞" else "-∞"
	end
	local tier = math.floor(math.log10(abs) / 3)
	if tier > #SUFFIXES then
		return string.format("%.2e", n)
	end
	local scaled = n / 10 ^ (tier * 3)
	-- Al redondear, 999.96K tiene que pasar a 1M y no quedar en "1000K".
	if math.abs(scaled) >= 999.95 and tier < #SUFFIXES then
		tier += 1
		scaled /= 1000
	end
	local decimals = if math.abs(scaled) < 100 then 2 else 1
	return trim(string.format("%." .. decimals .. "f", scaled)) .. SUFFIXES[tier]
end

function Format.money(n: number, symbol: string?): string
	return (symbol or "$") .. Format.number(n)
end

function Format.perSecond(n: number, symbol: string?): string
	return Format.money(n, symbol) .. "/s"
end

-- "x2", "x1.5", "x0.75".
function Format.multiplier(m: number): string
	return "x" .. trim(string.format("%.2f", m))
end

-- 0.0525 → "5.25%". Probabilidades chicas con más decimales: 0.000012 → "0.0012%".
function Format.percent(p: number, decimals: number?): string
	local value = p * 100
	local d: number = decimals or 2
	if decimals == nil and value > 0 and value < 0.01 then
		d = math.min(8, math.ceil(-math.log10(value)) + 2)
	end
	return trim(string.format("%." .. d .. "f", value)) .. "%"
end

-- Probabilidad como "1 in N" (lo que muestran los hits sobre lo más raro).
function Format.oneIn(chance: number): string
	if chance <= 0 then
		return "—"
	end
	return "1 in " .. Format.commas(math.max(1, math.floor(1 / chance + 0.5)))
end

-- "2h 28m 42s", "4m 8s", "19s", "3d 2h". Para contadores de eventos, ruletas y reposiciones.
function Format.duration(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	s %= 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm %ds", h, m, s)
	elseif m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

-- Duración corta para premios y botones: "2d", "1h", "1h 30m", "15m", "45s" (sin ceros de relleno).
function Format.short(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	s %= 60
	if d > 0 then
		return if h > 0 then string.format("%dd %dh", d, h) else string.format("%dd", d)
	elseif h > 0 then
		return if m > 0 then string.format("%dh %dm", h, m) else string.format("%dh", h)
	elseif m > 0 then
		return if s > 0 then string.format("%dm %ds", m, s) else string.format("%dm", m)
	end
	return string.format("%ds", s)
end

-- "09:20:37" o "00:17", como los relojes de eventos.
function Format.clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local h, m = s // 3600, (s % 3600) // 60
	s %= 60
	if h > 0 then
		return string.format("%02d:%02d:%02d", h, m, s)
	end
	return string.format("%02d:%02d", m, s)
end

return Format
