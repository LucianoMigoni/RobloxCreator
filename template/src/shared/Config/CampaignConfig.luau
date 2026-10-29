--!strict
-- Premio de bienvenida para quien entra por una campaña (Ads Manager → Advanced options → launch data),
-- un share link o una captura compartida (CampaignService). Roblox recomienda un premio exclusivo para
-- los que llegan por anuncio porque sube la conversión. Cada código premia una sola vez por jugador.
-- Premios chicos y nunca aleatorios. Los códigos de cada campaña salen de tools/campaigns.py (ad_<etapa>).

local Types = require("../Types")

type Reward = Types.Reward

return {
	-- Código exacto → premio.
	CODES = {} :: { [string]: Reward },
	-- Prefijo → premio, para no listar cada campaña ("ad_humo", "ad_empuje"... usan "ad_").
	PREFIXES = {
		ad_ = { boost = "Money2x", seconds = 900, label = "WELCOME GIFT!" },
		tiktok_ = { boost = "Money2x", seconds = 900, label = "WELCOME GIFT!" },
		yt_ = { boost = "Money2x", seconds = 900, label = "WELCOME GIFT!" },
		share_ = { boost = "Luck2x", seconds = 600, label = "FRIEND GIFT!" },
	} :: { [string]: Reward },
	-- LaunchData que va en el link al compartir una captura (CaptureService:PromptShareCapture).
	SHARE_LAUNCH_DATA = "share_capture",
	-- LaunchData más largo que esto se ignora (lo puede escribir cualquiera en la URL).
	MAX_LENGTH = 64,
}
