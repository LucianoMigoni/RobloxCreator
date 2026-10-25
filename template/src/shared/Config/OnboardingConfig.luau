--!strict
-- Embudo de onboarding: los pasos de los primeros minutos, en orden. El algoritmo de Home castiga el
-- rebote antes de 60 s: este embudo muestra en Creator Analytics en qué paso se van los jugadores.
-- source "server": lo confirma el servidor (puede saltear pasos de cliente que falten).
-- source "client": lo informa el cliente; solo cuenta si es exactamente el siguiente, y nunca da premio.

export type Step = { name: string, source: "server" | "client" }

return {
	STEPS = {
		{ name = "Joined", source = "server" },
		{ name = "OpenedShop", source = "client" },
		{ name = "BoughtFirstItem", source = "server" },
	} :: { Step },
	-- Monedas al completar el último paso, solo si ese paso es de servidor.
	COMPLETION_REWARD = 50,
	REPORT_RATE = { count = 3, perSeconds = 1 },
}
