--!strict
-- Lo que los hits ponen en el mundo (roblox-ui-designer/references/hud-hits.md, fila "En el mundo"):
-- - Carteles grandes sobre lo que se compra o se junta ("EGG SHOP", "SELL"): World.sign, o en Studio la
--   etiqueta "HitSign" en una parte con los atributos Text (inglés), Variant e Icon.
-- - Carteles flotantes de varias líneas sobre cada unidad (nombre, rareza, "$12/s"): World.tag.
-- - Flechas que avanzan por el piso hasta el objetivo: World.path (los kits llaman Bus "ShowPath").
-- Todo es local de este jugador y solo muestra: no cambia nada del juego.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)

local World = {}

export type Line = { text: string, color: Color3? }

local SIGN_TAG = "HitSign"
local SIGN_RATIO = 3.2 -- ancho/alto del cartel
local SIGN_DISTANCE = 300 -- studs: más lejos no se dibuja
local TAG_DISTANCE = 90
local PATH_COLOR = Color3.fromRGB(255, 64, 64)

local player = Players.LocalPlayer
local signs: { [Instance]: BillboardGui } = {}
local path: { beam: Beam, from: Attachment, to: Attachment?, target: Instance }? = nil
local pending: Instance? = nil -- objetivo pedido antes de que aparezca el personaje

local function container(): Instance
	return player:WaitForChild("PlayerGui")
end

-- La parte sobre la que flota: una BasePart o un Attachment; de un modelo, su PrimaryPart.
local function anchorOf(target: Instance): Instance?
	if target:IsA("BasePart") or target:IsA("Attachment") then
		return target
	end
	if target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function topOf(anchor: Instance): number
	return if anchor:IsA("BasePart") then anchor.Size.Y / 2 else 0
end

local function billboard(name: string, anchor: Instance, width: number, height: number, distance: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = anchor
	gui.Size = UDim2.fromScale(width, height) -- en un BillboardGui la escala es en studs
	gui.StudsOffsetWorldSpace = Vector3.new(0, topOf(anchor) + height / 2 + 0.5, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = distance
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = container()
	return gui
end

-- Cartel grande con el material de los hits. `width` en studs. Devuelve el BillboardGui (destruirlo lo
-- saca) o nil si `target` no es una parte, un attachment o un modelo con partes.
function World.sign(target: Instance, text: string, variant: UIKit.Variant?, icon: string?, width: number?): BillboardGui?
	local anchor = anchorOf(target)
	if not anchor then
		return nil
	end
	local w = width or 12
	local gui = billboard("Sign_" .. text, anchor, w, w / SIGN_RATIO, SIGN_DISTANCE)
	local plate = UIKit.new("Frame", {
		Name = "Plate",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.96, 0.84),
	}, gui) :: Frame
	UIKit.style(plate, variant or "Accept", 0.3, 0.05)
	local labelX = 0.5
	local labelWidth = 0.9
	if icon then
		UIKit.icon(plate, icon, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.1, 0.42),
			Size = UDim2.fromScale(1.35, 1.35),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Rotation = -8,
			ZIndex = 4,
		})
		labelX = 0.6
		labelWidth = 0.74
	end
	UIKit.label(plate, "Text", text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(labelX, 0.47),
		Size = UDim2.fromScale(labelWidth, 0.72),
		ZIndex = 3,
	}, 220, UIKit.TitleFont)
	return gui
end

-- Líneas flotantes sin fondo sobre una unidad: nombre, rareza en su color, ingreso en verde.
function World.tag(target: Instance, lines: { Line }, width: number?): BillboardGui?
	local anchor = anchorOf(target)
	if not anchor then
		return nil
	end
	local w = width or 6
	local gui = billboard("Tag", anchor, w, w * 0.2 * math.max(#lines, 1), TAG_DISTANCE)
	UIKit.new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
	}, gui)
	World.setTag(gui, lines)
	return gui
end

