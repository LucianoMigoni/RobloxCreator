--!strict
-- Tipos que comparten servidor y cliente.

-- Un premio: lo dan el diario, los regalos por tiempo, las misiones, la ruleta, los códigos, el grupo,
-- los referidos y los productos. Puede combinar varias cosas.
export type Reward = {
	currency: string?, -- moneda (EconomyConfig.CURRENCIES)
	amount: number?, -- monto fijo de esa moneda
	incomeMinutes: number?, -- o "N minutos de tus ganancias" (sigue sirviendo a medida que el jugador crece)
	boost: string?, -- impulso personal (BoostConfig.TIMED)
	serverBoost: string?, -- impulso para todo el servidor (BoostConfig.SERVER)
	seconds: number?, -- duración del impulso
	spins: number?, -- tiradas de la ruleta
	item: string?, -- algo del kit ("Egg:Rare", "Pet:Dragon"...): lo entrega el kit
	count: number?, -- cantidad del item
	label: string?, -- texto en inglés si el automático no alcanza ("Mystery Pet")
}

-- Una parte de un premio como la ve el jugador en el popup: ícono "cash" + "$12.5K", "luck" + "2x Luck · 15m".
-- `icon` es un nombre de shared/Icons.
export type RewardLine = { icon: string, text: string, kind: string, color: Color3? }

-- Lo que manda RewardShown: título grande, las partes del premio y quién lo dio (para el sonido).
export type RewardPopup = { title: string, lines: { RewardLine }, source: string }

-- Una zona del índice como la ve el jugador: su avance, si está abierta y su premio por completarla.
export type IndexZone = {
	id: string,
	name: string,
	image: string?, -- rbxassetid de la foto de la zona
	found: number,
	total: number,
	unlocked: boolean,
	claimed: boolean,
	reward: Reward?,
}

-- Una fuente de multiplicador como la ve el HUD.
export type MultiplierView = { stat: string, kind: string, value: number, label: string }

-- Lo que el cliente ve de sus datos (PlayerStateService → PlayerState). Nunca recibos ni datos internos.
-- Los números que cambian cada segundo (monedas, ingreso) viajan aparte, como atributos del jugador.
export type PlayerSnapshot = {
	currencies: { [string]: number },
	inventory: { string },
	-- false si los datos no cargaron: el progreso de esta sesión no se guarda.
	savesProgress: boolean,
	multipliers: { MultiplierView },
	boosts: { { id: string, label: string, icon: string, endsAt: number, server: boolean } },
	daily: { canClaim: boolean, slot: number, streak: number, nextIn: number },
	playtime: { seconds: number, claimed: { number }, day: number },
	quests: { ids: { string }, progress: { [string]: number }, claimed: { [string]: boolean }, bonusClaimed: boolean },
	spins: { tickets: number, nextFreeAt: number },
	-- Objetivo actual: `text` lleva %s donde va el objetivo formateado ("Earn %s" → "Earn $100").
	objective: { text: string, progress: number, target: number, money: boolean }?,
	rebirths: number,
	rebirthCost: number,
	-- keys: "unidad|variante" descubiertas; zones: vacío si el kit no usa zonas.
	index: { found: number, total: number, keys: { [string]: boolean }, zones: { IndexZone } },
	groupClaimed: boolean,
	ownedPasses: { string },
	boughtOnce: { [string]: boolean }, -- productos de una sola vez ya comprados (no se vuelven a ofrecer)
	giftTokens: { [string]: number }, -- regalos de pases pagados que todavía puede mandar
	pendingOffline: number, -- ganancias sin conexión de esta entrada (oferta de duplicarlas si > 0)
	settings: { music: boolean, sfx: boolean, lowGraphics: boolean },
	-- Lo propio del kit (unidades, huevos, velocidad...): cada kit define su forma.
	kit: any,
}

-- Un ModuleScript tiene que devolver exactamente un valor.
return {}
