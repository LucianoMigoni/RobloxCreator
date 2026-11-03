--!strict
-- Rarezas, mutaciones y tamaños, como en los hits. Las tablas de cada huevo, cinta o zona viven en el
-- kit; acá está lo que comparten: nombres, colores y cuánto multiplica cada variante.

export type Tier = {
	id: string, -- se ve en el juego (inglés)
	color: Color3,
	rainbow: boolean?, -- texto con degradé arcoíris animado
	announce: boolean?, -- aviso a todo el servidor cuando alguien consigue una
	global: boolean?, -- aviso también a los otros servidores
}

export type Variant = {
	id: string,
	weight: number,
	mult: number, -- multiplica el valor y el ingreso
	lucky: boolean?, -- la suerte la vuelve más probable
	color: Color3?,
	rainbow: boolean?,
	scale: number?, -- tamaños: escala del modelo
}

return {
	TIERS = {
		{ id = "Common", color = Color3.fromRGB(190, 196, 206) },
		{ id = "Uncommon", color = Color3.fromRGB(90, 220, 110) },
		{ id = "Rare", color = Color3.fromRGB(70, 160, 255) },
		{ id = "Epic", color = Color3.fromRGB(180, 95, 255) },
		{ id = "Legendary", color = Color3.fromRGB(255, 200, 30), announce = true },
		{ id = "Mythic", color = Color3.fromRGB(255, 70, 135), announce = true },
		{ id = "Secret", color = Color3.fromRGB(255, 255, 255), rainbow = true, announce = true, global = true },
	} :: { Tier },

	MUTATIONS = {
		{ id = "Normal", weight = 1000, mult = 1 },
		{ id = "Gold", weight = 60, mult = 2, lucky = true, color = Color3.fromRGB(255, 205, 60) },
		{ id = "Diamond", weight = 15, mult = 3, lucky = true, color = Color3.fromRGB(110, 230, 255) },
		{ id = "Rainbow", weight = 4, mult = 5, lucky = true, rainbow = true },
		{ id = "Galaxy", weight = 1, mult = 10, lucky = true, color = Color3.fromRGB(150, 80, 255) },
	} :: { Variant },

	SIZES = {
		{ id = "Normal", weight = 900, mult = 1, scale = 1 },
		{ id = "Big", weight = 90, mult = 1.5, scale = 1.35, lucky = true },
		{ id = "Huge", weight = 10, mult = 3, scale = 1.9, lucky = true },
	} :: { Variant },
}
