--!strict
-- Tipos que comparten servidor y cliente.

-- Lo que el cliente ve de sus datos (PlayerStateService → PlayerState). Nunca recibos ni datos internos.
export type PlayerSnapshot = {
	coins: number,
	inventory: { string },
	-- false si los datos no cargaron: el progreso de esta sesión no se guarda.
	savesProgress: boolean,
}

-- Un critter del jugador, tal como se guarda (DataConfig.DEFAULT_DATA.critters).
export type Critter = {
	uid: string,
	tier: number, -- índice en GameplayConfig.TIERS
	mutation: string, -- clave de GameplayConfig.MUTATIONS
	pedestal: number, -- 1..pedestales de la base
}

-- Un ModuleScript tiene que devolver exactamente un valor.
return {}
