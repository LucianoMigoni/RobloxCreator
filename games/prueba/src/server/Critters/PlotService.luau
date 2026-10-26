--!strict
-- Bases de los jugadores (M1 de docs/spec.md): una por jugador, en un anillo alrededor de la cinta.
-- Hito 1: la geometría son cubos grises armados por código; en el hito 6 la reemplaza el mapa real.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local PlotService = {}

local GREY = Color3.fromRGB(163, 162, 165)
local PAD_COLOR = Color3.fromRGB(91, 227, 60)
local FUSER_COLOR = Color3.fromRGB(150, 90, 230)

local plots: { Model } = {}
local owners: { [Model]: Player } = {}
local byPlayer: { [Player]: Model } = {}
local assigned = Instance.new("BindableEvent")
-- (player, plot) cuando un jugador recibe su base.
PlotService.Assigned = assigned.Event

local function part(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Pedestales en dos filas de cuatro (o las que hagan falta) en la mitad trasera de la base.
local function pedestalOffset(index: number): Vector3
	local column = (index - 1) % 4
	local row = (index - 1) // 4
	return Vector3.new(-9 + column * 6, 1, 5 + row * 6)
end

local function build(index: number, parent: Instance): Model
	local angle = (index - 1) / GameplayConfig.PLOTS * math.pi * 2
	local center = Vector3.new(math.cos(angle), 0, math.sin(angle)) * GameplayConfig.PLOT_RING_RADIUS
	-- -Z local mira a la cinta (el centro del mapa).
	local origin = CFrame.lookAt(center, Vector3.zero)
	local size = GameplayConfig.PLOT_SIZE

	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	local floor = part("Floor", Vector3.new(size, 0.5, size), origin * CFrame.new(0, 0.25, 0), GREY, plot)
	plot.PrimaryPart = floor
	for pedestal = 1, GameplayConfig.PEDESTALS do
		part("Pedestal" .. pedestal, Vector3.new(4, 2, 4), origin * CFrame.new(pedestalOffset(pedestal)), GREY, plot)
	end
	part("CollectPad", Vector3.new(6, 0.4, 6), origin * CFrame.new(-9, 0.7, -9), PAD_COLOR, plot)
	local fuser = part("Fuser", Vector3.new(5, 4, 5), origin * CFrame.new(9, 2.5, -9), FUSER_COLOR, plot)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Fuse"
	prompt.ObjectText = "Fuser"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = fuser

	local spawnPoint = Instance.new("Attachment")
	spawnPoint.Name = "Spawn"
	spawnPoint.CFrame = CFrame.new(0, 4, -11)
	spawnPoint.Parent = floor

	local critters = Instance.new("Folder")
	critters.Name = "Critters"
	critters.Parent = plot

	-- Al fondo de la base y chico: en el centro tapaba la vista del jugador hacia la cinta.
	local signPoint = Instance.new("Attachment")
	signPoint.Name = "SignPoint"
	signPoint.CFrame = CFrame.new(0, 8, size / 2 - 2)
	signPoint.Parent = floor
	local sign = Instance.new("BillboardGui")
	sign.Name = "Sign"
	sign.Size = UDim2.fromScale(10, 1.5)
	sign.MaxDistance = 150
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = "Free base"
	label.Parent = sign
	sign.Parent = signPoint

	plot.Parent = parent
	return plot
end

local function setSign(plot: Model, text: string)
	local floor = plot.PrimaryPart :: BasePart
	local sign = (floor:FindFirstChild("SignPoint") :: Attachment):FindFirstChild("Sign") :: BillboardGui
	(sign:FindFirstChildOfClass("TextLabel") :: TextLabel).Text = text
end

local function spawnAt(player: Player, character: Model)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	character:WaitForChild("HumanoidRootPart")
	local spawnPoint = (plot.PrimaryPart :: BasePart):FindFirstChild("Spawn") :: Attachment
	character:PivotTo(spawnPoint.WorldCFrame)
end

local function onPlayerAdded(player: Player)
	for _, plot in plots do
		if not owners[plot] then
			owners[plot] = player
			byPlayer[player] = plot
			plot:SetAttribute("OwnerUserId", player.UserId)
			setSign(plot, player.DisplayName .. "'s base")
			player.CharacterAdded:Connect(function(character)
				spawnAt(player, character)
			end)
			if player.Character then
				task.spawn(spawnAt, player, player.Character)
			end
			assigned:Fire(player, plot)
			return
		end
	end
	-- Más jugadores que bases: Game Settings → Max Players debe ser GameplayConfig.PLOTS.
	warn(string.format("[PlotService] no hay base libre para %s", player.Name))
end

local function onPlayerRemoving(player: Player)
	local plot = byPlayer[player]
	if not plot then
		return
	end
	byPlayer[player] = nil
	owners[plot] = nil
	plot:SetAttribute("OwnerUserId", nil)
	setSign(plot, "Free base")
	local critters = plot:FindFirstChild("Critters") :: Folder
	critters:ClearAllChildren()
end

function PlotService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = workspace
	for index = 1, GameplayConfig.PLOTS do
		table.insert(plots, build(index, folder))
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

function PlotService.get(player: Player): Model?
	return byPlayer[player]
end

function PlotService.owner(plot: Model): Player?
	return owners[plot]
end

-- Parte del pedestal `index` de una base.
function PlotService.pedestal(plot: Model, index: number): BasePart?
	return plot:FindFirstChild("Pedestal" .. index) :: BasePart?
end

-- La base que contiene una parte (pedestal, pad, fusionador).
function PlotService.plotOf(inst: Instance): Model?
	local node: Instance? = inst
	while node and node.Parent and node.Parent.Name ~= "Plots" do
		node = node.Parent
	end
	return if node and node.Parent and node:IsA("Model") then node else nil
end

return PlotService