function World.setTag(gui: BillboardGui, lines: { Line })
	for _, child in gui:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local count = math.max(#lines, 1)
	for i, line in lines do
		local label = UIKit.label(gui, "Line" .. i, line.text, { Size = UDim2.fromScale(1, 1 / count), LayoutOrder = i }, 120, UIKit.TitleFont)
		if line.color then
			label.TextColor3 = line.color
		end
	end
end

local function clearPath()
	local current = path
	if not current then
		return
	end
	path = nil
	current.beam:Destroy()
	current.from:Destroy()
	if current.to then
		current.to:Destroy()
	end
end

-- Flechas que avanzan por el piso desde los pies del jugador hasta `target` (una parte, un attachment o
-- un modelo). nil las saca. Se rehacen solas si el personaje reaparece.
function World.path(target: Instance?)
	clearPath()
	pending = nil
	if not target then
		return
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local anchor = anchorOf(target)
	if not root or not root:IsA("BasePart") or not anchor then
		pending = target -- se arma cuando aparezca el personaje (World.start)
		return
	end
	pending = nil
	local from = Instance.new("Attachment")
	from.Name = "PathFrom"
	from.Position = Vector3.new(0, -root.Size.Y / 2 - 1.8, 0) -- a la altura de los pies
	from.Parent = root
	local to: Attachment? = nil
	local finish: Attachment
	if anchor:IsA("Attachment") then
		finish = anchor
	else
		local made = Instance.new("Attachment")
		made.Name = "PathTo"
		made.Position = Vector3.new(0, -topOf(anchor) + 0.4, 0)
		made.Parent = anchor
		to = made
		finish = made
	end
	local beam = Instance.new("Beam")
	beam.Name = "Path"
	beam.Attachment0 = from
	beam.Attachment1 = finish
	local texture = UIKit.textureId("arrows")
	if texture ~= "" then
		beam.Texture = texture
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 4
		beam.TextureSpeed = 1.5 -- avanzan hacia el objetivo
	end
	beam.Color = ColorSequence.new(PATH_COLOR)
	beam.Transparency = NumberSequence.new(if texture ~= "" then 0 else 0.35)
	beam.Width0 = 1.6
	beam.Width1 = 1.6
	beam.FaceCamera = true
	beam.LightInfluence = 0
	beam.LightEmission = 0.3
	beam.Segments = 1
	beam.Parent = root
	path = { beam = beam, from = from, to = to, target = target }
end


-- Carteles de Studio o del servidor (etiqueta "HitSign") y flechas que siguen al personaje. Si el
-- servidor cambia un atributo del cartel ("Leo's Base"), se vuelve a dibujar.
function World.start()
	local watchers: { [Instance]: { RBXScriptConnection } } = {}
	local function draw(instance: Instance)
		local old = signs[instance]
		if old then
			old:Destroy()
			signs[instance] = nil
		end
		local text = instance:GetAttribute("Text")
		if typeof(text) ~= "string" then
			warn("[World] " .. instance:GetFullName() .. " tiene la etiqueta HitSign sin el atributo Text")
			return
		end
		local variant = instance:GetAttribute("Variant")
		local icon = instance:GetAttribute("Icon")
		local width = instance:GetAttribute("Width")
		local gui = World.sign(
			instance,
			text,
			if typeof(variant) == "string" and UIKit.Colors[variant] then variant :: any else nil,
			if typeof(icon) == "string" then icon else nil,
			if typeof(width) == "number" then width else nil
		)
		if gui then
			signs[instance] = gui
		end
	end
	local function add(instance: Instance)
		if watchers[instance] then
			return
		end
		local list = {}
		for _, name in { "Text", "Variant", "Icon", "Width" } do
			table.insert(list, instance:GetAttributeChangedSignal(name):Connect(function()
				draw(instance)
			end))
		end
		watchers[instance] = list
		draw(instance)
	end
	for _, instance in CollectionService:GetTagged(SIGN_TAG) do
		add(instance)
	end
	CollectionService:GetInstanceAddedSignal(SIGN_TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(SIGN_TAG):Connect(function(instance: Instance)
		local connections = watchers[instance]
		if connections then
			for _, connection in connections do
				connection:Disconnect()
			end
		end
		watchers[instance] = nil
		local gui = signs[instance]
		if gui then
			gui:Destroy()
			signs[instance] = nil
		end
	end)
	player.CharacterAdded:Connect(function(character: Model)
		local target = if path then path.target else pending
		if target then
			character:WaitForChild("HumanoidRootPart", 10)
			World.path(target)
		end
	end)
end

return World
