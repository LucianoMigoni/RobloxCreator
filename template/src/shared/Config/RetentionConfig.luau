--!strict
-- Todo lo que trae al jugador de vuelta y lo deja jugando: diario con racha, regalos por tiempo,
-- misiones, ruleta, códigos, grupo, ganancias sin conexión, renacer, índice y referidos.
-- Textos en inglés (se ven en el juego). Los montos son de ejemplo: cada juego los ajusta con sus
-- eventos de economía (roblox-metrics-growth).

local Types = require("../Types")

type Reward = Types.Reward

export type QuestDef = {
	id: string,
	text: string, -- %s = objetivo
	stat: string,
	target: number,
	money: boolean?,
	reward: Reward,
}

export type SpinSegment = {
	id: string,
	weight: number,
	label: string,
	color: Color3,
	reward: Reward,
}

return {
	-- Calendario de 7 días: el 7.º es el grande. Saltear un día reinicia la racha.
	DAILY = {
		{ currency = "Money", incomeMinutes = 5, label = "Cash" },
		{ spins = 1 },
		{ boost = "Money2x", seconds = 900 },
		{ currency = "Gems", amount = 10 },
		{ boost = "Luck2x", seconds = 1800 },
		{ spins = 3 },
		{ currency = "Gems", amount = 50, boost = "Luck2x", seconds = 3600, label = "MEGA GIFT" },
	} :: { Reward },

	-- Regalos por minutos jugados en el día ("FREE!"). Los primeros llegan rápido para enganchar.
	PLAYTIME = {
		{ seconds = 60, reward = { currency = "Money", incomeMinutes = 1 } :: Reward },
		{ seconds = 180, reward = { spins = 1 } :: Reward },
		{ seconds = 300, reward = { boost = "Money2x", seconds = 300 } :: Reward },
		{ seconds = 600, reward = { currency = "Gems", amount = 5 } :: Reward },
		{ seconds = 900, reward = { boost = "Luck2x", seconds = 600 } :: Reward },
		{ seconds = 1200, reward = { currency = "Money", incomeMinutes = 10 } :: Reward },
		{ seconds = 1800, reward = { spins = 2 } :: Reward },
		{ seconds = 2700, reward = { currency = "Gems", amount = 15 } :: Reward },
		{ seconds = 3600, reward = { currency = "Gems", amount = 25, boost = "Luck2x", seconds = 1800 } :: Reward },
	},

	-- Misiones diarias: 3 por día del pool, iguales en todos los servidores. Los kits mandan sus
	-- eventos (Steal, Hatch, CatchFish, Steps...) con QuestService.track.
	QUESTS = {
		count = 3,
		pool = {
			{ id = "earn", text = "Earn %s", stat = "MoneyEarned", target = 10_000, money = true, reward = { currency = "Gems", amount = 5 } },
			{ id = "play", text = "Play for %s minutes", stat = "Minutes", target = 15, reward = { spins = 1 } },
			{ id = "spin", text = "Spin the wheel %s times", stat = "Spin", target = 2, reward = { boost = "Money2x", seconds = 600 } },
			{ id = "collect", text = "Collect cash %s times", stat = "Collect", target = 20, reward = { currency = "Money", incomeMinutes = 5 } },
			{ id = "rare", text = "Get %s Rare or better", stat = "RareFound", target = 3, reward = { boost = "Luck2x", seconds = 900 } },
			{ id = "upgrade", text = "Buy %s upgrades", stat = "Upgrade", target = 5, reward = { currency = "Gems", amount = 5 } },
		} :: { QuestDef },
		bonus = { currency = "Gems", amount = 25, spins = 1, label = "ALL QUESTS BONUS" } :: Reward,
	},

	-- Ruleta: una tirada gratis cada FREE_EVERY segundos (real) y tiradas extra de premios o productos.
	-- Si las tiradas se venden por Robux es aleatorio pago: las probabilidades se muestran chiquitas en
	-- cada casilla y ShopService la oculta a quien no puede usarla (PolicyService).
	SPIN = {
		FREE_EVERY = 4 * 3600,
		SEGMENTS = {
			{ id = "cash", weight = 35, label = "Cash", color = Color3.fromRGB(85, 230, 95), reward = { currency = "Money", incomeMinutes = 3 } },
			{ id = "gems", weight = 25, label = "10 Gems", color = Color3.fromRGB(80, 190, 255), reward = { currency = "Gems", amount = 10 } },
			{ id = "money2x", weight = 15, label = "2x Money", color = Color3.fromRGB(255, 200, 30), reward = { boost = "Money2x", seconds = 900 } },
			{ id = "luck2x", weight = 12, label = "2x Luck", color = Color3.fromRGB(120, 255, 120), reward = { boost = "Luck2x", seconds = 900 } },
			{ id = "bigcash", weight = 8, label = "BIG Cash", color = Color3.fromRGB(255, 120, 60), reward = { currency = "Money", incomeMinutes = 15 } },
			{ id = "jackpot", weight = 1, label = "JACKPOT", color = Color3.fromRGB(255, 70, 135), reward = { currency = "Gems", amount = 250, label = "JACKPOT" } },
			{ id = "spin", weight = 4, label = "+1 Spin", color = Color3.fromRGB(180, 95, 255), reward = { spins = 1 } },
		} :: { SpinSegment },
	},

	-- Códigos: publicarlos en la página del juego y en el grupo (nunca links a Discord dentro del juego).
	CODES = {
		RELEASE = { reward = { currency = "Gems", amount = 25, spins = 2 } :: Reward },
	} :: { [string]: { reward: Reward, expiresAt: number? } },

	-- Premio único por unirse al grupo (GameConfig.GROUP_ID), además del bono permanente de BoostConfig.
	GROUP_REWARD = { currency = "Gems", amount = 25, boost = "Luck2x", seconds = 1800, label = "Group gift" } :: Reward,

	-- Ganancias sin conexión: fracción del ingreso por segundo, con tope.
	OFFLINE = { rate = 0.5, capSeconds = 4 * 3600, minSeconds = 120 },

	-- Renacer: cuesta cada vez más y suma un multiplicador permanente de plata.
	REBIRTH = { currency = "Money", base = 50_000, growth = 3, perRebirth = 0.5, reward = { currency = "Gems", amount = 10 } :: Reward },

	-- Sistema oficial de referidos (Player:GetJoinData().ReferredByPlayerId): premio para los dos.
	REFERRAL = {
		invitee = { currency = "Gems", amount = 25, label = "Welcome gift" } :: Reward,
		inviter = { currency = "Gems", amount = 50, spins = 1, label = "Friend joined!" } :: Reward,
	},

	-- Recordatorios sin premio: pedir like/favorito y activar notificaciones (las reglas no dejan premiar
	-- el like ni bloquear el juego por las notificaciones).
	LIKE_REMINDER_AFTER = 15 * 60,
	NOTIFY_PROMPT_AFTER = 8 * 60,
}
