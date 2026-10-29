--!strict
-- Ids de Roblox de los assets propios del juego, por nombre de archivo sin extensión:
-- - icons: objetos 3D del HUD (assets/ui/hud-icons; también hit-icons).
-- - flat y flatPlain: íconos planos con contorno y lisos (assets/ui/icons-flat).
-- - textures: material de la UI (assets/ui/hit-skin: studs, franjas, rayos).
-- - sounds, voices y vfx: audio y partículas.
-- - models: modelos subidos.
-- Lo reescribe `python tools/roblox_upload.py luau` desde games/<juego>/assets.lock.json: no editar a
-- mano. Vacío = todavía sin subir: Icons muestra el emoji, UIKit dibuja sin texturas y AudioConfig usa
-- los sonidos de la biblioteca de Roblox, así la plantilla funciona desde el primer momento.

return {
	icons = {} :: { [string]: string },
	flat = {} :: { [string]: string },
	flatPlain = {} :: { [string]: string },
	textures = {} :: { [string]: string },
	sounds = {} :: { [string]: string },
	voices = {} :: { [string]: string },
	vfx = {} :: { [string]: string },
	models = {} :: { [string]: string },
}
