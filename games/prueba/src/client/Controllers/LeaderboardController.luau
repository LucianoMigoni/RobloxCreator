--!strict
-- Tablas de posiciones del mundo (etiqueta KitLeaderboard): dibuja en la cara "Face" de la parte
-- "Board" del modelo (o de su parte principal) la lista que deja el servidor en el atributo "Top"
-- (Social/GlobalLeaderboardService): medalla de los tres primeros, foto, nombre y valor con el formato
-- del HUD. La fila propia se resalta. Todo es local y solo muestra.

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Shared.Config.EconomyConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local Format = require(ReplicatedStorage.Shared.Lib.Format)
local UIKit = require(ReplicatedStorage.Shared.UIKit)

local LeaderboardController = {}

local PIXELS_PER_STUD = 50
local ROWS = 10
local MAX_DISTANCE = 220
local MEDALS: { UIKit.Variant } = { "Premium", "Light", "Orange" } -- oro, plata, bronce

type Row = { id: number, name: string, value: number }

local player = Players.LocalPlayer
local guis: { [Instance]: SurfaceGui } = {}
local watched: { [Instance]: boolean } = {}

local function boardPart(model: Instance): BasePart?
	if model:IsA("BasePart") then
		return model
	end
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") and child:GetAttribute("Face") ~= nil then
			return child
		end
	end
	if model:IsA("Model") then
		return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function faceOf(part: BasePart): Enum.NormalId
	local face = part:GetAttribute("Face")
	if typeof(face) == "string" then
		local ok, value = pcall(function(): Enum.NormalId
			return (Enum.NormalId :: any)[face]
		end)
		if ok and value then
			return value
		end
	end
	return Enum.NormalId.Front
end

local function format(stat: string, value: number): string
	local currency = EconomyConfig.CURRENCIES[stat]
	if currency then
		return Format.money(value, currency.symbol)
	end
	return Format.number(value)
end

local function decode(model: Instance): { Row }
	local raw = model:GetAttribute("Top")
	if typeof(raw) ~= "string" then
		return {}
	end
	local ok, rows = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or typeof(rows) ~= "table" then
		return {}
	end
	local out: { Row } = {}
	for _, row in rows :: { any } do
		if typeof(row) == "table" and typeof(row.id) == "number" and typeof(row.name) == "string" and typeof(row.value) == "number" then
			table.insert(out, { id = row.id, name = row.name, value = row.value })
		end
	end
	return out
end

-- Arma el cartel (una vez) y devuelve la lista donde van las filas.
local function build(model: Instance, part: BasePart, stat: string): Frame
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TopBoard_" .. stat
	gui.Adornee = part
	gui.Face = faceOf(part)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	guis[model] = gui
	local back = UIKit.new("Frame", { Name = "Back", Size = UDim2.fromScale(1, 1) }, gui) :: Frame
	UIKit.style(back, "Panel", 0.04, 0.012)
	-- Encabezado dorado con trofeo.
	local header = UIKit.new("Frame", { Name = "Header", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.025), Size = UDim2.fromScale(0.94, 0.13), ZIndex = 2 }, back) :: Frame
	UIKit.style(header, "Premium", 0.3, 0.03)
	local currency = EconomyConfig.CURRENCIES[stat]
	UIKit.icon(header, if currency then currency.icon else "trophy", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.09, 0.45), Size = UDim2.fromScale(1.25, 1.25), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 4 })
	UIKit.label(header, "Title", string.format(UiText.TOP_BOARD, string.upper(stat)), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.56, 0.48), Size = UDim2.fromScale(0.8, 0.74), ZIndex = 4 }, 120, UIKit.TitleFont)
	local list = UIKit.new("Frame", { Name = "List", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromScale(0.92, 0.74), ZIndex = 2 }, back) :: Frame
	UIKit.new("UIListLayout", { Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	UIKit.label(back, "Footer", UiText.TOP_BOARD_UPDATES, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.985), Size = UDim2.fromScale(0.8, 0.045), ZIndex = 2 }, 40)
	return list
end

local function row(list: Frame, rank: number, entry: Row?, stat: string)
	local mine = entry ~= nil and entry.id == player.UserId
	local frame = UIKit.new("Frame", { Name = "Row" .. rank, LayoutOrder = rank, Size = UDim2.fromScale(1, 0.088), ZIndex = 3 }, list) :: Frame
	UIKit.style(frame, if mine then "Info" else "Dark", 0.25, 0.02)
	-- Puesto: medalla para los tres primeros.
	local badge = UIKit.new("Frame", { Name = "Rank", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.015, 0.5), Size = UDim2.fromScale(0.8, 0.8), SizeConstraint = Enum.SizeConstraint.RelativeYY, ZIndex = 4 }, frame) :: Frame
	UIKit.style(badge, MEDALS[rank] or "Neutral", 0.5, 0.06)
	UIKit.label(badge, "Number", tostring(rank), { Size = UDim2.fromScale(1, 1), ZIndex = 5 }, 60, UIKit.TitleFont)
	if not entry then
		UIKit.label(frame, "Name", if rank == 1 then UiText.TOP_BOARD_EMPTY else "-", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.13, 0.5), Size = UDim2.fromScale(0.6, 0.62), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }, 54)
		return
	end
	UIKit.new("ImageLabel", {
		Name = "Avatar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.12, 0.5),
		Size = UDim2.fromScale(0.86, 0.86),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		-- Foto de la cabeza sin pedirla aparte (formato rbxthumb, verificado en creator-docs: projects/assets).
		Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", entry.id),
		ZIndex = 4,
	}, frame)
	local name = UIKit.label(frame, "Name", entry.name, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.215, 0.5), Size = UDim2.fromScale(0.44, 0.6), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 }, 54)
	name.AutoLocalize = false -- los nombres de usuario no se traducen
	local value = UIKit.label(frame, "Value", format(stat, entry.value), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.975, 0.5), Size = UDim2.fromScale(0.32, 0.62), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 4 }, 54)
	value.TextColor3 = if EconomyConfig.CURRENCIES[stat] then Color3.fromRGB(120, 255, 120) else Color3.fromRGB(255, 226, 92)
end

local function draw(model: Instance)
	local stat = model:GetAttribute("Stat")
	local part = boardPart(model)
	if typeof(stat) ~= "string" or not part then
		return
	end
	local gui = guis[model]
	local list = if gui then gui:FindFirstChild("List", true) :: Frame? else nil
	if not list then
		list = build(model, part, stat)
	end
	local frame = list :: Frame
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local rows = decode(model)
	for rank = 1, ROWS do
		row(frame, rank, rows[rank], stat)
	end
end

local function add(model: Instance)
	if watched[model] then
		return
	end
	watched[model] = true
	draw(model)
	model:GetAttributeChangedSignal("Top"):Connect(function()
		draw(model)
	end)
end

function LeaderboardController.start()
	for _, model in CollectionService:GetTagged(Tags.LEADERBOARD) do
		task.spawn(add, model)
	end
	CollectionService:GetInstanceAddedSignal(Tags.LEADERBOARD):Connect(add)
	CollectionService:GetInstanceRemovedSignal(Tags.LEADERBOARD):Connect(function(model: Instance)
		local gui = guis[model]
		if gui then
			gui:Destroy()
			guis[model] = nil
		end
		watched[model] = nil
	end)
end

return LeaderboardController
