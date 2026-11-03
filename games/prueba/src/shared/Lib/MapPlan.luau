--!strict
-- MapPlan: el mapa estilo hit de una receta del armador, como datos (partes con tamaño, posición,
-- color, material, etiquetas y atributos). Sin Roblox: se prueba con el CLI (tests/MapPlan.spec.luau) y
-- server/Map/MapKit lo convierte en partes. Un mapa hecho a mano en Studio funciona igual si usa las
-- mismas etiquetas (Kits/Tags); MapKit solo arma uno si el lugar no tiene carpeta "Map".
--
-- El estilo sale de mirar Steal An Egg, Steal a Brainrot y Fish It! (miniaturas y videos, 2026-11-03;
-- notas en skills/roblox-game-kits/references/bloques.md, "El mapa"):
-- - piso de plástico con studs, colores muy saturados;
-- - corrales con cerco (o edificios de paredes altas) y pedestales para las unidades;
-- - puestos de madera con toldo a rayas y un aro brillante en el piso;
-- - alfombra roja con studs como cinta, placa de cobro verde;
-- - faroles, flores y arbustos;
-- - cerros de fondo o mar;
-- - islas con cerco de madera y arco con su nombre;
-- - la unidad más rara, gigante, en la plaza.
--
-- Distribución (Y arriba; el piso arriba en y = 0; pisos flotantes con su barranco abajo):
-- - Centro: plaza con el spawn (mirando al sur) y cuatro pasos en cruz que nada sólido tapa. Los
--   puestos (`map.shops` o los que piden los bloques), las tablas de posiciones, la ruleta y el cofre
--   del grupo van en anillos alrededor, mirando al centro: primero los de adelante del spawn.
-- - Sur: arco con el cartel NEXT UPDATE sobre el paso y, al fondo, la fila de puestos que se pisan o
--   usan (vender, mejoras, fusión).
-- - Norte: avenida con las bases a los dos lados (entrada hacia la avenida) y la cinta en el medio.
-- - Este: islas de zonas en fila, con puentes y puertas; adentro, las estaciones de tiradas junto al
--   camino y cuatro lotes para lo demás (cintas de correr, agua, pilas, salvajes). Los
--   teletransportes a cada zona quedan en el lobby, a los costados del paso del este.
-- - Oeste: plataformas de etapas sobre el vacío (huecos que se saltan con la velocidad de base).
-- Colores por tema (y por zona, si su nombre sugiere un bioma: "Beach", "Snowy Peaks", "Volcano").
-- Cada pieza reserva su lugar en el piso (`footprints`): la decoración solo va donde queda libre y
-- los tests revisan que nada choque y que todo lo que se usa esté sobre un piso (`floors`).

local Prng = require("./Prng")
local Types = require("../Kits/Types")

local MapPlan = {}

export type Vec = { x: number, y: number, z: number }
export type Attr = string | number | boolean
-- Atributos de una parte o grupo (valores Attr; `any` para no pelear con los literales en modo estricto).
export type Attrs = { [string]: any }
export type Part = {
	name: string,
	group: string, -- clave del grupo (Group.key)
	-- "Block" (por defecto), "Ball" (tamaño parejo), "Cylinder" (su eje es X), "Wedge" (alto atrás, +Z;
	-- baja hacia adelante, −Z)
	shape: string?,
	mesh: string?, -- "Sphere": bloque con SpecialMesh, una elipse de cualquier tamaño (choca como caja)
	size: Vec,
	pos: Vec,
	rotY: number?, -- grados; con rotY = a, la cara de adelante (−Z) mira hacia (−sin a, −cos a)
	rotZ: number?,
	color: string, -- hex
	material: string?, -- nombre de Enum.Material
	studs: boolean?, -- studs arriba (SurfaceType.Studs, el look clásico de los hits)
	transparency: number?,
	collide: boolean?, -- por defecto true
	tags: { string }?,
	attrs: Attrs?,
	spawn: boolean?, -- SpawnLocation
}
-- `key` es único en el plan (las partes lo usan); `name` es el nombre de la instancia.
export type Group = { key: string, name: string, parent: string?, model: boolean?, tags: { string }?, attrs: Attrs? }
-- Rectángulo en el piso (XZ), girado `angle` grados como una parte con rotY = angle (hx a lo largo de su
-- X, hz de su Z); x0..z1 es la caja que lo contiene. kind: "area" (base o isla: adentro van piezas),
-- "piece" (algo que se usa o se ve: puesto, pad, tabla), "corridor" (paso que nada sólido tapa),
-- "decor", "floor".
export type Footprint = {
	name: string,
	kind: string,
	solid: boolean,
	cx: number,
	cz: number,
	hx: number,
	hz: number,
	angle: number,
	x0: number,
	x1: number,
	z0: number,
	z1: number,
}
export type Palette = {
	ground: string,
	path: string,
	edge: string,
	cliff: string, -- barranco debajo de cada piso
	hill: string, -- cerros de fondo
	fence: string, -- cercos de las islas
	trunk: string,
	leaves: { string },
	flowers: { string },
	rock: string,
	water: string,
	decor: string, -- "tree", "palm", "lollipop", "pine", "cactus", "crystal", "coral"
	night: boolean?,
}
export type Plan = {
	groups: { Group },
	parts: { Part },
	footprints: { Footprint },
	floors: { Footprint }, -- donde se puede parar alguien: pisos, islas, puentes, plataformas
	warnings: { string }, -- lo que no entró (MapKit lo avisa; los tests de las recetas lo prohíben)
	theme: string,
	palette: Palette,
}

local ACCENTS = { "#FF5C8A", "#2EC5F5", "#FFD23A", "#46D64B", "#A35CFF", "#FF9F1A", "#2FE0C8", "#FF3B4F" }
local SIGN_VARIANTS = { "Accept", "Info", "Purple", "Pink", "Orange", "Cyan", "Premium" }
local WOOD = "#C98B4F"
local WOOD_DARK = "#8A5A2B"

-- Medidas (studs).
local PLAZA_RADIUS = 50
local LOBBY = { x0 = -80, x1 = 80, z0 = -132, z1 = 92 } -- piso del lobby
local AVENUE = 18 -- media avenida entre las bases
local PLOTS_Z = 100 -- donde empieza la primera fila de bases
local PLOT_GAP = 14 -- entre filas de bases
local ISLAND = 150 -- lado de cada isla de zona
local FIRST_ISLAND_X = 185 -- centro de la primera isla (puente de ~30 desde el lobby)
local ISLAND_STEP = 200 -- de centro a centro (puentes de 50 entre islas)
local SOUTH_ROW_Z = -98 -- fila de puestos del sur
local ARCH_Z = -56 -- arco del cartel NEXT UPDATE
local SHOWCASE = { r = 24, a = 135 } -- pedestal de la unidad gigante, adelante y a la derecha del spawn
local CELL = 9 -- espacios y parcelas de las bases
local COLUMNS = 4

MapPlan.THEMES = {
	meadow = { ground = "#6BDF3A", path = "#F3E2B0", edge = "#48B52C", cliff = "#9C6B3E", hill = "#D9A066", fence = "#8B5A2B", trunk = "#8A5A2B", leaves = { "#3AD152", "#2FBF45", "#7EE35F" }, flowers = { "#FF5C8A", "#FFD23A", "#FFFFFF", "#A35CFF" }, rock = "#A3A9B8", water = "#3BA7FF", decor = "tree" },
	beach = { ground = "#F7DE8F", path = "#FFF3CF", edge = "#E9C46A", cliff = "#C9A060", hill = "#E8C27A", fence = "#C68A4E", trunk = "#B07A3A", leaves = { "#3AD152", "#2FBF45" }, flowers = { "#FF5C8A", "#FF9F1A", "#FFFFFF" }, rock = "#D9C08A", water = "#2EC5F5", decor = "palm" },
	candy = { ground = "#FFA3D7", path = "#FFFFFF", edge = "#FF7AC4", cliff = "#7A4A2E", hill = "#8B5A3C", fence = "#FF7AC4", trunk = "#FFFFFF", leaves = { "#FF5C8A", "#A35CFF", "#2FE0C8", "#FFD23A" }, flowers = { "#2FE0C8", "#FFD23A", "#A35CFF" }, rock = "#FFCCE8", water = "#B488FF", decor = "lollipop" },
	snow = { ground = "#F2F7FF", path = "#CFE3F7", edge = "#BFD9F2", cliff = "#8FB4D9", hill = "#9CC3E6", fence = "#7A5A3A", trunk = "#7A5A3A", leaves = { "#2E8B57", "#3BA06A" }, flowers = { "#2EC5F5", "#A35CFF", "#FFFFFF" }, rock = "#AFC6DD", water = "#9AD8FF", decor = "pine" },
	jungle = { ground = "#3FBF4A", path = "#C89A60", edge = "#2F8A3A", cliff = "#6B4423", hill = "#8A6A45", fence = "#6B4423", trunk = "#6B4423", leaves = { "#1F8A3A", "#2FA84A", "#4CC35A" }, flowers = { "#FF5C8A", "#FF9F1A", "#FFD23A" }, rock = "#7D8B7A", water = "#3BC9A8", decor = "tree" },
	desert = { ground = "#F2C46B", path = "#F7DCA0", edge = "#E3A54C", cliff = "#C97A45", hill = "#E0995A", fence = "#A86B3C", trunk = "#4CAF50", leaves = { "#4CAF50", "#3E9B45" }, flowers = { "#FF5C8A", "#FFD23A" }, rock = "#D98C5F", water = "#3BA7FF", decor = "cactus" },
	volcano = { ground = "#5A4646", path = "#7A5C5C", edge = "#2E2424", cliff = "#2A1F1F", hill = "#3A2C2C", fence = "#3A2E2E", trunk = "#3A2E2E", leaves = { "#FF6A1A", "#FFB21A" }, flowers = { "#FF6A1A", "#FFB21A" }, rock = "#5A4A4A", water = "#FF5A1A", decor = "crystal" },
	space = { ground = "#4B3A8B", path = "#7B6BE6", edge = "#2A1E4E", cliff = "#22183F", hill = "#6B5BD6", fence = "#6B5BD6", trunk = "#2A1E4E", leaves = { "#2EE0C8", "#FF5CE1", "#A35CFF" }, flowers = { "#2EE0C8", "#FF5CE1" }, rock = "#4E3E8A", water = "#2EE0C8", decor = "crystal", night = true },
	farm = { ground = "#7FE04F", path = "#D9B27A", edge = "#5FB83E", cliff = "#8A5A2B", hill = "#C98F55", fence = "#A0522D", trunk = "#8A5A2B", leaves = { "#3AD152", "#2FBF45" }, flowers = { "#FF5C8A", "#FFD23A", "#FFFFFF" }, rock = "#A3A9B8", water = "#3BA7FF", decor = "tree" },
	city = { ground = "#7C8294", path = "#E1E5EE", edge = "#4A4E5C", cliff = "#3A3E4A", hill = "#B9BFCC", fence = "#9AA0AD", trunk = "#7A5A3A", leaves = { "#3AD152", "#2FBF45" }, flowers = { "#FF5C8A", "#2EC5F5" }, rock = "#9AA0AD", water = "#3BA7FF", decor = "tree" },
	underwater = { ground = "#2E9BD9", path = "#8FE0F7", edge = "#1F6FA8", cliff = "#1A5A8A", hill = "#3F8FC0", fence = "#1F6FA8", trunk = "#1F6FA8", leaves = { "#FF5C8A", "#FF9F1A", "#A35CFF" }, flowers = { "#FF5C8A", "#FF9F1A", "#A35CFF" }, rock = "#3F7FA8", water = "#2EC5F5", decor = "coral" },
} :: { [string]: Palette }

