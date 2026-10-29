--!strict
-- Monedas del juego. La principal es la plata de los simuladores; las demás son opcionales (gemas, la
-- moneda del evento). Cada una se registra aparte en las analíticas de economía (máximo 10 por juego).

export type Currency = {
	symbol: string, -- se antepone al número: "$" → "$1.2K"; "" para mostrar solo el número
	icon: string, -- nombre de ícono (shared/Icons: "cash", "gem"...)
	color: Color3,
	start: number, -- con cuánto arranca un jugador nuevo
	purchasable: boolean, -- true si se vende por Robux (entonces lo aleatorio que se compra con ella es "aleatorio pago")
}

return {
	MAIN = "Money",
	CURRENCIES = {
		Money = { symbol = "$", icon = "cash", color = Color3.fromRGB(85, 230, 95), start = 10, purchasable = true },
		Gems = { symbol = "", icon = "gem", color = Color3.fromRGB(80, 190, 255), start = 0, purchasable = false },
	} :: { [string]: Currency },
	-- Los simuladores llegan a Qa y más. Por encima de 2^53 se pierde precisión de unidades, que no se ve
	-- en pantalla (Format muestra 3 o 4 cifras).
	MAX_BALANCE = 1e300,
	-- Piso del ingreso por segundo para premios en "minutos de ganancia" (paquetes de plata, ruleta):
	-- un jugador que recién empieza igual recibe algo que se nota.
	MIN_INCOME_PER_SECOND = 5,
}
