--!strict
-- Lo que cambia de un juego a otro antes de tocar cualquier sistema. Todo lo que ve el jugador va en
-- inglés (regla del hub).

return {
	NAME = "My Hit Game",
	-- Fórmula del juego (server/Kits/<KIT>): "Steal", "Hatch", "Speed", "Fishing", "Search" o "None".
	KIT = "None",
	-- Grupo de Roblox del juego: premio por unirse y bono permanente (0 = sin grupo todavía).
	GROUP_ID = 0,
	-- Qué se ve en la tabla de jugadores de Roblox (arriba a la derecha), en este orden.
	LEADERSTATS = { "Money", "Rebirths" },
	-- Menú de la izquierda: "wide" (botones anchos con ícono plano, como Steal An Egg) o "tile"
	-- (cuadrados con ícono 3D, como Anime Dice). Muestra: roblox-ui-designer/references/hud-hits/.
	HUD_MENU = "wide",
	-- Mascota de la marca para los avisos grandes ("LEVEL UP!"): rbxassetid de una imagen, o "" para no usar.
	MASCOT_IMAGE = "",
}