-- Bioma de una zona por su nombre (en inglés); si no se reconoce, nil.
local BIOME_WORDS: { { string } } = {
	{ "beach", "beach", "ocean", "sea", "island", "tropic", "shore" },
	{ "candy", "candy", "sweet", "sugar", "cake" },
	{ "snow", "snow", "ice", "winter", "frost", "arctic", "frozen" },
	{ "jungle", "jungle", "forest", "rainforest", "wood" },
	{ "desert", "desert", "sand", "dune", "canyon", "egypt" },
	{ "volcano", "volcano", "lava", "fire", "magma", "hell" },
	{ "space", "space", "moon", "galaxy", "planet", "star", "cosmic", "alien" },
	{ "underwater", "reef", "underwater", "deep", "coral", "atlantis" },
	{ "farm", "farm", "barn", "ranch" },
	{ "meadow", "meadow", "grass", "spawn", "hill", "garden", "park" },
}
function MapPlan.biome(name: string): string?
	local lower = string.lower(name)
	for _, entry in BIOME_WORDS do
		for i = 2, #entry do
			if string.find(lower, entry[i], 1, true) then
				return entry[1]
			end
		end
	end
	return nil
end

-- Construcción --------------------------------------------------------------------------------------

type Decor = { group: string, palette: Palette, x: number, z: number, scale: number }
type Builder = {
	plan: Plan,
	random: () -> number,
	used: { [string]: number },
	pending: { Decor },
}

local function v(x: number, y: number, z: number): Vec
	return { x = x, y = y, z = z }
end

-- Grupo nuevo (Folder o Model). Devuelve su clave: el nombre o, si ya hay uno igual, el nombre con un
-- número (cada base tiene sus "Building_Farm").
local function group(b: Builder, name: string, parent: string?, model: boolean?, tags: { string }?, attrs: Attrs?): string
	local n = (b.used[name] or 0) + 1
	b.used[name] = n
	local key = if n == 1 then name else name .. "#" .. n
	table.insert(b.plan.groups, { key = key, name = name, parent = parent, model = model, tags = tags, attrs = attrs })
	return key
end

local function part(b: Builder, spec: Part): Part
	table.insert(b.plan.parts, spec)
	return spec
end

-- Medias medidas de la caja que contiene a un rectángulo de medias medidas hx × hz girado `angle`.
local function bounds(hx: number, hz: number, angle: number): (number, number)
	local c, s = math.abs(math.cos(math.rad(angle))), math.abs(math.sin(math.rad(angle)))
	return c * hx + s * hz, s * hx + c * hz
end

local function orect(name: string, kind: string, solid: boolean, cx: number, cz: number, hx: number, hz: number, angle: number): Footprint
	local bx, bz = bounds(hx, hz, angle)
	return { name = name, kind = kind, solid = solid, cx = cx, cz = cz, hx = hx, hz = hz, angle = angle, x0 = cx - bx, x1 = cx + bx, z0 = cz - bz, z1 = cz + bz }
end

local function rect(name: string, kind: string, solid: boolean, cx: number, cz: number, hx: number, hz: number): Footprint
	return orect(name, kind, solid, cx, cz, hx, hz, 0)
end

-- Ejes de un rectángulo girado: su X (ux, uz) y su Z (vx, vz) en el mundo.
local function axesOf(f: Footprint): (number, number, number, number)
	local r = math.rad(f.angle)
	return math.cos(r), -math.sin(r), math.sin(r), math.cos(r)
end

-- Media longitud de la sombra del rectángulo sobre un eje.
local function shadow(f: Footprint, ax: number, az: number): number
	local ux, uz, vx, vz = axesOf(f)
	return f.hx * math.abs(ux * ax + uz * az) + f.hz * math.abs(vx * ax + vz * az)
end

-- ¿Se pisan? (tocarse en un borde no cuenta). Ejes separadores entre los dos rectángulos girados.
function MapPlan.overlaps(a: Footprint, c: Footprint): boolean
	if not (a.x0 < c.x1 and c.x0 < a.x1 and a.z0 < c.z1 and c.z0 < a.z1) then
		return false
	end
	if a.angle % 90 == 0 and c.angle % 90 == 0 then
		return true -- los dos derechos: la caja es exacta
	end
	local dx, dz = c.cx - a.cx, c.cz - a.cz
	for _, f in { a, c } do
		local ux, uz, vx, vz = axesOf(f)
		for _, axis in { { ux, uz }, { vx, vz } } do
			local distance = math.abs(dx * axis[1] + dz * axis[2])
			if distance >= shadow(a, axis[1], axis[2]) + shadow(c, axis[1], axis[2]) - 1e-9 then
				return false
			end
		end
	end
	return true
end

-- ¿El rectángulo entra entero en alguno de los pisos?
function MapPlan.onFloor(plan: Plan, f: Footprint): boolean
	for _, floor in plan.floors do
		if f.x0 >= floor.x0 - 1e-6 and f.x1 <= floor.x1 + 1e-6 and f.z0 >= floor.z0 - 1e-6 and f.z1 <= floor.z1 + 1e-6 then
			return true
		end
	end
	return false
end

-- Problemas del armado: avisos, piezas que chocan, piezas sólidas en un paso, áreas que se pisan,
-- decoración encima de algo y piezas fuera de un piso. Vacío = sano (lo usan los tests).
function MapPlan.audit(plan: Plan): { string }
	local out = table.clone(plan.warnings)
	local list = plan.footprints
	for i = 1, #list do
		local a = list[i]
		if a.kind == "piece" and not MapPlan.onFloor(plan, a) then
			table.insert(out, a.name .. " no está sobre un piso")
		end
		for j = i + 1, #list do
			local c = list[j]
			if MapPlan.overlaps(a, c) then
				-- Por el par de clases (como texto, para que el chequeo de tipos no las refine).
				local pair = a.kind .. "+" .. c.kind
				local decorOnSomething = (string.find(pair, "decor", 1, true) ~= nil) and not (string.find(pair, "area", 1, true) ~= nil)
				local bad = pair == "piece+piece"
					or pair == "area+area"
					or (pair == "piece+corridor" and a.solid)
					or (pair == "corridor+piece" and c.solid)
					or decorOnSomething
				if bad then
					table.insert(out, a.name .. " (" .. a.kind .. ") choca con " .. c.name .. " (" .. c.kind .. ")")
				end
			end
		end
	end
	return out
end

local function reserve(b: Builder, name: string, kind: string, solid: boolean, cx: number, cz: number, hx: number, hz: number)
	table.insert(b.plan.footprints, rect(name, kind, solid, cx, cz, hx, hz))
end

local function floorAt(b: Builder, name: string, cx: number, cz: number, hx: number, hz: number)
	table.insert(b.plan.floors, rect(name, "floor", false, cx, cz, hx, hz))
end

-- ¿Entra algo acá sin pisar piezas, pasos ni decoración? (las áreas no cuentan: adentro van cosas)
local function free(b: Builder, cx: number, cz: number, hx: number, hz: number, angle: number?): boolean
	local probe = orect("", "", false, cx, cz, hx, hz, angle or 0)
	for _, f in b.plan.footprints do
		if f.kind ~= "area" and MapPlan.overlaps(probe, f) then
			return false
		end
	end
	return true
end

local function warn(b: Builder, text: string)
	table.insert(b.plan.warnings, text)
end

local function newBuilder(theme: string, seed: number): Builder
	local palette = MapPlan.THEMES[theme] or MapPlan.THEMES.meadow
	local b: Builder = {
		plan = { groups = {}, parts = {}, footprints = {}, floors = {}, warnings = {}, theme = theme, palette = palette },
		random = Prng.new(seed),
		used = {},
		pending = {},
	}
	group(b, "Map", nil)
	return b
end

-- Una semilla estable a partir del nombre de la receta (el mismo mapa cada vez).
local function seedOf(text: string): number
	local h = 2166136261
	for i = 1, #text do
		h = (h * 16777619 + string.byte(text, i)) % 4294967296
	end
	return h
end

