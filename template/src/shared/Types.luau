--!strict
-- Tipos que comparten servidor y cliente.

-- Lo que el cliente ve de sus datos (PlayerStateService → PlayerState). Nunca recibos ni datos internos.
export type PlayerSnapshot = {
	coins: number,
	inventory: { string },
	-- false si los datos no cargaron: el progreso de esta sesión no se guarda.
	savesProgress: boolean,
}

-- Un ModuleScript tiene que devolver exactamente un valor.
return {}
