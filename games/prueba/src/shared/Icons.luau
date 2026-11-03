--!strict
-- Íconos por nombre. Dos familias, como en los hits (roblox-ui-designer/references/hud-hits.md):
-- - Objetos 3D (assets/ui/hud-icons: "cash", "shop", "luck_blue", "egg"...): Icons.resolve.
-- - Planos blancos para botones chicos y la barra de Roblox (assets/ui/icons-flat): Icons.flat.
-- Si el juego ya los subió, AssetIds trae el rbxassetid; si no, se muestra el emoji de respaldo para que
-- la UI funcione igual en el primer playtest. Un valor que ya es "rbxassetid://..." o un emoji pasa tal
-- cual. La configuración (monedas, impulsos, productos) guarda nombres de ícono, nunca ids.

local AssetIds = require("./Config/AssetIds")
local KitConfig = require("./Config/KitConfig")

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
	-- armador (2026-11-02): todavía sin ícono 3D, ver tarea de íconos
	merge = "⏫",
	pad = "🛒",
	tap = "👆",
	steps = "👟",
	seed = "🌱",
	-- Unidades de muestra de las recetas (assets/ui/unit-icons y pet-icons), hasta subir sus imágenes.
	banana_buddy = "🍌",
	toast_pal = "🍞",
	cactus_cowboy = "🌵",
	disco_donut = "🍩",
	pizza_pirate = "🍕",
	robo_pickle = "🥒",
	ninja_noodle = "🍜",
	astro_avocado = "🥑",
	taco_king = "🌮",
	sardine = "🐟",
	clownfish = "🐠",
	pufferfish = "🐡",
	salmon = "🐟",
	swordfish = "🐟",
	octopus = "🐙",
	shark = "🦈",
	golden_koi = "🎏",
	baby_kraken = "🦑",
	chick = "🐤",
	hen = "🐔",
	rooster = "🐓",
	golden_hen = "🐔",
	robo_hen = "🤖",
	ninja_hen = "🥷",
	wizard_hen = "🧙",
	king_rooster = "👑",
	cosmic_hen = "🌌",
	baby_raptor = "🦖",
	stego = "🦕",
	trike = "🦕",
	ankylo = "🦕",
	ptero = "🦅",
	parasaur = "🦕",
	spino = "🦖",
	trex = "🦖",
	crystal_rex = "💎",
	carrot = "🥕",
	tomato = "🍅",
	corn = "🌽",
	pumpkin = "🎃",
	watermelon = "🍉",
	strawberry = "🍓",
	dragon_fruit = "🐉",
	golden_apple = "🍎",
	rainbow_melon = "🌈",
	old_boot = "👢",
	rubber_duck = "🦆",
	toy_robot = "🤖",
	pearl = "🦪",
	gold_ring = "💍",
	ancient_coin = "🪙",
	magic_crystal = "🔮",
	golden_needle = "🪡",
	rainbow_needle = "🪡",
	cat = "🐱",
	dog = "🐶",
	bunny = "🐰",
	fox = "🦊",
	penguin = "🐧",
	panda = "🐼",
	tiger = "🐯",
	elephant = "🐘",
}

-- ¿Tiene emoji de respaldo? (los tests de las recetas lo piden para cada ícono que usan)
function Icons.hasFallback(key: string): boolean
	local own = KitConfig.iconFallbacks
	return EMOJI[key] ~= nil or (own ~= nil and own[key] ~= nil)
end

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
	local own = KitConfig.iconFallbacks
	return { text = EMOJI[key] or (if own then own[key] else nil) or key }
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
