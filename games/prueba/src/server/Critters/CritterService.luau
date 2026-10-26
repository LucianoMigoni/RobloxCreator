--!strict
-- Critters del jugador (M3–M6 de docs/spec.md): colocarlos en pedestales, el ingreso por segundo que
-- se acumula en cada pedestal, juntarlo en el collect pad y fusionar pares en el fusionador.
-- Todo lo decide el servidor: el pad responde a Touched y el fusionador a su ProximityPrompt.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("../Data/DataService")
local CurrencyService = require("../Economy/CurrencyService")
local OnboardingService = require("../Onboarding/OnboardingService")
local PlayerStateService = require("../PlayerStateService")
local CritterRules = require("./CritterRules")
local CritterVisual = require("./CritterVisual")
local PlotService = require("./PlotService")

local CritterService = {}

local INCOME_BY_TIER = {}
for _, tier in GameplayConfig.TIERS do
	table.insert(INCOME_BY_TIER, tier.income)
end

-- Monedas acumuladas en cada pedestal, hasta que el dueño pisa el pad. Solo en memoria.
local pending: { [Player]: { [number]: number } } = {}
local displays: { [Player]: { [string]: Model } } = {}

local function multiplier(_player: Player): number
	return 1 -- renacer y pases se suman en los hitos 3 y 5
end

local function show(player: Player, critter: Types.Critter)
	local plot = PlotService.get(player)
	local pedestal = plot and PlotService.pedestal(plot, critter.pedestal)
	if not plot or not pedestal then
		return
	end
	local model = CritterVisual.build(critter.tier, critter.mutation)
	model:PivotTo(pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2 + model:GetExtentsSize().Y / 2, 0))
	model.Parent = plot:FindFirstChild("Critters")
	displays[player][critter.uid] = model
end

local function hide(player: Player, uid: string)
	local model = displays[player][uid]
	if model then
		model:Destroy()
		displays[player][uid] = nil
	end
end

-- Agrega un critter en el primer pedestal libre. false si no hay lugar o los datos no cargaron.
function CritterService.add(player: Player, tier: number, mutation: string): boolean
	local data = DataService.get(player)
	if not data or not displays[player] then
		return false
	end
	local pedestal = CritterRules.freePedestal(data.critters, GameplayConfig.PEDESTALS)
	if not pedestal then
		return false
	end
	local critter: Types.Critter = { uid = HttpService:GenerateGUID(false), tier = tier, mutation = mutation, pedestal = pedestal }
	table.insert(data.critters, critter)
	show(player, critter)
	PlayerStateService.push(player)
	return true
end

function CritterService.hasFreePedestal(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and CritterRules.freePedestal(data.critters, GameplayConfig.PEDESTALS) ~= nil
end

-- Compra en la cinta: cobra y coloca. El precio sale de la configuración, nunca del cliente.
function CritterService.buy(player: Player, tier: number): boolean
	local price = GameplayConfig.TIERS[tier].price
	if not price or not CritterService.hasFreePedestal(player) then
		return false
	end
	if not CurrencyService.spend(player, price, Enum.AnalyticsEconomyTransactionType.Shop, "Conveyor") then
		return false
	end
	CritterService.add(player, tier, "Normal")
	OnboardingService.complete(player, "BoughtFirstCritter")
	return true
end

local function collect(player: Player)
	local owed = 0
	for pedestal, amount in pending[player] do
		owed += amount
		pending[player][pedestal] = 0
	end
	owed = math.floor(owed)
	if owed > 0 and CurrencyService.add(player, owed, Enum.AnalyticsEconomyTransactionType.Gameplay, "Collect") then
		OnboardingService.complete(player, "CollectedCoins")
	end
end

local function fuse(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local i, j = CritterRules.pickFusePair(data.critters, #GameplayConfig.TIERS)
	if not i or not j then
		return
	end
	local a, b = data.critters[i], data.critters[j]
	-- Las monedas sin juntar de los dos pedestales pasan al del resultado: no se pierden.
	local carried = (pending[player][a.pedestal] or 0) + (pending[player][b.pedestal] or 0)
	pending[player][a.pedestal], pending[player][b.pedestal] = 0, 0
	hide(player, a.uid)
	hide(player, b.uid)
	table.remove(data.critters, math.max(i, j))
	table.remove(data.critters, math.min(i, j))
	local result: Types.Critter = { uid = HttpService:GenerateGUID(false), tier = a.tier + 1, mutation = "Normal", pedestal = a.pedestal }
	table.insert(data.critters, result)
	pending[player][result.pedestal] = carried
	show(player, result)
	PlayerStateService.push(player)
	OnboardingService.complete(player, "FirstFuse")
end

local function tick()
	for player, perPedestal in pending do
		local data = DataService.get(player)
		local plot = PlotService.get(player)
		if not data or not plot then
			continue
		end
		for _, critter in data.critters do
			local income = CritterRules.income(INCOME_BY_TIER, GameplayConfig.MUTATIONS, critter, multiplier(player)) or 0
			local amount = (perPedestal[critter.pedestal] or 0) + income * GameplayConfig.INCOME_TICK_SECONDS
			perPedestal[critter.pedestal] = amount
			local model = displays[player][critter.uid]
			if model then
				CritterVisual.setInfo(model, math.floor(amount) .. " coins")
			end
		end
	end
end

local hooked: { [Model]: boolean } = {}

-- El pad y el fusionador de una base se conectan una vez y atienden solo al dueño de turno.
local function hook(plot: Model)
	hooked[plot] = true
	local pad = plot:FindFirstChild("CollectPad") :: BasePart
	pad.Touched:Connect(function(hit: BasePart)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and PlotService.get(player) == plot and pending[player] then
			collect(player)
		end
	end)
	local prompt = (plot:FindFirstChild("Fuser") :: BasePart):FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	prompt.Triggered:Connect(function(player: Player)
		if PlotService.get(player) == plot and pending[player] then
			fuse(player)
		end
	end)
end

local function onAssigned(player: Player, plot: Model)
	if not hooked[plot] then
		hook(plot)
	end
	pending[player] = {}
	displays[player] = {}
	local data = DataService.waitForData(player)
	if not data or PlotService.get(player) ~= plot then
		return
	end
	for _, critter in data.critters do
		show(player, critter)
	end
end

-- Llamar antes de PlotService.start(), para no perderse las primeras bases asignadas.
function CritterService.start()
	PlotService.Assigned:Connect(onAssigned)
	Players.PlayerRemoving:Connect(function(player: Player)
		-- shortcut: lo no juntado se pierde al salir; las ganancias sin conexión llegan en el hito 3.
		pending[player] = nil
		displays[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(GameplayConfig.INCOME_TICK_SECONDS)
			tick()
		end
	end)
end

return CritterService
