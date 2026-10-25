-- Foto de rendimiento. Pegar en `execute_luau` del MCP de Studio durante un playtest:
--   datamodel Client → memoria, draw calls y triángulos que ve el jugador
--   datamodel Server → instancias, partes y scripts del lugar
-- No hay umbrales oficiales (salvo 20 000 triángulos por malla, que se controla al importar): comparar contra la foto anterior y contra
-- el dispositivo base (anotar ambas en docs/qa.md). Los números de Studio no reemplazan la prueba en el
-- teléfono: el emulador no reproduce la memoria real (guía oficial de rendimiento).

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local side = if RunService:IsClient() then "Client" else "Server"
local lines = {}
local function add(label: string, value: any)
	table.insert(lines, string.format("%-28s %s", label, tostring(value)))
end

add("Datamodel", side)
add("Memoria total (MB)", string.format("%.0f", Stats:GetTotalMemoryUsageMb()))
add("Instancias", Stats.InstanceCount)
add("Primitivas", Stats.PrimitivesCount)
if side == "Client" then
	add("Draw calls de escena", Stats.SceneDrawcallCount)
	add("Triángulos de escena", Stats.SceneTriangleCount)
end
add("StreamingEnabled", workspace.StreamingEnabled)

local parts, meshes, scripts = 0, 0, 0
for _, inst in workspace:GetDescendants() do
	if inst:IsA("BasePart") then
		parts += 1
	end
	if inst:IsA("MeshPart") then
		meshes += 1
	end
	if inst:IsA("BaseScript") then
		scripts += 1
	end
end
add("BaseParts en Workspace", parts)
add("MeshParts en Workspace", meshes)
add("Scripts en Workspace", scripts)

-- Las 5 ramas de Workspace con más instancias: dónde mirar primero si la memoria sube.
local heavy = {}
for _, child in workspace:GetChildren() do
	table.insert(heavy, { name = child.Name, count = #child:GetDescendants() })
end
table.sort(heavy, function(a, b)
	return a.count > b.count
end)
for i = 1, math.min(5, #heavy) do
	add("  rama pesada " .. i, heavy[i].name .. " (" .. heavy[i].count .. " instancias)")
end

return table.concat(lines, "\n")
