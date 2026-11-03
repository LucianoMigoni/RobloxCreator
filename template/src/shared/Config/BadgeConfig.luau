--!strict
-- Insignias de Roblox (Badges) que se ganan solas jugando (server/Social/Badges.luau). Cada una se crea
-- en el Creator Dashboard (Monetization → Badges; 5 gratis cada 24 h, después 100 Robux cada una) con
-- su nombre, su descripción y su imagen de assets/ui/badge-art, y su id va en `badgeId`. Con 0 (sin
-- crear) se saltea. Nombres y descripciones en inglés: son los del Dashboard.
--
-- Reglas (`rule`):
-- - "join": entrar por primera vez.
-- - "signal": la primera vez que pasa esa señal (`stat` de Signals.track: "RareFound", "SecretFound").
-- - "rebirths", "index", "streak", "playtime": llegar a `value` (renacimientos, descubiertos en el
--   índice, días seguidos del regalo diario, segundos jugados en el día). Se revisan también al entrar.
-- - "friend": jugar en el mismo servidor que un amigo.
-- - "dev": estar en un servidor con el creador del juego (GameConfig.DEV_USER_IDS o el dueño).

export type Rule = "join" | "signal" | "rebirths" | "index" | "streak" | "playtime" | "friend" | "dev"

export type Badge = {
	key: string, -- se guarda en los datos: no cambiarlo después de publicar
	badgeId: number,
	name: string,
	desc: string,
	image: string, -- archivo de assets/ui/badge-art (sin .png)
	rule: Rule,
	stat: string?,
	value: number?,
}

return {
	LIST = {
		{ key = "Welcome", badgeId = 0, name = "Welcome!", desc = "Join the game for the first time.", image = "welcome", rule = "join" },
		{ key = "FirstRare", badgeId = 0, name = "Lucky Find", desc = "Get your first Rare or better.", image = "first_rare", rule = "signal", stat = "RareFound" },
		{ key = "Secret", badgeId = 0, name = "Secret Hunter", desc = "Find a Secret!", image = "secret", rule = "signal", stat = "SecretFound" },
		{ key = "Rebirth", badgeId = 0, name = "Reborn", desc = "Rebirth for the first time.", image = "rebirth", rule = "rebirths", value = 1 },
		{ key = "Collector", badgeId = 0, name = "Collector", desc = "Discover 25 in the Index.", image = "collector", rule = "index", value = 25 },
		{ key = "Streak", badgeId = 0, name = "Loyal Player", desc = "Claim the daily reward 7 days in a row.", image = "streak", rule = "streak", value = 7 },
		{ key = "PlayHour", badgeId = 0, name = "Dedicated", desc = "Play for 1 hour in one day.", image = "playtime", rule = "playtime", value = 3600 },
		{ key = "Friends", badgeId = 0, name = "Better Together", desc = "Play in the same server as a friend.", image = "friends", rule = "friend" },
		{ key = "MetDev", badgeId = 0, name = "Met the Dev", desc = "Be in a server with the game's creator.", image = "met_dev", rule = "dev" },
	} :: { Badge },
	-- Cada cuánto se revisan las reglas "friend" y "dev" (segundos).
	CHECK_SECONDS = 20,
}
