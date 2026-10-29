--!strict
-- Íconos por nombre. Dos familias, como en los hits (roblox-ui-designer/references/hud-hits.md):
-- - Objetos 3D (assets/ui/hud-icons: "cash", "shop", "luck_blue", "egg"...): Icons.resolve.
-- - Planos blancos para botones chicos y la barra de Roblox (assets/ui/icons-flat): Icons.flat.
-- Si el juego ya los subió, AssetIds trae el rbxassetid; si no, se muestra el emoji de respaldo para que
-- la UI funcione igual en el primer playtest. Un valor que ya es "rbxassetid://..." o un emoji pasa tal
-- cual. La configuración (monedas, impulsos, productos) guarda nombres de ícono, nunca ids.

local AssetIds = require("./Config/AssetIds")

local Icons = {}

local EMOJI: { [string]: string } = {
	coins = "🪙",
	cash = "💵",
	gem = "💎",
	gift = "🎁",
	chest = "💰",
	trophy = "🏆",
	egg_gold = "🥚",
	crown = "👑",
	star = "⭐",
	shop = "🛒",
	index = "📖",
	rebirth = "🔄",
	quests = "📜",
	daily = "📅",
	spin = "🎡",
	codes = "🎟️",
	settings = "⚙️",
	teleport = "🌀",
	speed = "⚡",
	luck = "🍀",
	money_boost = "💰",
	strength = "💪",
	magnet = "🧲",
	timer = "⏳",
	friends = "👥",
	shield = "🛡️",
	lock = "🔒",
	inventory = "🎒",
	pets = "🐾",
	base = "🏠",
	map = "🗺️",
	potion = "🧪",
	battle = "⚔️",
	fishing = "🎣",
	search = "🔍",
	notifications = "🔔",
	egg_common = "🥚",
	egg_uncommon = "🥚",
	egg_rare = "🥚",
	egg_epic = "🥚",
	egg_legendary = "🥚",
	egg_mythic = "🥚",
	egg_secret = "🥚",
	egg_halloween = "🎃",
	egg_winter = "❄️",
	robux = "R$",
	close = "✖",
	-- hud-icons (2026-10-29)
	luck_blue = "🍀",
	egg = "🥚",
	medal = "🏅",
	boost = "⚡",
	dice = "🎲",
	fire = "🔥",
	treadmill = "🏃",
	pickaxe = "⛏️",
	heart = "❤️",
	invite = "➕",
	moon = "🌙",
	plus = "➕",
	check = "✔️",
	trade = "🔁",
}

export type Resolved = { image: string?, text: string? }

-- Imagen o texto para un nombre de ícono.
function Icons.resolve(key: string?): Resolved
	if not key or key == "" then
		return {}
	end
	if string.sub(key, 1, 13) == "rbxassetid://" or string.sub(key, 1, 7) == "rbxasset" then
		return { image = key }
	end
	local id = AssetIds.icons[key]
	if id and id ~= "" then
		return { image = id }
	end
	return { text = EMOJI[key] or key }
end

-- Ícono plano por nombre (assets/ui/icons-flat). `plain` = blanco liso, para la barra de Roblox o para
-- teñir con ImageColor3; si no, blanco con contorno oscuro. Sin subir: el emoji del 3D.
function Icons.flat(key: string?, plain: boolean?): Resolved
	if not key or key == "" then
		return {}
	end
	local id = (if plain then AssetIds.flatPlain else AssetIds.flat)[key]
	if id and id ~= "" then
		return { image = id }
	end
	return Icons.resolve(key)
end

-- Ya subido a Roblox (para decidir si vale la pena mostrar una imagen grande).
function Icons.hasImage(key: string?): boolean
	return Icons.resolve(key).image ~= nil
end

-- Para los tests: el emoji de respaldo de un nombre.
function Icons.fallback(key: string): string?
	return EMOJI[key]
end

return Icons
