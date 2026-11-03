--!strict
-- Arma en el servidor el mapa de la receta (Lib/MapPlan) cuando el lugar no tiene uno: carpeta "Map"
-- con modelos y partes ancladas, las etiquetas y atributos que buscan los bloques, el spawn y la luz
-- estilo hit (colores saturados, brillo suave, atmósfera). Si Workspace ya tiene una carpeta "Map"
-- (mapa hecho a mano en Studio con las mismas etiquetas), no toca nada. Sin `map` en la receta,
-- tampoco: la plantilla corre sin mapa como antes.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local MapPlan = require(ReplicatedStorage.Shared.Lib.MapPlan)

local MapKit = {}

local function color(hex: string): Color3
	local ok, value = pcall(Color3.fromHex, hex)
	return if ok then value else Color3.new(1, 1, 1)
end

local function material(name: string?): Enum.Material
	local ok, value = pcall(function(): Enum.Material
		return (Enum.Material :: any)[name or "SmoothPlastic"]
	end)
	return if ok and value then value else Enum.Material.SmoothPlastic
end

local function shape(name: string?): Enum.PartType
	if name == "Ball" then
		return Enum.PartType.Ball
	elseif name == "Cylinder" then
		return Enum.PartType.Cylinder
	end
	return Enum.PartType.Block
end

local function apply(instance: Instance, tags: { string }?, attrs: MapPlan.Attrs?)
	if tags then
		for _, tag in tags do
			instance:AddTag(tag)
		end
	end
	if attrs then
		for key, value in attrs do
			instance:SetAttribute(key, value)
		end
	end
end

local function makePart(spec: MapPlan.Part): BasePart
	local part: BasePart
	if spec.spawn then
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Neutral = true
		spawnLocation.Duration = 0 -- sin campo de fuerza al aparecer
		part = spawnLocation
	elseif spec.shape == "Wedge" then
		part = Instance.new("WedgePart")
	elseif spec.mesh == "Sphere" then
		-- Elipse de cualquier medida: bloque con SpecialMesh (la forma Ball es siempre pareja).
		local p = Instance.new("Part")
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		part = p
	else
		local p = Instance.new("Part")
		p.Shape = shape(spec.shape)
		part = p
	end
	part.Name = spec.name
	part.Size = Vector3.new(spec.size.x, spec.size.y, spec.size.z)
	-- Primero el giro horizontal y después el de costado (los cilindros se paran con rotZ = 90).
	part.CFrame = CFrame.new(spec.pos.x, spec.pos.y, spec.pos.z)
		* CFrame.fromEulerAnglesYXZ(0, math.rad(spec.rotY or 0), 0)
		* CFrame.fromEulerAnglesXYZ(0, 0, math.rad(spec.rotZ or 0))
	part.Anchored = true
	part.CanCollide = spec.collide ~= false
	part.CanTouch = true
	part.Color = color(spec.color)
	part.Material = material(spec.material)
	part.Transparency = spec.transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	apply(part, spec.tags, spec.attrs)
	return part
end

-- Luz de hit: día soleado y saturado (de noche en el espacio), sin pisar efectos que ya existan.
local function lighting(palette: MapPlan.Palette)
	local night = palette.night == true
	Lighting.ClockTime = if night then 0 else 14.5
	Lighting.Brightness = if night then 1.6 else 2.4
	Lighting.Ambient = if night then Color3.fromRGB(110, 96, 160) else Color3.fromRGB(120, 120, 135)
	Lighting.OutdoorAmbient = if night then Color3.fromRGB(130, 110, 190) else Color3.fromRGB(165, 165, 180)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true
	local function effect(className: string, name: string, props: { [string]: any })
		if Lighting:FindFirstChild(name) then
			return
		end
		local instance = Instance.new(className)
		instance.Name = name
		for key, value in props do
			(instance :: any)[key] = value
		end
		instance.Parent = Lighting
	end
	effect("ColorCorrectionEffect", "HitColor", { Saturation = 0.22, Contrast = 0.08, Brightness = 0.02 })
	effect("BloomEffect", "HitBloom", { Intensity = 0.35, Size = 24, Threshold = 1.5 })
	effect("Atmosphere", "HitAtmosphere", {
		Density = 0.22,
		Offset = 0.1,
		Color = color(palette.path),
		Decay = color(palette.edge),
		Glare = 0,
		Haze = 1,
	})
end

-- Arma el mapa. Devuelve la carpeta o nil si no correspondía (hay un mapa o la receta no tiene `map`).
function MapKit.build(): Folder?
	local recipe = KitConfig
	local map = recipe.map
	if not map or Workspace:FindFirstChild("Map") then
		return nil
	end
	if map.groupChest and GameConfig.GROUP_ID == 0 then
		-- Sin grupo no hay premio que cobrar: el cofre no se pone (un cartel de regalo vacío engaña).
		warn("[MapKit] map.groupChest sin GameConfig.GROUP_ID: el cofre del grupo no se pone")
		local copy = table.clone(map)
		copy.groupChest = false
		recipe = table.clone(recipe)
		recipe.map = copy
	end
	local plan = MapPlan.build(recipe)
	for _, text in plan.warnings do
		warn("[MapKit] " .. text)
	end
	-- Por clave (única); el nombre de la instancia puede repetirse (los edificios de cada base).
	local containers: { [string]: Instance } = {}
	for _, g in plan.groups do
		local instance: Instance = Instance.new(if g.model then "Model" else "Folder")
		instance.Name = g.name
		apply(instance, g.tags, g.attrs)
		containers[g.key] = instance
	end
	for _, g in plan.groups do
		local parent = if g.parent then containers[g.parent] else nil
		if parent then
			containers[g.key].Parent = parent
		end
	end
	for _, spec in plan.parts do
		makePart(spec).Parent = containers[spec.group] or containers.Map
	end
	-- Cada modelo con su parte principal (los carteles y los prompts se ponen ahí).
	for _, instance in containers do
		if instance:IsA("Model") and not instance.PrimaryPart then
			instance.PrimaryPart = instance:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	-- El piso del lugar nuevo de Studio sobra: el mapa trae el suyo.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
	lighting(plan.palette)
	-- Se agrega todo junto al final: los bloques ven cada etiqueta con sus atributos ya puestos.
	local folder = containers.Map :: Folder
	folder.Parent = Workspace
	return folder
end

return MapKit
