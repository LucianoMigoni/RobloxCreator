--!strict
-- Números del juego (docs/spec.md). Nada de valores sueltos en la lógica: se ajustan acá.
-- Los nombres son en inglés porque los ve el jugador.

export type Tier = { name: string, income: number, price: number? }
export type Weight = { tier: number, weight: number }

return {
	-- Un nivel por critter; dos del mismo nivel se fusionan en el siguiente. price = se vende en la cinta.
	TIERS = {
		{ name = "Pebble Pup", income = 1, price = 10 },
		{ name = "Mossling", income = 3, price = 60 },
		{ name = "Bubblebug", income = 7, price = 400 },
		{ name = "Zapfrog", income = 18 },
		{ name = "Cloud Kitty", income = 45 },
		{ name = "Lava Lizard", income = 110 },
		{ name = "Star Owl", income = 275 },
		{ name = "Crystal Dragon", income = 700 },
	} :: { Tier },

	-- Multiplicador de ingreso por mutación (las mutaciones llegan en el hito 3).
	MUTATIONS = { Normal = 1, Gold = 2, Rainbow = 5 } :: { [string]: number },

	PLOTS = 8, -- bases por servidor (= jugadores máximos)
	PEDESTALS = 8, -- pedestales por base, sin pases
	-- Con 8 bases de 30 studs, menos de ~60 hace que se pisen las esquinas de bases vecinas.
	PLOT_RING_RADIUS = 60, -- distancia del centro del mapa (la cinta) a cada base
	PLOT_SIZE = 30,

	BELT_LENGTH = 60, -- corre sobre el eje X por el centro; no toca las bases
	BELT_SPAWN_SECONDS = 4, -- un critter nuevo cada tanto
	BELT_WALK_SECONDS = 20, -- lo que tarda en cruzar la cinta
	BELT_WEIGHTS = {
		{ tier = 1, weight = 70 },
		{ tier = 2, weight = 25 },
		{ tier = 3, weight = 5 },
	} :: { Weight },
	BUY_DISTANCE = 14, -- studs desde el personaje al critter de la cinta
	-- El critter se mueve: el servidor lo ve unos studs más adelante que el cliente que tocó el prompt.
	BUY_DISTANCE_TOLERANCE = 4,

	INCOME_TICK_SECONDS = 1,
}
