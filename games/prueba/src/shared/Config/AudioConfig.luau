--!strict
-- Sonidos y música del juego, por evento. Cada sonido usa el nuestro (`asset`, nombre en
-- AssetIds.sounds: la toma elegida de assets/audio/hit-sfx) cuando ya está subido, y si no, uno de la
-- biblioteca pública de Roblox (`id`, assets/audio/roblox-library), que se puede usar en cualquier
-- experiencia. Así el juego suena desde el primer playtest.
-- Los anuncios con voz (`VOICES`) salen de AssetIds.voices: sin subir, no suenan (el efecto alcanza).
-- La música es de la biblioteca con licencia de Roblox (assets/audio/roblox-music, APM y DistroKid).

export type Sound = {
	id: string, -- respaldo de la biblioteca de Roblox
	asset: string?, -- nombre en AssetIds.sounds
	volume: number?,
	pitch: { number }?, -- { mínimo, máximo }: variación al azar para que no canse
	cooldown: number?, -- segundos mínimos entre dos reproducciones (monedas seguidas)
}

local function lib(id: number): string
	return "rbxassetid://" .. id
end

return {
	SOUNDS = {
		Click = { id = lib(15675059323), asset = "button_pop_A", volume = 0.5, pitch = { 0.95, 1.08 } },
		Open = { id = lib(15675055424), volume = 0.45 },
		Close = { id = lib(10066914500), volume = 0.4 },
		Tab = { id = lib(17208408337), volume = 0.4 },
		Coin = { id = lib(127645268874265), asset = "coin_pickup_A", volume = 0.45, pitch = { 0.92, 1.12 }, cooldown = 0.05 },
		Cash = { id = lib(17208380755), asset = "cash_register_A", volume = 0.55 },
		CoinsBurst = { id = lib(127645268874265), asset = "coins_burst_A", volume = 0.6 },
		Purchase = { id = lib(17208380755), asset = "purchase_success_A", volume = 0.6 },
		Reward = { id = lib(17208361335), asset = "purchase_success_A", volume = 0.6 },
		LevelUp = { id = lib(15675043410), asset = "level_up_A", volume = 0.6 },
		Victory = { id = lib(12222253), asset = "level_up_A", volume = 0.6 },
		Riser = { id = lib(17208327798), asset = "rare_reveal_A", volume = 0.6 },
		Reveal = { id = lib(17208327798), asset = "rare_reveal_A", volume = 0.65 },
		Legendary = { id = lib(15675043410), asset = "legendary_reveal_A", volume = 0.75 },
		EggCrack = { id = lib(17208204604), asset = "egg_crack_A", volume = 0.6 },
		SpinTick = { id = lib(15675032796), volume = 0.3, cooldown = 0.03 },
		SpinStart = { id = lib(15675024286), asset = "spin_wheel_A", volume = 0.5 },
		Rebirth = { id = lib(15675024286), asset = "rebirth_whoosh_A", volume = 0.7 },
		Error = { id = lib(17208353912), asset = "error_buzz_A", volume = 0.5 },
		Notify = { id = lib(17208361335), volume = 0.5 },
		Whoosh = { id = lib(15675028888), volume = 0.4 },
		Equip = { id = lib(17208323435), volume = 0.5 },
		Pickup = { id = lib(17208319162), volume = 0.5, pitch = { 0.95, 1.1 }, cooldown = 0.05 },
		Hover = { id = lib(10066931761), volume = 0.25 },
	} :: { [string]: Sound },

	-- Anuncio con voz por momento (nombre en AssetIds.voices). "deep_" o "cartoon_": la voz elegida.
	VOICE_STYLE = "deep",
	VOICES = {
		Legendary = "legendary",
		Mythic = "mythic",
		Secret = "secret",
		Epic = "epic",
		Rebirth = "rebirth",
		LevelUp = "level_up",
		DoubleMoney = "double_money",
		Jackpot = "jackpot",
		NewRecord = "new_record",
		Lucky = "so_lucky",
	} :: { [string]: string },
	VOICE_VOLUME = 0.8,

	-- Música por ambiente: el juego elige con Sound.playMusic("Lobby"). Volumen bajo: no tapa los efectos.
	MUSIC_VOLUME = 0.25,
	MUSIC = {
		Lobby = { lib(80257380636383), lib(140228184971194), lib(71612604315412), lib(104439502290763), lib(100892436157886) },
		Happy = { lib(131911681104322), lib(105386431475048), lib(93478033976110) },
		Halloween = { lib(1836009584), lib(89785992214997), lib(125675395753612) },
		Winter = { lib(140596895991475), lib(100764064159201) },
		Summer = { lib(140522140523060), lib(81431480827880) },
		Boss = { lib(139732156978834), lib(132746955787604) },
		Underwater = { lib(109259675282369) },
		Space = { lib(85922328966318), lib(136898642923218) },
	} :: { [string]: { string } },
}
