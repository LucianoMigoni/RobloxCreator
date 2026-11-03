--!strict
-- Sonidos de la UI y música, por nombre de evento (Config/AudioConfig). Usa nuestro efecto si ya está
-- subido (AssetIds.sounds) y si no, el de la biblioteca de Roblox. Cada sonido tiene una instancia
-- reutilizable por nombre (varias copias para los que se pisan, como las monedas). La música rota una
-- lista por ambiente con fundido. Volúmenes de efectos y música por separado (Ajustes).

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AssetIds = require(ReplicatedStorage.Shared.Config.AssetIds)
local AudioConfig = require(ReplicatedStorage.Shared.Config.AudioConfig)

local Sound = {}

local COPIES = 4 -- cuántas veces puede sonar el mismo efecto a la vez
local FADE = TweenInfo.new(1.2, Enum.EasingStyle.Sine)

local folder = Instance.new("Folder")
folder.Name = "GameSounds"
folder.Parent = SoundService

local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "SFX"
sfxGroup.Volume = 1
sfxGroup.Parent = SoundService

local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "Music"
musicGroup.Volume = 1
musicGroup.Parent = SoundService

local pools: { [string]: { Sound } } = {}
local nextCopy: { [string]: number } = {}
local lastPlayed: { [string]: number } = {}
local random = Random.new()

local function resolve(name: string): (string?, AudioConfig.Sound?)
	local def = AudioConfig.SOUNDS[name]
	if not def then
		return nil, nil
	end
	local own = def.asset and AssetIds.sounds[def.asset]
	return if own and own ~= "" then own else def.id, def
end

local function pool(name: string): { Sound }?
	local existing = pools[name]
	if existing then
		return existing
	end
	local id, def = resolve(name)
	if not id or not def then
		return nil
	end
	local list = {}
	for i = 1, COPIES do
		local s = Instance.new("Sound")
		s.Name = name .. i
		s.SoundId = id
		s.Volume = def.volume or 0.5
		s.SoundGroup = sfxGroup
		s.Parent = folder
		table.insert(list, s)
	end
	pools[name] = list
	nextCopy[name] = 1
	return list
end

-- Reproduce un efecto. `pitch` fija la velocidad (1 = normal); si no, se varía al azar si el sonido
-- lo pide. Los nombres desconocidos no hacen nada (un kit puede pedir uno que el juego no definió).
function Sound.play(name: string, pitch: number?)
	local def = AudioConfig.SOUNDS[name]
	if not def then
		return
	end
	local now = os.clock()
	if def.cooldown and now - (lastPlayed[name] or 0) < def.cooldown then
		return
	end
	lastPlayed[name] = now
	local list = pool(name)
	if not list then
		return
	end
	local index = nextCopy[name]
	nextCopy[name] = index % #list + 1
	local s = list[index]
	local range = def.pitch
	s.PlaybackSpeed = pitch or (if range then random:NextNumber(range[1], range[2]) else 1)
	s.TimePosition = 0
	s:Play()
end

-- Anuncio con voz ("LEGENDARY!"): solo si la voz ya está subida.
function Sound.voice(moment: string)
	local key = AudioConfig.VOICES[moment]
	if not key then
		return
	end
	local id = AssetIds.voices[AudioConfig.VOICE_STYLE .. "_" .. key]
	if not id or id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = AudioConfig.VOICE_VOLUME
	s.SoundGroup = sfxGroup
	s.Parent = folder
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(8, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

-- Música ------------------------------------------------------------------------------------------

local musicToken = 0
local current: Sound? = nil

local function fadeOut(s: Sound)
	local tween = TweenService:Create(s, FADE, { Volume = 0 })
	tween.Completed:Once(function()
		s:Destroy()
	end)
	tween:Play()
end

-- Rota la lista del ambiente ("Lobby", "Halloween"...) hasta que se pida otra o se pare.
function Sound.playMusic(mood: string)
	local list = AudioConfig.MUSIC[mood]
	if not list or #list == 0 then
		return
	end
	musicToken += 1
	local token = musicToken
	if current then
		fadeOut(current)
		current = nil
	end
	task.spawn(function()
		local order = table.clone(list)
		-- Mezcla para que cada jugador no escuche siempre el mismo tema primero.
		for i = #order, 2, -1 do
			local j = random:NextInteger(1, i)
			order[i], order[j] = order[j], order[i]
		end
		local i = 1
		while token == musicToken do
			local s = Instance.new("Sound")
			s.Name = "Music"
			s.SoundId = order[i]
			s.Volume = 0
			s.SoundGroup = musicGroup
			s.Parent = folder
			current = s
			s:Play()
			TweenService:Create(s, FADE, { Volume = AudioConfig.MUSIC_VOLUME }):Play()
			local started = os.clock()
			while not s.IsLoaded and token == musicToken and os.clock() - started < 10 do
				task.wait(0.25)
			end
			local length = s.TimeLength
			local waited = 0
			-- Sale antes si cambió el ambiente; si el tema no carga, pasa al siguiente.
			while token == musicToken and waited < math.max(length - 1.5, 5) and s.Parent do
				task.wait(0.5)
				waited += 0.5
			end
			if s.Parent then
				fadeOut(s)
			end
			i = i % #order + 1
		end
	end)
end

function Sound.stopMusic()
	musicToken += 1
	if current then
		fadeOut(current)
		current = nil
	end
end

-- 0 a 1 cada uno (Ajustes).
function Sound.setVolumes(sfx: number, music: number)
	sfxGroup.Volume = math.clamp(sfx, 0, 1)
	musicGroup.Volume = math.clamp(music, 0, 1)
end

-- Carga los efectos más usados antes de que hagan falta (sin bloquear el arranque).
function Sound.preload(names: { string })
	task.spawn(function()
		local list = {}
		for _, name in names do
			local sounds = pool(name)
			if sounds then
				for _, s in sounds do
					table.insert(list, s)
				end
			end
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, list)
	end)
end

return Sound
