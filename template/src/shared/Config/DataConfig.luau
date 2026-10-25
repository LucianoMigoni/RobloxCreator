--!strict
-- Configuración de DataService (server/Data/DataService.luau).

local DataConfig = {
	-- Cambiarlo empieza todos los datos desde cero: solo para cambios incompatibles de formato.
	STORE_NAME = "PlayerData_v1",
	KEY_PREFIX = "Player_",

	AUTOSAVE_SECONDS = 180, -- valor de la guía oficial; cada jugador arranca con un desfase al azar
	-- Más de 3 autoguardados: un servidor vivo siempre renueva el bloqueo antes de que venza.
	-- Si un servidor se cae sin liberarlo, el jugador espera como mucho esto para recuperar sus datos.
	LOCK_EXPIRY_SECONDS = 600,
	-- Si otro servidor tiene el bloqueo (el jugador acaba de cambiar de servidor), se reintenta ~30 s
	-- para darle tiempo a terminar su guardado final.
	LOCKED_RETRY_ATTEMPTS = 5,
	LOCKED_RETRY_SECONDS = 6,

	MAX_ATTEMPTS = 4, -- reintentos ante errores de DataStore
	RETRY_BASE_SECONDS = 1, -- espera 1, 2, 4 s entre intentos
	CLOSE_TIMEOUT_SECONDS = 25, -- BindToClose da 30 s en total

	-- Datos de un jugador nuevo. Agregar campos acá es seguro: Reconcile los completa en jugadores existentes.
	DEFAULT_DATA = {
		coins = 0,
		inventory = {} :: { string },
	},
}

return DataConfig
