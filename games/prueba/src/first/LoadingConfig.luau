--!strict
-- Lo editable de la pantalla de carga (ReplicatedFirst/Loading). Vive acá y no en Shared/Config porque
-- la pantalla sale antes de que llegue ReplicatedStorage. Textos en inglés (se traducen solos).

return {
	-- El nombre del juego, en grande (el mismo que GameConfig.NAME).
	TITLE = "My Hit Game",
	-- Fondo: rbxassetid de la imagen (assets/ui/loading, subida con tools/roblox_upload.py). Vacío = degradé.
	IMAGE = "",
	-- Colores del degradé de respaldo, de arriba hacia abajo (hex).
	GRADIENT = { "#7A2CFF", "#FF4FD8" },
	-- Consejos que van cambiando abajo (inglés simple, cortos).
	TIPS = {
		"Hatch eggs to find rare pets!",
		"Join our group for a FREE gift!",
		"Invite friends: +10% money each!",
		"Come back every day for bigger rewards!",
		"Rebirth to earn money faster!",
		"Finish your quests for a bonus!",
	},
	TIP_SECONDS = 3,
	MIN_SECONDS = 2.5, -- se muestra al menos esto (se lee el nombre)
	MAX_SECONDS = 20, -- y como mucho esto, aunque falte cargar algo
	SKIP_AFTER = 6, -- "Skip" aparece a los tantos segundos
	SKIP = "Skip",
	LOADING = "Loading... %d%%",
}
