--!strict
-- Ajustes del jugador (música, efectos, gráficos bajos): se guardan con sus datos para que valgan en
-- cualquier dispositivo. El cliente los aplica; el servidor solo los guarda.

local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local Signals = require("../Signals")

local SettingsService = {}

local function save(player: Player, music: boolean, sfx: boolean, lowGraphics: boolean): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	data.settings.music = music
	data.settings.sfx = sfx
	data.settings.lowGraphics = lowGraphics
	Signals.dirty(player)
	return true
end

function SettingsService.start()
	Remotes.onInvoke("SaveSettings", {
		args = { Validate.boolean(), Validate.boolean(), Validate.boolean() },
		rate = { count = 4, perSeconds = 2 },
	}, save)
end

return SettingsService
