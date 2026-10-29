--!strict
-- Multiplicadores permanentes y temporales (BoostService). Los pases y productos que dan impulsos
-- están en ShopConfig; acá, los bonos gratis y la definición de cada impulso con tiempo.
-- Estadísticas típicas: "Money", "Luck", "Speed", "Wins", "Gems".

export type Timed = {
	stat: string,
	value: number, -- multiplicador: 2 = x2
	label: string, -- se ve en el HUD: "2x Money"
	icon: string, -- nombre de ícono (shared/Icons)
}

return {
	-- Bono por cada amigo en el servidor ("Friend Boost +10%"), con tope.
	FRIENDS = { stat = "Money", perFriend = 0.1, max = 0.5, label = "Friends" },
	-- Bono permanente por estar en el grupo del juego (GameConfig.GROUP_ID).
	GROUP = { stat = "Money", value = 0.1, label = "Group" },
	-- Bono para quien tiene la suscripción de Roblox (Player.HasRobloxSubscription).
	SUBSCRIPTION = { stat = "Money", value = 0.1, label = "Premium" },

	-- Impulsos con tiempo: los dan productos, la ruleta, regalos y anuncios. Se acumula el tiempo.
	TIMED = {
		Money2x = { stat = "Money", value = 2, label = "2x Money", icon = "money_boost" },
		Luck2x = { stat = "Luck", value = 2, label = "2x Luck", icon = "luck" },
		Speed2x = { stat = "Speed", value = 2, label = "2x Speed", icon = "speed" },
		Wins2x = { stat = "Wins", value = 2, label = "2x Wins", icon = "trophy" },
	} :: { [string]: Timed },

	-- Impulsos para todo el servidor ("Server Luck x2", 15 min): los compra un jugador y gana todos.
	SERVER = {
		ServerLuck2x = { stat = "Luck", value = 2, label = "Server Luck", icon = "luck" },
		ServerMoney2x = { stat = "Money", value = 2, label = "Server Money", icon = "money_boost" },
		ServerSpeed2x = { stat = "Speed", value = 2, label = "Server Speed", icon = "speed" },
	} :: { [string]: Timed },
}
