--!strict
-- Mascotas que siguen a su dueño (bloque Equip con `follow`): cada cliente dibuja las de todos los
-- jugadores a partir del atributo "Equipped" que publica el servidor ("Dragon|Gold|Huge;Kitty||").
-- Flotan en abanico detrás del jugador, con un rebote suave, y se acomodan con suavidad. Son locales y
-- sin choque: no pesan en el servidor. Con gráficos bajos (Bus "LowGraphics") solo se dibujan las
-- propias, y las de jugadores lejos de la cámara no se mueven.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local Bus = require("../Bus")
local HudController = require("../Controllers/HudController")
local KitUi = require("./KitUi")

type Follower = { model: Model, height: number, index: number }

local Followers = {}

local SPREAD = math.rad(110) -- ancho del abanico detrás del jugador
local DISTANCE = 5 -- studs detrás del jugador
local ROW_GAP = 3.5 -- con muchas, una segunda fila más atrás
local PER_ROW = 4
local BOB_HEIGHT = 0.35
local BOB_SPEED = 3
local FOLLOW_SPEED = 9 -- más alto = se acomodan más rápido
local FAR = 160 -- studs: más lejos de la cámara no se actualizan

local localPlayer = Players.LocalPlayer
local folder: Folder? = nil
local byPlayer: { [Player]: { Follower } } = {}
local lowGraphics = false

local function container(): Folder
	local existing = folder
	if existing and existing.Parent then
		return existing
	end
	local made = Instance.new("Folder")
	made.Name = "KitFollowers"
	made.Parent = Workspace
	folder = made
	return made
end

local function clear(player: Player)
	local list = byPlayer[player]
	if list then
		for _, follower in list do
			follower.model:Destroy()
		end
	end
	byPlayer[player] = nil
end

local function nonEmpty(text: string?): string?
	return if text and text ~= "" then text else nil
end

local function rebuild(player: Player)
	clear(player)
	if lowGraphics and player ~= localPlayer then
		return
	end
	local value = player:GetAttribute("Equipped")
	if typeof(value) ~= "string" or value == "" then
		return
	end
	local equip = KitConfig.equip
	local max = if equip then equip.maxSlots else 0
	local list: { Follower } = {}
	for i, entry in string.split(value, ";") do
		if i > max then
			break
		end
		local parts = string.split(entry, "|")
		local kind = parts[1]
		local def = if kind then KitUi.unitDef(kind) else nil
		if def and kind then
			local model = UnitModel.make(def, { kind = kind, variant = nonEmpty(parts[2]), size = nonEmpty(parts[3]) })
			-- Sin cartel: el nombre ya está en el inventario.
			model:RemoveTag(UnitModel.TAG)
			model.Name = player.Name .. "_" .. kind
			local _, size = model:GetBoundingBox()
			model.Parent = container()
			table.insert(list, { model = model, height = size.Y, index = i })
		end
	end
	byPlayer[player] = list
end

-- Dónde va la mascota `index` de `count` detrás de `root`.
local function target(root: BasePart, follower: Follower, count: number, now: number): CFrame
	local row = (follower.index - 1) // PER_ROW
	local inRow = math.min(count - row * PER_ROW, PER_ROW)
	local slot = (follower.index - 1) % PER_ROW
	local angle = if inRow > 1 then -SPREAD / 2 + SPREAD * slot / (inRow - 1) else 0
	local distance = DISTANCE + row * ROW_GAP
	local offset = Vector3.new(math.sin(angle) * distance, 0, math.cos(angle) * distance)
	local base = root.CFrame * CFrame.new(offset)
	local bob = math.sin(now * BOB_SPEED + follower.index) * BOB_HEIGHT
	local y = root.Position.Y - 1.5 + follower.height / 2 + bob
	local position = Vector3.new(base.Position.X, y, base.Position.Z)
	local look = root.CFrame.LookVector
	return CFrame.lookAt(position, position + Vector3.new(look.X, 0, look.Z))
end

local function step(dt: number)
	local camera = Workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local now = os.clock()
	local alpha = 1 - math.exp(-FOLLOW_SPEED * dt)
	for player, list in byPlayer do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") and (root.Position - eye).Magnitude < FAR then
			for _, follower in list do
				local goal = target(root, follower, #list, now)
				local current = follower.model:GetPivot()
				-- Si quedó muy lejos (reapareció, se teletransportó), salta directo.
				if (current.Position - goal.Position).Magnitude > 60 then
					follower.model:PivotTo(goal)
				else
					follower.model:PivotTo(current:Lerp(goal, alpha))
				end
			end
		end
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Equipped"):Connect(function()
		rebuild(player)
	end)
	rebuild(player)
end

function Followers.start(_hud: HudController.Hud)
	local equip = KitConfig.equip
	if not equip or not equip.follow then
		return
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(clear)
	Bus.on("LowGraphics", function(on: any)
		lowGraphics = on == true
		for _, player in Players:GetPlayers() do
			rebuild(player)
		end
	end)
	RunService.Heartbeat:Connect(step)
end

return Followers