local function pick<T>(b: Builder, list: { T }): T
	return list[math.floor(b.random() * #list) + 1]
end

-- Cartel del mundo: HitSign con texto (lo dibuja UI/World en cada cliente).
local function signAttrs(text: string, variant: string, icon: string?, width: number?): Attrs
	local attrs: Attrs = { Text = text, Variant = variant, Width = width or 12 }
	if icon then
		attrs.Icon = icon
	end
	return attrs
end

-- Piso con studs y su barranco abajo (islas flotantes).
local function ground(b: Builder, name: string, groupKey: string, palette: Palette, cx: number, cz: number, hx: number, hz: number)
	part(b, { name = name, group = groupKey, size = v(hx * 2, 2, hz * 2), pos = v(cx, -1, cz), color = palette.ground, material = "Plastic", studs = true })
	part(b, { name = name .. "Cliff", group = groupKey, size = v(hx * 2 - 4, 18, hz * 2 - 4), pos = v(cx, -11, cz), color = palette.cliff, material = "Slate" })
	floorAt(b, name, cx, cz, hx, hz)
end

-- Camino de color con studs (y un paso reservado que nada sólido tapa).
local function path(b: Builder, name: string, groupKey: string, color: string, x0: number, x1: number, z0: number, z1: number)
	part(b, { name = name, group = groupKey, size = v(x1 - x0, 0.5, z1 - z0), pos = v((x0 + x1) / 2, 0.2, (z0 + z1) / 2), color = color, material = "Plastic", studs = true })
	reserve(b, name, "corridor", false, (x0 + x1) / 2, (z0 + z1) / 2, (x1 - x0) / 2, (z1 - z0) / 2)
end

-- Cerco recto de postes y dos travesaños, de (x0, z0) a (x1, z1), parado en la altura `base`.
local function fence(b: Builder, groupKey: string, x0: number, z0: number, x1: number, z1: number, rail: string, post: string, base: number)
	local dx, dz = x1 - x0, z1 - z0
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 1 then
		return
	end
	local n = math.max(1, math.ceil(length / 7))
	for i = 0, n do
		local t = i / n
		part(b, { name = "FencePost", group = groupKey, size = v(0.9, 4.4, 0.9), pos = v(x0 + dx * t, base + 2.2, z0 + dz * t), color = post, material = "SmoothPlastic" })
	end
	-- El travesaño corre por su eje X: girado para seguir la dirección del cerco.
	local rotY = math.deg(math.atan2(-dz, dx))
	for _, h in { 1.7, 3.3 } do
		part(b, { name = "FenceRail", group = groupKey, size = v(length, 0.55, 0.4), pos = v(x0 + dx / 2, base + h, z0 + dz / 2), rotY = rotY, color = rail, material = "SmoothPlastic" })
	end
end

-- Farol: poste oscuro con una luz cálida arriba (solo si queda libre).
local function lamp(b: Builder, groupKey: string, x: number, z: number)
	if not free(b, x, z, 0.8, 0.8) then
		return
	end
	part(b, { name = "LampPost", group = groupKey, shape = "Cylinder", size = v(8, 0.7, 0.7), pos = v(x, 4, z), rotZ = 90, color = "#3A3E4A", material = "Metal" })
	part(b, { name = "LampLight", group = groupKey, shape = "Ball", size = v(2, 2, 2), pos = v(x, 8.6, z), color = "#FFE9A8", material = "Neon" })
	reserve(b, "Lamp", "piece", true, x, z, 0.8, 0.8)
end

-- Decoración ------------------------------------------------------------------------------------------

-- Lo que ocupa un adorno de escala 1 (radio, en studs).
local DECOR_RADIUS = 5.5

local function bush(b: Builder, groupKey: string, palette: Palette, x: number, z: number, s: number)
	part(b, { name = "Bush", group = groupKey, mesh = "Sphere", size = v(6 * s, 4 * s, 5 * s), pos = v(x, 1.6 * s, z), color = pick(b, palette.leaves), material = "SmoothPlastic", collide = false })
	part(b, { name = "Bush", group = groupKey, mesh = "Sphere", size = v(4 * s, 3.2 * s, 4 * s), pos = v(x + 2.2 * s, 1.3 * s, z + 1.4 * s), color = pick(b, palette.leaves), material = "SmoothPlastic", collide = false })
end

local function flowers(b: Builder, groupKey: string, palette: Palette, x: number, z: number, s: number)
	for i = 0, 2 do
		local a = math.rad(i * 120 + 30)
		local fx, fz = x + math.cos(a) * 1.4 * s, z + math.sin(a) * 1.4 * s
		part(b, { name = "Stem", group = groupKey, shape = "Cylinder", size = v(1.6 * s, 0.3 * s, 0.3 * s), pos = v(fx, 0.8 * s, fz), rotZ = 90, color = "#2FBF45", material = "SmoothPlastic", collide = false })
		part(b, { name = "Flower", group = groupKey, shape = "Ball", size = v(1.1 * s, 1.1 * s, 1.1 * s), pos = v(fx, 1.8 * s, fz), color = pick(b, palette.flowers), material = "SmoothPlastic", collide = false })
	end
end

local function decor(b: Builder, groupKey: string, palette: Palette, x: number, z: number, scale: number)
	local s = scale
	local roll = b.random()
	if roll < 0.22 then
		bush(b, groupKey, palette, x, z, s)
		return
	elseif roll < 0.36 then
		flowers(b, groupKey, palette, x, z, s)
		return
	end
	local leaf = pick(b, palette.leaves)
	local kind = palette.decor
	if kind == "palm" then
		part(b, { name = "Trunk", group = groupKey, shape = "Cylinder", size = v(14 * s, 1.6 * s, 1.6 * s), pos = v(x, 7 * s, z), rotZ = 80, color = palette.trunk, material = "Wood" })
		for i = 0, 3 do
			local a = math.rad(i * 90 + 20)
			part(b, { name = "Leaf", group = groupKey, size = v(8 * s, 0.8 * s, 3 * s), pos = v(x + math.cos(a) * 3.5 * s + 1.2 * s, 14 * s, z + math.sin(a) * 3.5 * s), rotY = -i * 90 - 20, rotZ = -18, color = leaf, material = "SmoothPlastic", collide = false })
		end
	elseif kind == "lollipop" then
		part(b, { name = "Stick", group = groupKey, shape = "Cylinder", size = v(10 * s, 0.8 * s, 0.8 * s), pos = v(x, 5 * s, z), rotZ = 90, color = "#FFFFFF", material = "SmoothPlastic" })
		part(b, { name = "Candy", group = groupKey, shape = "Cylinder", size = v(1.2 * s, 7 * s, 7 * s), pos = v(x, 11 * s, z), rotY = math.floor(b.random() * 180), color = leaf, material = "SmoothPlastic" })
	elseif kind == "pine" then
		part(b, { name = "Trunk", group = groupKey, shape = "Cylinder", size = v(3 * s, 1.4 * s, 1.4 * s), pos = v(x, 1.5 * s, z), rotZ = 90, color = palette.trunk, material = "Wood" })
		for i = 0, 2 do
			local w = (8 - i * 2.2) * s
			part(b, { name = "Needles", group = groupKey, shape = "Cylinder", size = v(3 * s, w, w), pos = v(x, (4 + i * 3) * s, z), rotZ = 90, color = leaf, material = "SmoothPlastic" })
		end
		part(b, { name = "Snow", group = groupKey, shape = "Ball", size = v(2.4 * s, 2.4 * s, 2.4 * s), pos = v(x, 12.5 * s, z), color = "#FFFFFF", material = "SmoothPlastic" })
	elseif kind == "cactus" then
		part(b, { name = "Body", group = groupKey, shape = "Cylinder", size = v(9 * s, 2.4 * s, 2.4 * s), pos = v(x, 4.5 * s, z), rotZ = 90, color = leaf, material = "SmoothPlastic" })
		part(b, { name = "Arm", group = groupKey, shape = "Cylinder", size = v(3.5 * s, 1.6 * s, 1.6 * s), pos = v(x + 2 * s, 5.5 * s, z), rotZ = 90, color = leaf, material = "SmoothPlastic" })
		part(b, { name = "Arm", group = groupKey, shape = "Cylinder", size = v(3 * s, 1.6 * s, 1.6 * s), pos = v(x - 2 * s, 4 * s, z), rotZ = 90, color = leaf, material = "SmoothPlastic" })
	elseif kind == "crystal" then
		for i = 0, 2 do
			local h = (6 + i * 2.5) * s
			part(b, { name = "Crystal", group = groupKey, size = v(2 * s, h, 2 * s), pos = v(x + (i - 1) * 1.6 * s, h / 2, z + (i % 2) * 1.2 * s), rotY = i * 25, rotZ = (i - 1) * 14, color = leaf, material = "Neon", transparency = 0.15 })
		end
	elseif kind == "coral" then
		for i = 0, 2 do
			local h = (4 + i * 2) * s
			part(b, { name = "Coral", group = groupKey, shape = "Cylinder", size = v(h, 1.4 * s, 1.4 * s), pos = v(x + (i - 1) * 1.8 * s, h / 2, z), rotZ = 90 + (i - 1) * 18, color = pick(b, palette.leaves), material = "SmoothPlastic" })
			part(b, { name = "Tip", group = groupKey, shape = "Ball", size = v(2.2 * s, 2.2 * s, 2.2 * s), pos = v(x + (i - 1) * 1.8 * s + (i - 1) * h * 0.15, h, z), color = pick(b, palette.leaves), material = "SmoothPlastic" })
		end
	else
		-- Árbol de bloques: tronco y copa de dos elipses.
		part(b, { name = "Trunk", group = groupKey, shape = "Cylinder", size = v(6 * s, 1.8 * s, 1.8 * s), pos = v(x, 3 * s, z), rotZ = 90, color = palette.trunk, material = "Wood" })
		part(b, { name = "Leaves", group = groupKey, mesh = "Sphere", size = v(8 * s, 7 * s, 8 * s), pos = v(x, 8 * s, z), color = leaf, material = "SmoothPlastic", collide = false })
		part(b, { name = "Leaves", group = groupKey, shape = "Ball", size = v(5 * s, 5 * s, 5 * s), pos = v(x + 1.5 * s, 11 * s, z - 1 * s), color = pick(b, palette.leaves), material = "SmoothPlastic", collide = false })
	end
	if b.random() < 0.35 then
		part(b, { name = "Rock", group = groupKey, mesh = "Sphere", size = v(3 * s, 2 * s, 2.6 * s), pos = v(x + 3.5 * s, 0.6 * s, z + 2.5 * s), color = palette.rock, material = "SmoothPlastic" })
	end
end

-- Pedido de un adorno: se pone al final, solo si queda libre y sobre un piso.
local function decorLater(b: Builder, groupKey: string, palette: Palette, x: number, z: number, scale: number)
	table.insert(b.pending, { group = groupKey, palette = palette, x = x, z = z, scale = scale })
end

-- Adornos a lo largo de los cuatro lados de un rectángulo, a `d` del borde (d < 0: hacia adentro).
local function ring(b: Builder, groupKey: string, palette: Palette, cx: number, cz: number, hx: number, hz: number, d: number, step: number)
	local ex, ez = hx + d, hz + d
	for _, side in { 1, -1 } do
		local n = math.max(1, math.floor(ex * 2 / step))
		for i = 0, n do
			local x = cx - ex + i * (ex * 2 / n)
			decorLater(b, groupKey, palette, x + (b.random() - 0.5) * 4, cz + side * ez + (b.random() - 0.5) * 3, 0.8 + b.random() * 0.4)
		end
		local m = math.max(1, math.floor(ez * 2 / step))
		for i = 1, m - 1 do
			local z = cz - ez + i * (ez * 2 / m)
			decorLater(b, groupKey, palette, cx + side * ex + (b.random() - 0.5) * 3, z + (b.random() - 0.5) * 4, 0.8 + b.random() * 0.4)
		end
	end
end

local function flushDecor(b: Builder)
	for _, d in b.pending do
		local r = DECOR_RADIUS * d.scale
		if MapPlan.onFloor(b.plan, rect("", "", false, d.x, d.z, r, r)) and free(b, d.x, d.z, r, r) then
			decor(b, d.group, d.palette, d.x, d.z, d.scale)
			reserve(b, "Decor", "decor", true, d.x, d.z, r, r)
		end
	end
	table.clear(b.pending)
end

-- Un cerro escalonado: dos o tres mesetas con studs, cada una más chica, con su borde del color del
-- piso (las terrazas de Steal An Egg). Arranca debajo del piso, como los barrancos.
local function mesa(b: Builder, groupKey: string, palette: Palette, x: number, z: number, sx: number, sz: number, h: number)
	local tops: { number } = if h > 26 then { h * 0.42, h * 0.74, h } elseif h > 14 then { h * 0.58, h } else { h }
	local bottom = -18
	local ox, oz = 0, 0
	for k, top in tops do
		local shrink = 1 - (k - 1) * 0.24
		local w, d = sx * shrink, sz * shrink
		local height = top - bottom
		part(b, { name = "Hill", group = groupKey, size = v(w, height, d), pos = v(x + ox, bottom + height / 2, z + oz), color = palette.hill, material = "Plastic", studs = true })
		part(b, { name = "HillTop", group = groupKey, size = v(w + 0.6, 1.2, d + 0.6), pos = v(x + ox, top + 0.6, z + oz), color = palette.ground, material = "Plastic", studs = true })
		bottom = top
		ox += (b.random() - 0.5) * sx * 0.12
		oz += (b.random() - 0.5) * sz * 0.12
	end
end

-- Cerros de fondo a lo largo de un borde, hacia afuera (nx, nz), salvo en `gaps` (tramos del borde,
-- en distancia desde el comienzo, que quedan abiertos).
local function ridge(b: Builder, groupKey: string, palette: Palette, ax: number, az: number, bx: number, bz: number, nx: number, nz: number, gaps: { { number } }?)
	local dx, dz = bx - ax, bz - az
	local length = math.sqrt(dx * dx + dz * dz)
	local ux, uz = dx / length, dz / length
	local t = 0
	while t < length do
		local w = 18 + b.random() * 14
		local d = 16 + b.random() * 12
		local h = 10 + b.random() * 30
		local mid = t + w / 2
		local open = false
		for _, gap in gaps or ({} :: { { number } }) do
			if mid + w / 2 > gap[1] and mid - w / 2 < gap[2] then
				open = true
			end
		end
		if not open then
			local out = d / 2 + 1
			local x, z = ax + ux * mid + nx * out, az + uz * mid + nz * out
			-- El ancho va a lo largo del borde: girado si el borde corre por Z.
			local sx, sz = if math.abs(ux) > 0.5 then w else d, if math.abs(ux) > 0.5 then d else w
			mesa(b, groupKey, palette, x, z, sx, sz, h)
		end
		t += w - 4
	end
end

-- Piezas -----------------------------------------------------------------------------------------------

-- Puesto que abre una ventana (KitShopStand): mostrador de madera, toldo a rayas que baja hacia el
-- cliente, cartel y aro brillante en el piso. `faceY`: hacia dónde mira, f = (sin faceY, cos faceY).
local function stand(b: Builder, parent: string, window: string, label: string, icon: string?, color: string, x: number, z: number, faceY: number)
	local g = group(b, "Stand_" .. window, parent, true, { "KitShopStand", "HitSign" }, {
		Window = window,
		Label = label,
		Text = string.upper(label),
		Variant = "Accept",
		Icon = icon or "shop",
		Width = 12,
	})
	local rad = math.rad(faceY)
	local fx, fz = math.sin(rad), math.cos(rad)
	local tx, tz = math.cos(rad), -math.sin(rad)
	part(b, { name = "Counter", group = g, size = v(12, 4, 4), pos = v(x, 2, z), rotY = faceY, color = WOOD, material = "WoodPlanks" })
	part(b, { name = "Front", group = g, size = v(12.2, 1.2, 4.2), pos = v(x, 4.2, z), rotY = faceY, color = color, material = "SmoothPlastic" })
	for _, side in { -1, 1 } do
		local px = x + tx * 5.4 * side - fx * 3
		local pz = z + tz * 5.4 * side - fz * 3
		part(b, { name = "Post", group = g, shape = "Cylinder", size = v(9, 1, 1), pos = v(px, 4.5, pz), rotZ = 90, color = WOOD_DARK, material = "Wood" })
	end
	-- Toldo a rayas: la cuña baja hacia su frente (−Z), así que va girada 180 más que el mostrador.
	local stripes = 6
	for i = 0, stripes - 1 do
		local offset = -7 + 14 / stripes * (i + 0.5)
		part(b, { name = "Awning", group = g, shape = "Wedge", size = v(14 / stripes, 2.5, 7), pos = v(x - fx * 2 + tx * offset, 10, z - fz * 2 + tz * offset), rotY = faceY + 180, color = if i % 2 == 0 then color else "#FFFFFF", material = "SmoothPlastic" })
	end
	part(b, { name = "Glow", group = g, shape = "Cylinder", size = v(0.2, 8, 8), pos = v(x + fx * 6, 0.5, z + fz * 6), rotZ = 90, color = "#FFD23A", material = "Neon", transparency = 0.35, collide = false })
	return g
end

-- Pad redondo y plano (se pisa).
local function pad(b: Builder, groupKey: string, name: string, size: number, x: number, z: number, color: string, tags: { string }, attrs: Attrs?, height: number?): Part
	return part(b, { name = name, group = groupKey, shape = "Cylinder", size = v(0.6, size, size), pos = v(x, (height or 0) + 0.3, z), rotZ = 90, color = color, material = "Neon", tags = tags, attrs = attrs, transparency = 0.1 })
end

-- Tabla de posiciones (KitLeaderboard, atributo Stat): el cliente dibuja la lista en la cara de
-- adelante de "Board" (atributo Face), que mira al centro de la plaza.
local function leaderboard(b: Builder, stat: string, x: number, z: number, a: number)
	local g = group(b, "Board_" .. stat, "Lobby", true, { "KitLeaderboard" }, { Stat = stat })
	local rad = math.rad(a)
	local ox, oz = math.sin(rad) * 0.7, math.cos(rad) * 0.7 -- hacia atrás (lejos del centro)
	local tx, tz = math.cos(rad), -math.sin(rad) -- a lo ancho
	part(b, { name = "Board", group = g, size = v(16, 18, 1), pos = v(x, 12, z), rotY = a, color = "#2D2F3A", material = "SmoothPlastic", attrs = { Face = "Front" } })
	part(b, { name = "Frame", group = g, size = v(17.6, 19.6, 0.8), pos = v(x + ox, 12, z + oz), rotY = a, color = "#FFD23A", material = "SmoothPlastic" })
	part(b, { name = "Crown", group = g, shape = "Wedge", size = v(17.6, 2.4, 1.6), pos = v(x + ox, 23, z + oz), rotY = a + 180, color = "#FFD23A", material = "SmoothPlastic" })
	for _, s in { -1, 1 } do
		part(b, { name = "Leg", group = g, size = v(1.6, 3, 1.6), pos = v(x + ox + tx * 6 * s, 1.5, z + oz + tz * 6 * s), rotY = a, color = "#FFD23A", material = "SmoothPlastic" })
	end
end

-- Ruleta del mundo: abre la ventana Spin.
local function wheel(b: Builder, x: number, z: number, a: number)
	local g = group(b, "Stand_Spin", "Lobby", true, { "KitShopStand", "HitSign" }, { Window = "Spin", Label = "Spin", Text = "SPIN", Variant = "Pink", Icon = "spin", Width = 10 })
	local rad = math.rad(a)
	local ix, iz = -math.sin(rad), -math.cos(rad) -- hacia el centro
	-- Disco parado con su eje (X) apuntando al centro: rotY = a − 90.
	part(b, { name = "Wheel", group = g, shape = "Cylinder", size = v(1.6, 16, 16), pos = v(x, 11, z), rotY = a - 90, color = "#FFFFFF", material = "SmoothPlastic" })
	-- Rayos de colores sobre la cara: con rotY = a su eje Z apunta al centro y rotZ los gira en la cara.
	for i = 0, 3 do
		part(b, { name = "Slice", group = g, size = v(3.2, 14, 0.4), pos = v(x + ix * 0.9, 11, z + iz * 0.9), rotY = a, rotZ = i * 45, color = ACCENTS[i + 1], material = "SmoothPlastic" })
	end
	part(b, { name = "Hub", group = g, shape = "Ball", size = v(3, 3, 3), pos = v(x + ix * 1.4, 11, z + iz * 1.4), color = "#FFD23A", material = "SmoothPlastic" })
	part(b, { name = "Pointer", group = g, size = v(2.2, 2.2, 1), pos = v(x + ix * 1.2, 19.8, z + iz * 1.2), rotY = a, rotZ = 45, color = "#FF3B4F", material = "SmoothPlastic" })
	part(b, { name = "Stand", group = g, size = v(3, 3, 3), pos = v(x, 1.5, z), rotY = a, color = "#FFD23A", material = "SmoothPlastic" })
end

-- Cofre del grupo: el cliente le pone un prompt que cobra el premio por unirse.
local function chest(b: Builder, x: number, z: number, a: number)
	local g = group(b, "GroupChest", "Lobby", true, { "KitGroupChest", "HitSign" }, signAttrs("FREE GIFT", "Purple", "chest", 10))
	part(b, { name = "Chest", group = g, size = v(7, 5, 5), pos = v(x, 2.5, z), rotY = a, color = "#B07A3A", material = "WoodPlanks" })
	part(b, { name = "Lid", group = g, size = v(7.4, 1.6, 5.4), pos = v(x, 5.8, z), rotY = a, color = "#FFD23A", material = "SmoothPlastic" })
	part(b, { name = "Lock", group = g, size = v(1.4, 1.8, 0.6), pos = v(x - math.sin(math.rad(a)) * 2.8, 4.6, z - math.cos(math.rad(a)) * 2.8), rotY = a, color = "#FFD23A", material = "Neon" })
	part(b, { name = "Glow", group = g, shape = "Cylinder", size = v(0.2, 9, 9), pos = v(x, 0.5, z), rotZ = 90, color = "#A35CFF", material = "Neon", transparency = 0.4, collide = false })
end

-- Lugares del lobby, en orden (radio, ángulo; ángulo 180 = sur, adelante del spawn). Cada cosa toma el
-- primero libre y mira al centro.
local SLOTS: { { r: number, a: number } } = {
	{ r = 40, a = 148 },
	{ r = 40, a = 212 },
	{ r = 40, a = 122 },
	{ r = 40, a = 238 },
	{ r = 40, a = 58 },
	{ r = 40, a = 302 },
	{ r = 40, a = 32 },
	{ r = 40, a = 328 },
	{ r = 64, a = 160 },
	{ r = 64, a = 200 },
	{ r = 64, a = 138 },
	{ r = 64, a = 222 },
	{ r = 64, a = 116 },
	{ r = 64, a = 244 },
	{ r = 64, a = 64 },
	{ r = 64, a = 296 },
	{ r = 64, a = 40 },
	{ r = 64, a = 320 },
}

-- Primer lugar libre del lobby para algo de w × d (ancho a lo largo del anillo, mirando al centro: un
-- rectángulo girado como una parte con rotY = ángulo). Lo reserva.
local function slot(b: Builder, taken: { [number]: boolean }, name: string, w: number, d: number): (number?, number, number)
	for i, s in SLOTS do
		if not taken[i] then
			local x, z = math.sin(math.rad(s.a)) * s.r, math.cos(math.rad(s.a)) * s.r
			if free(b, x, z, w / 2, d / 2, s.a) then
				taken[i] = true
				table.insert(b.plan.footprints, orect(name, "piece", true, x, z, w / 2, d / 2, s.a))
				return s.a, x, z
			end
		end
	end
	warn(b, "no hay lugar en el lobby para " .. name)
	return nil, 0, 0
end

-- Bases ------------------------------------------------------------------------------------------------

type PlotLayout = { size: number, slotRows: number, tileRows: number, perSide: number }

-- Tamaño de cada base según lo que lleva adentro (cuadrada, mínimo 56).
local function plotLayout(recipe: Types.KitConfig): PlotLayout
	local plots = recipe.plots :: Types.PlotsConfig
	local slotRows = math.ceil(plots.maxSlots / COLUMNS)
	local tiles = if recipe.garden then recipe.garden.maxTiles else 0
	local tileRows = math.ceil(tiles / COLUMNS)
	local buildings = if recipe.tycoon then #recipe.tycoon.buildings else 0
	local perSide = math.ceil(buildings / 2)
	-- Fondo: espacios y parcelas; adelante, 24 libres para entrar, cobrar y trabar.
	local depth = 6 + slotRows * CELL + (if tileRows > 0 then 4 + tileRows * CELL else 0) + 24
	depth = math.max(depth, 6 + perSide * 13 + 24)
	-- Ancho: la grilla de 4 y, con tycoon, a cada lado un botón y su edificio.
	local width = COLUMNS * CELL + 12 + (if buildings > 0 then 30 else 0)
	local size = math.max(56, depth, width)
	return { size = math.ceil(size / 2) * 2, slotRows = slotRows, tileRows = tileRows, perSide = perSide }
end
MapPlan.plotLayout = plotLayout

-- Base de un jugador (KitPlot). `side`: 1 si la entrada mira a +X, −1 si a −X. Coordenadas locales: u
-- de atrás (−half) hacia la entrada (+half), w a lo largo de la avenida. `style`: "pen" o "building".
local function plot(b: Builder, recipe: Types.KitConfig, index: number, cx: number, cz: number, side: number, layout: PlotLayout, style: string)
	local plots = recipe.plots :: Types.PlotsConfig
	local palette = b.plan.palette
	local accent = ACCENTS[(index - 1) % #ACCENTS + 1]
	local size = layout.size
	local half = size / 2
	local g = group(b, "Plot" .. index, "Plots", true, { "KitPlot" }, { Order = index })
	local function at(u: number, w: number): (number, number)
		return cx + side * u, cz + w
	end
	local function hold(name: string, solid: boolean, u: number, w: number, hu: number, hw: number)
		local x, z = at(u, w)
		reserve(b, "Plot" .. index .. "." .. name, "piece", solid, x, z, hu, hw)
	end
	reserve(b, "Plot" .. index, "area", true, cx, cz, half + 1, half + 1)
	local fx, fz = at(0, 0)
	part(b, { name = "Floor", group = g, size = v(size, 1, size), pos = v(fx, 0.5, fz), color = palette.path, material = "Plastic", studs = true })
	part(b, { name = "Trim", group = g, size = v(size + 2, 0.6, size + 2), pos = v(fx, 0.3, fz), color = accent, material = "Plastic", studs = true })
	if style == "building" then
		-- Paredes altas del color de la base, franja de vidrio y borde blanco arriba; abierta adelante.
		local height = 12
		local walls: { { u: number, w: number, su: number, sw: number } } = {
			{ u = -half, w = 0, su = 1.5, sw = size },
			{ u = 0, w = half, su = size, sw = 1.5 },
			{ u = 0, w = -half, su = size, sw = 1.5 },
			{ u = half, w = (half + 8) / 2, su = 1.5, sw = half - 8 },
			{ u = half, w = -(half + 8) / 2, su = 1.5, sw = half - 8 },
		}
		for _, wall in walls do
			local wx, wz = at(wall.u, wall.w)
			local sx, sz = wall.su, wall.sw -- u corre por X y w por Z, de los dos lados de la avenida
			part(b, { name = "Wall", group = g, size = v(sx, height, sz), pos = v(wx, 1 + height / 2, wz), color = accent, material = "Plastic", studs = true })
			part(b, { name = "WallTop", group = g, size = v(sx + 0.6, 0.8, sz + 0.6), pos = v(wx, 1 + height + 0.4, wz), color = "#FFFFFF", material = "SmoothPlastic" })
			part(b, { name = "Window", group = g, size = v(sx + 0.3, 3, sz + 0.3), pos = v(wx, 8.5, wz), color = "#9FE3FF", material = "Glass", transparency = 0.2 })
		end
	else
		-- Corral: postes blancos y travesaños del color de la base, abierto adelante (16).
		local corners = {
			{ -half, -half, -half, half }, -- atrás
			{ -half, half, half, half }, -- costado
			{ -half, -half, half, -half }, -- costado
			{ half, half, half, 8 }, -- adelante
			{ half, -half, half, -8 },
		}
		for _, c in corners do
			local x0, z0 = at(c[1], c[2])
			local x1, z1 = at(c[3], c[4])
			fence(b, g, x0, z0, x1, z1, accent, "#FFFFFF", 1)
		end
	end
	-- Entrada: láser de la traba (lo prende el servidor), postes y cartel del dueño; adentro, un paso libre.
	local lx, lz = at(half, 0)
	local signY = if style == "building" then 15.5 else 12.5
	part(b, { name = "Barrier", group = g, size = v(1, 9, 16), pos = v(lx, 5.5, lz), color = "#FF3B4F", material = "Neon", transparency = 1, collide = false, tags = { "KitBarrier" } })
	for _, s in { -1, 1 } do
		local px, pz = at(half, s * 8.5)
		part(b, { name = "SignPost", group = g, size = v(1, signY, 1), pos = v(px, signY / 2, pz), color = "#FFFFFF", material = "SmoothPlastic" })
		hold("SignPost" .. s, true, half, s * 8.5, 0.5, 0.5)
	end
	part(b, { name = "Sign", group = g, size = v(1, 3.5, 18), pos = v(lx, signY + 1, lz), color = WOOD, material = "WoodPlanks" })
	local ux, uz = at(half - 12, 0)
	reserve(b, "Plot" .. index .. ".Entry", "corridor", false, ux, uz, 12, 7)
	-- Placa de cobro (verde con borde blanco), traba y reaparecer, cerca de la entrada.
	local cxp, czp = at(half - 7, half - 9)
	part(b, { name = "CollectBorder", group = g, size = v(9, 0.3, 9), pos = v(cxp, 1.1, czp), color = "#FFFFFF", material = "SmoothPlastic" })
	part(b, { name = "CollectPad", group = g, size = v(8, 0.4, 8), pos = v(cxp, 1.25, czp), color = "#46D64B", material = "Neon", transparency = 0.05, tags = { "KitCollectPad" } })
	hold("CollectPad", false, half - 7, half - 9, 4.5, 4.5)
	if plots.lock then
		local kx, kz = at(half - 7, -(half - 9))
		pad(b, g, "LockButton", 5, kx, kz, "#2EC5F5", { "KitLockButton" }, nil, 1)
		hold("LockButton", false, half - 7, -(half - 9), 2.5, 2.5)
	end
	local sx, sz = at(half - 14, 0)
	part(b, { name = "Spawn", group = g, size = v(4, 1, 4), pos = v(sx, 1.5, sz), color = "#FFFFFF", transparency = 1, collide = false, tags = { "KitSpawn" } })
	-- Pedestales para las unidades, al fondo, de a 4 por fila (el de arriba es el espacio).
	for i = 1, plots.maxSlots do
		local row = (i - 1) // COLUMNS
		local col = (i - 1) % COLUMNS
		local u = -half + 9.5 + row * CELL
		local w = (col - (COLUMNS - 1) / 2) * CELL
		local x, z = at(u, w)
		part(b, { name = "Pedestal", group = g, size = v(7.6, 0.8, 7.6), pos = v(x, 1.4, z), color = accent, material = "SmoothPlastic" })
		part(b, { name = "Slot" .. i, group = g, size = v(7, 0.4, 7), pos = v(x, 2, z), color = "#FFFFFF", material = "SmoothPlastic", tags = { "KitSlot" }, attrs = { Index = i } })
		hold("Slot" .. i, false, u, w, 3.8, 3.8)
	end
	if plots.slotPrices and #plots.slotPrices > 0 then
		local ox, oz = at(-half + 2, 0)
		part(b, { name = "SlotShop", group = g, size = v(1, 5, 4), pos = v(ox, 3.5, oz), color = "#FFD23A", material = "SmoothPlastic", tags = { "KitSlotShop" } })
		hold("SlotShop", true, -half + 2, 0, 0.5, 2)
	end
	-- Parcelas del cultivo, delante de los espacios.
	local garden = recipe.garden
	if garden then
		local u0 = -half + 6 + layout.slotRows * CELL + 4
		for i = 1, garden.maxTiles do
			local row = (i - 1) // COLUMNS
			local col = (i - 1) % COLUMNS
			local u = u0 + 4 + row * CELL
			local w = (col - (COLUMNS - 1) / 2) * CELL
			local x, z = at(u, w)
			part(b, { name = "Tile" .. i, group = g, size = v(8, 1, 8), pos = v(x, 1.1, z), color = "#8A5A2B", material = "Ground", tags = { "KitGardenTile" }, attrs = { Index = i } })
			hold("Tile" .. i, false, u, w, 4, 4)
		end
	end
	-- Tycoon: cada edificio a un costado, con su botón entre el edificio y la grilla.
	local tycoon = recipe.tycoon
	if tycoon then
		for i, building in tycoon.buildings do
			local s = if i % 2 == 1 then 1 else -1
			local u = -half + 8 + ((i - 1) // 2) * 13
			local wb = s * (half - 7.5)
			local wp = s * (half - 17)
			local bx2, bz2 = at(u, wp)
			pad(b, g, "Button_" .. building.id, 4, bx2, bz2, "#46D64B", { "KitTycoonButton" }, { Building = building.id }, 1)
			hold("Button_" .. building.id, false, u, wp, 2, 2)
			local hx, hz = at(u, wb)
			local house = group(b, "Building_" .. building.id, g, true, { "KitBuilding" }, { Building = building.id })
			local color = ACCENTS[(i + index) % #ACCENTS + 1]
			part(b, { name = "Walls", group = house, size = v(9, 7, 9), pos = v(hx, 4.5, hz), color = "#FFFFFF", material = "Plastic", studs = true })
			part(b, { name = "Door", group = house, size = v(0.4, 4, 3), pos = v(hx + side * 4.6, 3, hz), color = WOOD, material = "WoodPlanks" })
			part(b, { name = "Roof", group = house, shape = "Wedge", size = v(10, 4, 5), pos = v(hx, 10, hz - 2.5), color = color, material = "SmoothPlastic" })
			part(b, { name = "Roof", group = house, shape = "Wedge", size = v(10, 4, 5), pos = v(hx, 10, hz + 2.5), rotY = 180, color = color, material = "SmoothPlastic" })
			hold("Building_" .. building.id, true, u, wb, 4.7, 4.5)
		end
	end
end

-- Zonas ------------------------------------------------------------------------------------------------

type Zone = { id: string?, name: string, cx: number, palette: Palette }
type Lot = { name: string, cx: number, cz: number, hx: number, hz: number }

-- Cuatro lotes por isla (al norte y al sur del camino); cada cosa prefiere uno.
local LOT_ORDER: { [string]: { string } } = {
	treadmills = { "NW", "SW", "NE", "SE" },
	fishing = { "NE", "SE", "NW", "SW" },
	search = { "SE", "NE", "SW", "NW" },
	wild = { "SW", "NW", "SE", "NE" },
}

local function takeLot(lots: { [string]: Lot }, order: { string }): Lot?
	for _, name in order do
		local lot = lots[name]
		if lot then
			lots[name] = nil
			return lot
		end
	end
	return nil
end

local function fill(b: Builder, recipe: Types.KitConfig, zone: Zone, first: boolean, index: number)
	local id = zone.id
	local attrs: Attrs? = nil
	if id then
		attrs = { Zone = id }
	end
	local g = group(b, "Zone_" .. (id or "Main"), "Zones", false, nil, attrs)
	local palette = zone.palette
	local cx = zone.cx
	local half = ISLAND / 2
	ground(b, "Island_" .. (id or "Main"), g, palette, cx, 0, half, half)
	reserve(b, "Island_" .. (id or "Main"), "area", true, cx, 0, half, half)
	path(b, "Path", g, palette.path, cx - half, cx + half, -7, 7)
	-- Cerco de madera por el borde, abierto donde llega el camino.
	local e = half - 1.5
	fence(b, g, cx - e, e, cx + e, e, palette.fence, palette.fence, 0)
	fence(b, g, cx - e, -e, cx + e, -e, palette.fence, palette.fence, 0)
	for _, sx in { -1, 1 } do
		fence(b, g, cx + sx * e, -e, cx + sx * e, -9, palette.fence, palette.fence, 0)
		fence(b, g, cx + sx * e, 9, cx + sx * e, e, palette.fence, palette.fence, 0)
	end
	if id then
		-- Región de la zona: su cara de abajo es el piso de la isla (ahí llega el teletransporte).
		part(b, { name = "Region", group = g, size = v(ISLAND, 80, ISLAND), pos = v(cx, 40, 0), color = "#FFFFFF", transparency = 1, collide = false, tags = { "KitZone" }, attrs = { Zone = id } })
		-- Arco de la entrada con el nombre de la zona.
		local arch = group(b, "ZoneArch_" .. id, g, true, { "HitSign" }, signAttrs(string.upper(zone.name), SIGN_VARIANTS[(index - 1) % #SIGN_VARIANTS + 1], "map", 18))
		local ax = cx - half + 5
		part(b, { name = "Beam", group = arch, size = v(2.4, 2.4, 22), pos = v(ax, 16, 0), color = palette.fence, material = "WoodPlanks" })
		for _, s in { -1, 1 } do
			part(b, { name = "Pillar", group = arch, size = v(2.4, 16, 2.4), pos = v(ax, 8, s * 10), color = palette.fence, material = "WoodPlanks" })
			reserve(b, "ZoneArch_" .. id, "piece", true, ax, s * 10, 1.2, 1.2)
		end
	end
	local function belongs(z: string?): boolean
		return z == zone.id or (first and z == nil)
	end
	local lots: { [string]: Lot } = {
		NW = { name = "NW", cx = cx - 37, cz = 49, hx = 35, hz = 23 },
		NE = { name = "NE", cx = cx + 37, cz = 49, hx = 35, hz = 23 },
		SE = { name = "SE", cx = cx + 37, cz = -49, hx = 35, hz = 23 },
		SW = { name = "SW", cx = cx - 37, cz = -49, hx = 35, hz = 23 },
	}
	local function lotFor(kind: string, what: string): Lot?
		local lot = takeLot(lots, LOT_ORDER[kind])
		if lot then
			reserve(b, (id or "Main") .. "." .. what, "piece", false, lot.cx, lot.cz, lot.hx, lot.hz)
		else
			warn(b, "no hay lote libre en la zona " .. (id or "Main") .. " para " .. what)
		end
		return lot
	end
	-- Estaciones de tiradas junto al camino, de a dos (una a cada lado), desde la entrada.
	local rolls = recipe.rolls
	if rolls then
		local k = 0
		for _, def in rolls.list do
			if belongs(def.zone) then
				local col = k // 2
				local s = if k % 2 == 0 then 1 else -1
				local x = cx - half + 25 + col * 18
				local z = s * 17
				local st = group(b, "Roll_" .. def.id, g, true, { "KitRollStation" }, { Roll = def.id })
				part(b, { name = "Pedestal", group = st, shape = "Cylinder", size = v(3, 10, 10), pos = v(x, 1.5, z), rotZ = 90, color = "#FFFFFF", material = "SmoothPlastic" })
				part(b, { name = "Rim", group = st, shape = "Cylinder", size = v(0.6, 11, 11), pos = v(x, 3.1, z), rotZ = 90, color = "#FFD23A", material = "SmoothPlastic" })
				part(b, { name = "Egg", group = st, mesh = "Sphere", size = v(7, 9, 7), pos = v(x, 7.9, z), color = ACCENTS[(k + index) % #ACCENTS + 1], material = "SmoothPlastic" })
				part(b, { name = "Spots", group = st, mesh = "Sphere", size = v(7.3, 2.2, 7.3), pos = v(x, 8.6, z), color = "#FFFFFF", material = "SmoothPlastic" })
				reserve(b, "Roll_" .. def.id, "piece", true, x, z, 5.5, 5.5)
				k += 1
			end
		end
	end
	-- Cintas de correr, con la ganancia de esta zona, bajo una carpa.
	local treadmills = recipe.map and recipe.map.treadmills
	if treadmills then
		local lot = lotFor("treadmills", "Treadmills")
		if lot then
			local gain = treadmills.gains[math.min(index, #treadmills.gains)] or 1
			for k = 0, 2 do
				local x = lot.cx - 14 + k * 14
				part(b, { name = "Treadmill", group = g, size = v(8, 1, 14), pos = v(x, 0.5, lot.cz), color = "#2D2F3A", material = "DiamondPlate", tags = { "KitTreadmill", "HitSign" }, attrs = { Stat = treadmills.stat, Gain = gain, Text = "+" .. tostring(gain), Variant = "Info", Icon = "treadmill", Width = 7 } })
				part(b, { name = "Rail", group = g, size = v(8, 4, 1), pos = v(x, 2.5, lot.cz + 7.5), color = "#9AA0AD", material = "Metal" })
			end
			part(b, { name = "Tent", group = g, size = v(46, 1, 22), pos = v(lot.cx, 13, lot.cz), color = "#FFFFFF", material = "SmoothPlastic" })
			for _, px in { -22, 22 } do
				for _, pz in { -10, 10 } do
					part(b, { name = "TentPole", group = g, size = v(1, 12.5, 1), pos = v(lot.cx + px, 6.25, lot.cz + pz), color = "#3A3E4A", material = "Metal" })
				end
			end
		end
	end
	-- Agua de pesca: un lote por estanque, con muelle de tablas desde el camino.
	local fishing = recipe.fishing
	if fishing then
		for _, pool in fishing.pools do
			if belongs(pool.zone) then
				local lot = lotFor("fishing", "Water_" .. pool.id)
				if lot then
					local s = if lot.cz > 0 then 1 else -1
					part(b, { name = "Shore", group = g, shape = "Cylinder", size = v(0.6, 44, 44), pos = v(lot.cx, 0.3, lot.cz), rotZ = 90, color = MapPlan.THEMES.beach.ground, material = "Sand" })
					part(b, { name = "Water_" .. pool.id, group = g, shape = "Cylinder", size = v(0.8, 38, 38), pos = v(lot.cx, 0.4, lot.cz), rotZ = 90, color = palette.water, material = "Glass", transparency = 0.25, collide = false, tags = { "KitWater" }, attrs = { Pool = pool.id } })
					part(b, { name = "Pier", group = g, size = v(6, 0.8, 20), pos = v(lot.cx, 1.2, s * 34), color = WOOD, material = "WoodPlanks" })
					for _, px in { -2.6, 2.6 } do
						for _, pz in { 27, 41 } do
							part(b, { name = "PierPost", group = g, shape = "Cylinder", size = v(3.4, 0.8, 0.8), pos = v(lot.cx + px, 0.9, s * pz), rotZ = 90, color = WOOD_DARK, material = "Wood" })
						end
					end
				end
			end
		end
	end
	-- Pilas para revolver: dos por lote.
	local search = recipe.search
	if search then
		local mine: { Types.Pile } = {}
		for _, pile in search.piles do
			if belongs(pile.zone) then
				table.insert(mine, pile)
			end
		end
		local i = 1
		while i <= #mine do
			local lot = lotFor("search", "Piles" .. i)
			if not lot then
				break
			end
			local count = math.min(2, #mine - i + 1)
			for k = 0, count - 1 do
				local pile = mine[i + k]
				local x = if count == 1 then lot.cx else lot.cx + (k * 2 - 1) * 17
				-- Domo: esfera hundida, sobresale 7 y ocupa un círculo de 22 en el piso.
				part(b, { name = "Pile_" .. pile.id, group = g, shape = "Ball", size = v(24, 24, 24), pos = v(x, -5, lot.cz), color = "#E8C15A", material = "Sand", tags = { "KitPile" }, attrs = { Pile = pile.id } })
			end
			i += count
		end
		if first then
			pad(b, g, "Deposit", 8, cx + half - 17, -17, "#46D64B", { "KitDepositPad" })
			reserve(b, "Deposit", "piece", false, cx + half - 17, -17, 4, 4)
		end
	end
	-- Áreas de salvajes: un pasto con cerco por grupo, abierto hacia el camino.
	local wild = recipe.wild
	if wild then
		for i, spawnDef in wild.spawns do
			if belongs(spawnDef.zone) then
				local lot = lotFor("wild", "WildArea" .. i)
				if lot then
					part(b, { name = "WildArea" .. i, group = g, size = v(lot.hx * 2 - 6, 0.4, lot.hz * 2 - 6), pos = v(lot.cx, 0.25, lot.cz), color = palette.edge, material = "Grass", tags = { "KitWildSpawn" }, attrs = { Pool = i, Zone = spawnDef.zone or "" } })
					local x0, x1 = lot.cx - lot.hx + 1, lot.cx + lot.hx - 1
					local near = if lot.cz > 0 then lot.cz - lot.hz + 1 else lot.cz + lot.hz - 1
					local far = if lot.cz > 0 then lot.cz + lot.hz - 1 else lot.cz - lot.hz + 1
					fence(b, g, x0, far, x1, far, palette.fence, palette.fence, 0)
					fence(b, g, x0, near, x0, far, palette.fence, palette.fence, 0)
					fence(b, g, x1, near, x1, far, palette.fence, palette.fence, 0)
					fence(b, g, x0, near, lot.cx - 8, near, palette.fence, palette.fence, 0)
					fence(b, g, lot.cx + 8, near, x1, near, palette.fence, palette.fence, 0)
				end
			end
		end
	end
	ring(b, g, palette, cx, 0, half, half, -10, 22)
end

-- Plan completo --------------------------------------------------------------------------------------

-- Las ventanas que piden los bloques activos, si la receta no dice `map.shops`.
function MapPlan.shops(recipe: Types.KitConfig): { string }
	local map = recipe.map
	if map and map.shops then
		return map.shops
	end
	local out = { "Shop" }
	if recipe.sell then
		table.insert(out, "Sell")
	end
	if recipe.upgrades then
		table.insert(out, "Upgrades")
	end
	if recipe.garden then
		table.insert(out, "Seeds")
	end
	if recipe.fishing and #recipe.fishing.rods > 1 then
		table.insert(out, "Rods")
	end
	if recipe.search and #recipe.search.tools > 1 then
		table.insert(out, "Tools")
	end
	return out
end

local SHOP_STYLE: { [string]: { label: string, icon: string, color: string } } = {
	Shop = { label = "Shop", icon = "shop", color = "#46D64B" },
	Sell = { label = "Sell", icon = "cash", color = "#FF3B4F" },
	Upgrades = { label = "Upgrades", icon = "boost", color = "#FF9F1A" },
	Seeds = { label = "Seeds", icon = "seed", color = "#46D64B" },
	Rods = { label = "Rods", icon = "fishing", color = "#2EC5F5" },
	Tools = { label = "Tools", icon = "pickaxe", color = "#FF9F1A" },
	Index = { label = "Index", icon = "index", color = "#2EC5F5" },
	Spin = { label = "Spin", icon = "spin", color = "#FF5C8A" },
	Robux = { label = "Robux", icon = "robux", color = "#46D64B" },
}

-- Islas de zonas en orden (sin zonas: un área de actividades si algún bloque la necesita).
local function zoneList(recipe: Types.KitConfig, palette: Palette): { Zone }
	local out: { Zone } = {}
	local zones = recipe.zones
	local map = recipe.map
	local needsArea = recipe.rolls ~= nil or recipe.fishing ~= nil or recipe.search ~= nil or recipe.wild ~= nil or (map ~= nil and map.treadmills ~= nil)
	if zones and #zones.list > 0 then
		local ordered = table.clone(zones.list)
		table.sort(ordered, function(a, c)
			return a.order < c.order
		end)
		for i, z in ordered do
			local biome = MapPlan.biome(z.name)
			table.insert(out, { id = z.id, name = z.name, cx = FIRST_ISLAND_X + (i - 1) * ISLAND_STEP, palette = if biome then MapPlan.THEMES[biome] else palette })
		end
	elseif needsArea then
		table.insert(out, { id = nil, name = "Main", cx = FIRST_ISLAND_X, palette = palette })
	end
	return out
end

-- La unidad de la vitrina: la que dice `map.showcase`, o la última de la lista ("" = ninguna).
function MapPlan.showcase(recipe: Types.KitConfig): string?
	local units = recipe.units
	local map = recipe.map
	local wanted = if map then map.showcase else nil
	if not units or #units.list == 0 or wanted == "" then
		return nil
	end
	if wanted then
		for _, u in units.list do
			if u.id == wanted then
				return wanted
			end
		end
		return nil
	end
	return units.list[#units.list].id
end

-- Lo de alrededor: lo que pide la receta o, si no, mar en los temas de agua y cerros en los demás.
local function backdropOf(recipe: Types.KitConfig, theme: string): string
	local map = recipe.map
	if map and map.backdrop then
		return map.backdrop
	end
	if theme == "beach" or theme == "underwater" or recipe.fishing then
		return "ocean"
	end
	return "hills"
end

function MapPlan.build(recipe: Types.KitConfig): Plan
	local map = recipe.map
	local theme = if map then map.theme else "meadow"
	local b = newBuilder(theme, seedOf(recipe.name))
	local palette = b.plan.palette
	group(b, "Lobby", "Map")
	local plots = recipe.plots
	local layout = if plots then plotLayout(recipe) else nil
	local zones = zoneList(recipe, palette)

	-- Piso del lobby, plaza con un anillo de color, spawn y los cuatro pasos en cruz.
	local lobbyCx, lobbyCz = (LOBBY.x0 + LOBBY.x1) / 2, (LOBBY.z0 + LOBBY.z1) / 2
	ground(b, "Ground", "Lobby", palette, lobbyCx, lobbyCz, (LOBBY.x1 - LOBBY.x0) / 2, (LOBBY.z1 - LOBBY.z0) / 2)
	part(b, { name = "PlazaRing", group = "Lobby", shape = "Cylinder", size = v(0.3, PLAZA_RADIUS * 2 + 6, PLAZA_RADIUS * 2 + 6), pos = v(0, 0.15, 0), rotZ = 90, color = palette.edge, material = "Plastic" })
	part(b, { name = "Plaza", group = "Lobby", shape = "Cylinder", size = v(0.4, PLAZA_RADIUS * 2, PLAZA_RADIUS * 2), pos = v(0, 0.2, 0), rotZ = 90, color = palette.path, material = "Plastic" })
	part(b, { name = "PlazaInner", group = "Lobby", shape = "Cylinder", size = v(0.45, 60, 60), pos = v(0, 0.22, 0), rotZ = 90, color = ACCENTS[3], material = "Plastic" })
	part(b, { name = "PlazaCenter", group = "Lobby", shape = "Cylinder", size = v(0.5, 54, 54), pos = v(0, 0.25, 0), rotZ = 90, color = palette.path, material = "Plastic" })
	part(b, { name = "Spawn", group = "Lobby", size = v(12, 1, 12), pos = v(0, 0.9, 0), color = "#FFFFFF", material = "SmoothPlastic", spawn = true })
	reserve(b, "Spawn", "piece", false, 0, 0, 6, 6)
	local r = PLAZA_RADIUS - 2
	path(b, "PathNorth", "Lobby", palette.path, -9, 9, r, if plots then PLOTS_Z else LOBBY.z1)
	path(b, "PathSouth", "Lobby", palette.path, -9, 9, SOUTH_ROW_Z + 10, -r)
	path(b, "PathEast", "Lobby", palette.path, r, LOBBY.x1, -9, 9)
	path(b, "PathWest", "Lobby", palette.path, LOBBY.x0, -r, -9, 9)
	-- Los pasos siguen sobre la plaza (sin pintar) hasta el spawn.
	reserve(b, "CrossNS", "corridor", false, 0, 0, 9, r)
	reserve(b, "CrossEW", "corridor", false, 0, 0, r, 9)

	-- Teletransportes a cada zona (salvo la primera), a los costados del paso del este.
	local spots = { { 50, 18 }, { 50, -18 }, { 60, 18 }, { 60, -18 }, { 70, 18 }, { 70, -18 }, { 50, 28 }, { 50, -28 }, { 60, 28 }, { 60, -28 }, { 70, 28 }, { 70, -28 } }
	for i = 2, #zones do
		local zone = zones[i]
		local spot = spots[i - 1]
		if zone.id and spot then
			pad(b, "Lobby", "Teleport_" .. zone.id, 7, spot[1], spot[2], "#2EE0C8", { "KitTeleport" }, { Zone = zone.id })
			reserve(b, "Teleport_" .. zone.id, "piece", false, spot[1], spot[2], 3.5, 3.5)
		elseif zone.id then
			warn(b, "no hay lugar para el teletransporte a " .. zone.id)
		end
	end

	-- Vitrina: la unidad más rara, gigante, en un pedestal dorado al lado del spawn (Map/Showcase la pone).
	local showcase = MapPlan.showcase(recipe)
	if showcase then
		local sx, sz = math.sin(math.rad(SHOWCASE.a)) * SHOWCASE.r, math.cos(math.rad(SHOWCASE.a)) * SHOWCASE.r
		local g = group(b, "Showcase", "Lobby", true, { "KitShowcase" }, { Unit = showcase })
		part(b, { name = "Top", group = g, shape = "Cylinder", size = v(0.6, 10.4, 10.4), pos = v(sx, 4.3, sz), rotZ = 90, color = "#FFFFFF", material = "SmoothPlastic" })
		part(b, { name = "Pedestal", group = g, shape = "Cylinder", size = v(4, 11, 11), pos = v(sx, 2, sz), rotZ = 90, color = "#FFD23A", material = "SmoothPlastic" })
		part(b, { name = "Glow", group = g, shape = "Cylinder", size = v(0.2, 15, 15), pos = v(sx, 0.5, sz), rotZ = 90, color = "#FFD23A", material = "Neon", transparency = 0.4, collide = false })
		reserve(b, "Showcase", "piece", true, sx, sz, 6, 6)
	end

	-- Arco con el cartel de la próxima actualización sobre el paso del sur.
	if map and map.nextUpdate then
		local g = group(b, "NextUpdate", "Lobby", true, { "HitSign" }, signAttrs("NEXT UPDATE: " .. map.nextUpdate, "Pink", "timer", 20))
		part(b, { name = "Beam", group = g, size = v(26, 2, 2), pos = v(0, 15, ARCH_Z), color = "#FF5C8A", material = "SmoothPlastic" })
		for _, s in { -1, 1 } do
			part(b, { name = "Post", group = g, size = v(2, 15, 2), pos = v(s * 12, 7.5, ARCH_Z), color = "#FFFFFF", material = "SmoothPlastic" })
			reserve(b, "ArchPost", "piece", true, s * 12, ARCH_Z, 1, 1)
		end
	end

	-- Faroles a los dos lados de los pasos, afuera de la plaza.
	for _, s in { -1, 1 } do
		for _, z in { 58, 78 } do
			lamp(b, "Lobby", s * 12, z)
		end
		for _, z in { -66, -82 } do
			lamp(b, "Lobby", s * 12, z)
		end
		for _, x in { 56, 74 } do
			lamp(b, "Lobby", x, s * 12)
			lamp(b, "Lobby", -x, s * 12)
		end
	end

	-- Fila del sur: lo que se pisa o usa.
	local south: { (x: number) -> () } = {}
	if recipe.sell then
		table.insert(south, function(x)
			local g = group(b, "SellPad", "Lobby", true, nil, nil)
			pad(b, g, "Pad", 10, x, SOUTH_ROW_Z, "#FFD23A", { "KitSellPad" })
			reserve(b, "SellPad", "piece", false, x, SOUTH_ROW_Z, 5, 5)
		end)
	end
	if recipe.upgrades then
		table.insert(south, function(x)
			local g = group(b, "UpgradeStation", "Lobby", true, { "KitUpgradeStation" }, nil)
			part(b, { name = "Machine", group = g, size = v(8, 8, 6), pos = v(x, 4, SOUTH_ROW_Z), color = "#FF9F1A", material = "Plastic", studs = true })
			part(b, { name = "Screen", group = g, size = v(6, 3, 0.4), pos = v(x, 5.5, SOUTH_ROW_Z + 3.1), color = "#2EC5F5", material = "Neon" })
			part(b, { name = "Glow", group = g, shape = "Cylinder", size = v(0.2, 9, 9), pos = v(x, 0.5, SOUTH_ROW_Z + 7.5), rotZ = 90, color = "#FFD23A", material = "Neon", transparency = 0.35, collide = false })
			reserve(b, "UpgradeStation", "piece", true, x, SOUTH_ROW_Z, 4, 3.3)
		end)
	end
	if recipe.merge then
		table.insert(south, function(x)
			-- Máquina de fusión de bloques de colores, como la de Steal An Egg.
			local g = group(b, "MergeMachine", "Lobby", true, { "KitMergeMachine" }, nil)
			part(b, { name = "Base", group = g, size = v(12, 2, 10), pos = v(x, 1, SOUTH_ROW_Z), color = "#2D2F3A", material = "Plastic", studs = true })
			for k = 0, 5 do
				local bx = x - 4 + (k % 3) * 4
				local by = 3.5 + (k // 3) * 3
				part(b, { name = "Block", group = g, size = v(3, 3, 3), pos = v(bx, by, SOUTH_ROW_Z - 2), color = ACCENTS[k + 1], material = "Plastic", studs = true })
			end
			part(b, { name = "Orb", group = g, shape = "Ball", size = v(5, 5, 5), pos = v(x, 10.5, SOUTH_ROW_Z - 2), color = "#FF5CE1", material = "Neon", transparency = 0.2 })
			reserve(b, "MergeMachine", "piece", true, x, SOUTH_ROW_Z, 6, 5)
		end)
	end
	for i, place in south do
		place((i - (#south + 1) / 2) * 24)
	end

	-- Puestos, tablas, ruleta y cofre: cada uno en el primer lugar libre, mirando al centro.
	local taken: { [number]: boolean } = {}
	local shops = MapPlan.shops(recipe)
	for i, window in shops do
		local style = SHOP_STYLE[window] or { label = window, icon = "shop", color = ACCENTS[(i - 1) % #ACCENTS + 1] }
		if window == "Spin" then
			local a, x, z = slot(b, taken, "Stand_Spin", 17, 6)
			if a then
				wheel(b, x, z, a)
			end
		else
			local a, x, z = slot(b, taken, "Stand_" .. window, 14, 11)
			if a then
				stand(b, "Lobby", window, style.label, style.icon, style.color, x, z, a + 180)
			end
		end
	end
	if map and map.leaderboard then
		local stats = recipe.leaderstats or { "Money" }
		for i = 1, math.min(2, #stats) do
			local a, x, z = slot(b, taken, "Board_" .. stats[i], 18, 4)
			if a then
				leaderboard(b, stats[i], x, z, a)
			end
		end
	end
	if map and map.spin and not table.find(shops, "Spin") then
		local a, x, z = slot(b, taken, "Stand_Spin", 17, 6)
		if a then
			wheel(b, x, z, a)
		end
	end
	if map and map.groupChest then
		local a, x, z = slot(b, taken, "GroupChest", 9, 9)
		if a then
			chest(b, x, z, a)
		end
	end

	-- Bases al norte, a los dos lados de la avenida, con la alfombra roja de la cinta en el medio.
	local plotsHalfWidth = 0
	if plots and layout then
		local size = layout.size
		group(b, "Plots", "Map")
		local rows = math.ceil(plots.count / 2)
		local length = rows * (size + PLOT_GAP) - PLOT_GAP
		plotsHalfWidth = AVENUE + size + 22
		local style = if map and map.bases then map.bases else "pen"
		ground(b, "PlotsGround", "Plots", palette, 0, PLOTS_Z + length / 2, plotsHalfWidth, length / 2 + 16)
		for i = 1, plots.count do
			local row = (i - 1) // 2
			local side = if i % 2 == 1 then 1 else -1
			local px = -side * (AVENUE + size / 2)
			local pz = PLOTS_Z + size / 2 + row * (size + PLOT_GAP)
			plot(b, recipe, i, px, pz, side, layout, style)
		end
		part(b, { name = "Avenue", group = "Plots", size = v(AVENUE * 2, 0.4, length + 24), pos = v(0, 0.2, PLOTS_Z + length / 2), color = palette.path, material = "Plastic", studs = true })
		if recipe.belt then
			-- Las unidades caminan por el eje X de la cinta: girada 90, de la punta norte hacia el lobby.
			part(b, { name = "Belt", group = "Plots", size = v(length, 0.6, 9), pos = v(0, 0.5, PLOTS_Z + length / 2), rotY = 90, color = "#E53935", material = "Plastic", studs = true, tags = { "KitBelt" } })
			for _, s in { -1, 1 } do
				part(b, { name = "BeltLine", group = "Plots", size = v(0.8, 0.5, length), pos = v(s * 4.9, 0.45, PLOTS_Z + length / 2), color = "#FFFFFF", material = "SmoothPlastic" })
			end
			-- Arco al principio de la cinta, donde aparecen las unidades.
			local endZ = PLOTS_Z + length + 4
			for _, s in { -1, 1 } do
				part(b, { name = "BeltArchPost", group = "Plots", size = v(2, 14, 2), pos = v(s * 7, 7, endZ), color = "#FFD23A", material = "SmoothPlastic" })
			end
			part(b, { name = "BeltArch", group = "Plots", size = v(16, 2.4, 2.4), pos = v(0, 15, endZ), color = "#FF3B4F", material = "SmoothPlastic" })
			part(b, { name = "BeltArchLight", group = "Plots", size = v(14, 0.6, 2.6), pos = v(0, 13.6, endZ), color = "#FFD23A", material = "Neon" })
			reserve(b, "Belt", "piece", true, 0, PLOTS_Z + length / 2, 5.5, length / 2)
			reserve(b, "BeltArch", "piece", true, 0, endZ, 8, 1.2)
			reserve(b, "AvenueWest", "corridor", false, -12, PLOTS_Z + length / 2, 5, length / 2)
			reserve(b, "AvenueEast", "corridor", false, 12, PLOTS_Z + length / 2, 5, length / 2)
		else
			reserve(b, "Avenue", "corridor", false, 0, PLOTS_Z + length / 2, AVENUE - 1, length / 2)
		end
		ring(b, "Plots", palette, 0, PLOTS_Z + length / 2, AVENUE + size, length / 2, 9, 24)
	end

	-- Zonas al este, en islas con puentes (y puertas entre una y otra).
	if #zones > 0 then
		group(b, "Zones", "Map")
		local half = ISLAND / 2
		local function bridge(x0: number, x1: number): number
			local cx = (x0 + x1) / 2
			part(b, { name = "Bridge", group = "Zones", size = v(x1 - x0, 2, 16), pos = v(cx, -1, 0), color = WOOD, material = "WoodPlanks" })
			for _, s in { -1, 1 } do
				part(b, { name = "Rail", group = "Zones", size = v(x1 - x0, 2.5, 1), pos = v(cx, 1.25, s * 8.5), color = WOOD_DARK, material = "Wood" })
			end
			floorAt(b, "Bridge", cx, 0, (x1 - x0) / 2, 8)
			reserve(b, "Bridge", "corridor", false, cx, 0, (x1 - x0) / 2, 8)
			return cx
		end
		bridge(LOBBY.x1 - 2, zones[1].cx - half + 2)
		for i, zone in zones do
			fill(b, recipe, zone, i == 1, i)
			if i > 1 then
				local x = bridge(zones[i - 1].cx + half - 2, zone.cx - half + 2)
				if zone.id then
					part(b, { name = "Gate_" .. zone.id, group = "Zones", size = v(2, 18, 18), pos = v(x, 9, 0), color = "#A35CFF", material = "ForceField", transparency = 0.15, tags = { "KitGate" }, attrs = { Zone = zone.id } })
				end
			end
		end
	end

	-- Etapas al oeste, sobre el vacío: huecos de 4 a 7 (se saltan caminando a 16) y escalones de 1,5.
	local stages = recipe.stages
	if stages then
		group(b, "Stages", "Map")
		pad(b, "Stages", "Start", 12, LOBBY.x0 + 10, 0, "#46D64B", { "KitStageStart" })
		reserve(b, "StageStart", "piece", false, LOBBY.x0 + 10, 0, 6, 6)
		local x = LOBBY.x0
		for i = 1, stages.count do
			local gap = 4 + 3 * (i - 1) / math.max(stages.count - 1, 1)
			local width = 20
			local top = ((i - 1) % 4) * 1.5
			x -= gap + width / 2
			part(b, { name = "Stage" .. i, group = "Stages", size = v(width, 2, 22), pos = v(x, top - 1, 0), color = ACCENTS[(i - 1) % #ACCENTS + 1], material = "Plastic", studs = true })
			floorAt(b, "Stage" .. i, x, 0, width / 2, 11)
			pad(b, "Stages", "Checkpoint" .. i, 6, x, 0, "#FFFFFF", { "KitCheckpoint" }, { Stage = i }, top)
			reserve(b, "Checkpoint" .. i, "piece", false, x, 0, 3, 3)
			x -= width / 2
		end
		local wx = x - 6 - 15
		part(b, { name = "WinPlatform", group = "Stages", size = v(30, 2, 30), pos = v(wx, -1, 0), color = "#FFD23A", material = "Plastic", studs = true })
		floorAt(b, "WinPlatform", wx, 0, 15, 15)
		pad(b, "Stages", "Win", 14, wx, 0, "#FFD23A", { "KitWinPad" })
		reserve(b, "WinPad", "piece", false, wx, 0, 7, 7)
	end

	-- Alrededor: cerros de fondo por los bordes de afuera (sin tapar puentes ni etapas) o mar.
	local backdrop = backdropOf(recipe, theme)
	if backdrop == "hills" then
		group(b, "Backdrop", "Map")
		local zGap = { { (-20 - LOBBY.z0), (20 - LOBBY.z0) } } -- el centro del borde (puente o etapas)
		ridge(b, "Backdrop", palette, LOBBY.x0, LOBBY.z0, LOBBY.x1, LOBBY.z0, 0, -1, nil)
		ridge(b, "Backdrop", palette, LOBBY.x0, LOBBY.z0, LOBBY.x0, LOBBY.z1, -1, 0, zGap)
		ridge(b, "Backdrop", palette, LOBBY.x1, LOBBY.z0, LOBBY.x1, LOBBY.z1, 1, 0, if #zones > 0 then zGap else nil)
		if plots and layout then
			local rows = math.ceil(plots.count / 2)
			local length = rows * (layout.size + PLOT_GAP) - PLOT_GAP
			local z0, z1 = PLOTS_Z - 16, PLOTS_Z + length + 16
			ridge(b, "Backdrop", palette, -plotsHalfWidth, z0, -plotsHalfWidth, z1, -1, 0, nil)
			ridge(b, "Backdrop", palette, plotsHalfWidth, z0, plotsHalfWidth, z1, 1, 0, nil)
			ridge(b, "Backdrop", palette, -plotsHalfWidth, z1, plotsHalfWidth, z1, 0, 1, nil)
		else
			ridge(b, "Backdrop", palette, LOBBY.x0, LOBBY.z1, LOBBY.x1, LOBBY.z1, 0, 1, nil)
		end
	elseif backdrop == "ocean" then
		-- Mar debajo de todo: quien se cae lo atraviesa y reaparece (no choca).
		part(b, { name = "Ocean", group = "Map", size = v(3000, 1, 3000), pos = v(600, -7, 0), color = palette.water, material = "Glass", transparency = 0.15, collide = false })
	end

	-- Decoración al final: alrededor de la plaza y por el borde del lobby, donde quede libre.
	for i = 1, 26 do
		local a = (i / 26) * math.pi * 2 + (b.random() - 0.5) * 0.2
		local rr = 60 + b.random() * 14
		decorLater(b, "Lobby", palette, math.sin(a) * rr, math.cos(a) * rr, 0.9 + b.random() * 0.4)
	end
	ring(b, "Lobby", palette, lobbyCx, lobbyCz, (LOBBY.x1 - LOBBY.x0) / 2, (LOBBY.z1 - LOBBY.z0) / 2, -9, 16)
	flushDecor(b)
	return b.plan
end

return MapPlan
