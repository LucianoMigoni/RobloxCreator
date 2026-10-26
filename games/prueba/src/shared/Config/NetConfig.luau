--!strict
return {
	-- Cuánto espera el cliente a que el servidor cree un remote antes de fallar con un error claro.
	WAIT_SECONDS = 15,
	-- GetPlayerState: el cliente lo pide al entrar; más que esto es un cliente modificado.
	STATE_RATE = { count = 2, perSeconds = 1 },
}
