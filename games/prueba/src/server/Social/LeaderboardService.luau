--!strict
-- Tabla de jugadores de Roblox (leaderstats, arriba a la derecha) con GameConfig.LEADERSTATS: monedas
-- formateadas como en el HUD ("$1.2M"), renacimientos y estadísticas del armador ("Speed": el bloque
-- Stats las deja en un atributo del jugador con ese nombre). Mostrar cuánto tiene cada uno empuja a
-- competir y a comprar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local CurrencyService = require("../Economy/CurrencyService")
local DataService = require("../Data/DataService")

local LeaderboardService = {}

local function setCurrency(player: Player, id: string, balance: number)
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild(id)
	if value and value:IsA("StringValue") then
		local currency = EconomyConfig.CURRENCIES[id]
		value.Value = Format.money(balance, if currency then currency.symbol else "")
	end
end

local function build(player: Player)
	local data = DataService.get(player)
	if not data or player:FindFirstChild("leaderstats") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	for _, stat in GameConfig.LEADERSTATS do
		if EconomyConfig.CURRENCIES[stat] then
			local value = Instance.new("StringValue")
			value.Name = stat
			value.Parent = folder
		elseif stat == "Rebirths" then
			local value = Instance.new("IntValue")
			value.Name = stat
			value.Value = data.rebirths
			value.Parent = folder
		else
			local value = Instance.new("StringValue")
			value.Name = stat
			local function update()
				local current = player:GetAttribute(stat)
				value.Value = Format.number(if typeof(current) == "number" then current else 0)
			end
			update()
			player:GetAttributeChangedSignal(stat):Connect(update)
			value.Parent = folder
		end
	end
	folder.Parent = player
	for id in EconomyConfig.CURRENCIES do
		setCurrency(player, id, data.currencies[id] or 0)
	end
end

function LeaderboardService.start()
	DataService.StateChanged:Connect(function(player: Player, state: string)
		if state ~= "loading" then
			build(player)
		end
	end)
	CurrencyService.Changed:Connect(setCurrency)
	Players.PlayerAdded:Connect(function(player: Player)
		player:GetAttributeChangedSignal("Rebirths"):Connect(function()
			local stats = player:FindFirstChild("leaderstats")
			local value = stats and stats:FindFirstChild("Rebirths")
			local rebirths = player:GetAttribute("Rebirths")
			if value and value:IsA("IntValue") and typeof(rebirths) == "number" then
				value.Value = rebirths
			end
		end)
	end)
end

return LeaderboardService
