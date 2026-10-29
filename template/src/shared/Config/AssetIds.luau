--!strict
-- Ids de Roblox de los assets propios del juego: íconos (assets/ui/hit-icons), efectos y voces
-- (assets/audio/hit-sfx, hit-voices) y texturas de partículas (assets/vfx/hit), por nombre de archivo
-- sin extensión. Lo reescribe `python tools/roblox_upload.py luau` desde games/<juego>/assets.lock.json:
-- no editar a mano. Vacío = todavía sin subir: Icons muestra el emoji y AudioConfig usa los sonidos
-- de la biblioteca de Roblox, así la plantilla funciona desde el primer momento.

return {
	icons = {} :: { [string]: string },
	sounds = {} :: { [string]: string },
	voices = {} :: { [string]: string },
	vfx = {} :: { [string]: string },
}
