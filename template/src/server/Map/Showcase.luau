--!strict
-- Vitrina del lobby (etiqueta KitShowcase, atributo Unit): la unidad gigante sobre su pedestal, mirando
-- al spawn. Los hits ponen sus criaturas más raras enormes en el mapa: es lo que todos quieren tener.
-- El modelo es el de la unidad (Kits/UnitModel, con su cartel de nombre y rareza) escalado con
-- Model:ScaleTo (verificado en creator-docs, 2026-11-03). Funciona igual en un mapa hecho a mano.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local KitConfig = require(ReplicatedStorage.Shared.Config.KitConfig)
local Tags = require(ReplicatedStorage.Shared.Kits.Tags)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local KitWorld = require("../Kits/KitWorld")

local Showcase = {}

local SCALE = 4

local function place(instance: Instance)
	local id = KitWorld.text(instance, "Unit")
	local units = KitConfig.units
	if not id or not units or instance:FindFirstChild("ShowcaseUnit") then
		return
	end
	local def = nil
	for _, u in units.list do
		if u.id == id then
			def = u
		end
	end
	if not def then
		warn("[Showcase] la unidad '" .. id .. "' no está en la receta")
		return
	end
	-- Arriba de todo lo que tenga el pedestal.
	local top: Vector3
	if instance:IsA("Model") then
		local box, size = instance:GetBoundingBox()
		top = box.Position + Vector3.new(0, size.Y / 2, 0)
	elseif instance:IsA("BasePart") then
		top = instance.Position + Vector3.new(0, instance.Size.Y / 2, 0)
	else
		return
	end
	local model = UnitModel.make(def, { kind = id })
	model:ScaleTo(SCALE)
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local target = if spawn then spawn.Position else Vector3.zero
	local look = Vector3.new(target.X, top.Y, target.Z)
	local facing = if (look - top).Magnitude > 0.1 then CFrame.lookAt(top, look) else CFrame.new(top)
	UnitModel.standOn(model, facing)
	model.Name = "ShowcaseUnit"
	model.Parent = instance
end

function Showcase.start()
	KitWorld.tagged(Tags.SHOWCASE, place)
end

return Showcase
