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
	-- Los kits agregan los suyos en `kits[<nombre>]` con DataService.registerKit (antes de start).
	DEFAULT_DATA = {
		currencies = {} :: { [string]: number }, -- EconomyConfig.CURRENCIES; DataService completa el saldo inicial
		inventory = {} :: { string },
		processedReceipts = {} :: { [string]: number }, -- PurchaseId → hora: compras de Robux ya otorgadas
		firstPlayedAt = 0,
		lastSeen = 0, -- os.time() del servidor al salir (ganancias sin conexión)
		lastIncome = 0, -- plata por segundo al salir
		objective = { index = 1, progress = 0 },
		daily = { lastClaimDay = -1, streak = 0 },
		playtime = { day = -1, seconds = 0, claimed = {} :: { number } },
		quests = { day = -1, ids = {} :: { string }, progress = {} :: { [string]: number }, claimed = {} :: { [string]: boolean }, bonusClaimed = false },
		spins = { tickets = 0, nextFreeAt = 0 },
		codes = {} :: { [string]: boolean },
		groupClaimed = false,
		referralRewarded = false,
		rebirths = 0,
		index = {} :: { [string]: boolean }, -- lo descubierto: "unidad|variante"
		indexClaimed = {} :: { [string]: boolean }, -- zonas del índice con el premio ya cobrado
		boosts = {} :: { [string]: number }, -- impulso personal → hora en que termina
		boughtOnce = {} :: { [string]: boolean }, -- productos de una sola vez ya comprados
		giftedPasses = {} :: { [string]: boolean }, -- pases que otro jugador le regaló
		pendingOffline = 0, -- ganancias sin conexión de la última entrada (para la oferta de duplicarlas)
		campaignCodes = {} :: { [string]: boolean }, -- LaunchData de campañas y links ya premiados
		giftTokens = {} :: { [string]: number }, -- regalos de pases pagados que todavía no se entregaron
		settings = { music = true, sfx = true, lowGraphics = false }, -- Ajustes del jugador (SettingsService)
		kits = {} :: { [string]: any },
	},
}

return DataConfig
