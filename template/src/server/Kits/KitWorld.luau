--!strict
-- Ayudas del mundo para los bloques del armador, en el servidor: encontrar partes por etiqueta (las que
-- están y las que aparezcan), leer sus atributos, poner carteles, crear ProximityPrompts y pads que se
-- pisan, y medir que el jugador esté cerca de verdad. La posición del personaje la manda su cliente:
-- cada acción se vuelve a medir acá, con un margen por la latencia.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local KitWorld = {}

local PROMPT_DISTANCE = 10
local SLACK = 8 -- studs de margen: el personaje sigue moviéndose mientras viaja el pedido
local TOUCH_COOLDOWN = 0.6
local PROMPT_COOLDOWN = 0.25
local SIGN_TAG = "HitSign" -- client/UI/World dibuja el cartel (atributos Text, Variant, Icon, Width)

export type PromptProps = {
	action: string, -- verbo en inglés: "Buy", "Steal", "Open"
	object: string?, -- arriba del verbo: "Common Egg", "$1.2K"
	hold: number?, -- segundos manteniendo apretado
	distance: number?,
	key: Enum.KeyCode?,
	name: string?, -- para encontrarlo después (varios prompts en la misma parte)
}

-- Llama `added` con cada instancia que tiene la etiqueta, ahora y cuando aparezca, y `removed` cuando se
-- va. Cada llamada corre en su propio hilo: un error en una parte no frena a las demás.
function KitWorld.tagged(tag: string, added: (Instance) -> (), removed: ((Instance) -> ())?)
	local seen: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	local function onAdded(instance: Instance)
		if seen[instance] then
			return
		end
		seen[instance] = true
		task.spawn(added, instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
		seen[instance] = nil
		if removed then
			task.spawn(removed, instance)
		end
	end)
	for _, instance in CollectionService:GetTagged(tag) do
		onAdded(instance)
	end
end

function KitWorld.text(instance: Instance, name: string): string?
	local value = instance:GetAttribute(name)
	return if typeof(value) == "string" and value ~= "" then value else nil
end

function KitWorld.number(instance: Instance, name: string): number?
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" and value == value then value else nil
end

-- El atributo en la instancia o en el primer antepasado que lo tenga ("Zone" de una parte dentro de
-- una zona).
function KitWorld.inherited(instance: Instance, name: string): any
	local current: Instance? = instance
	while current and current ~= game do
		local value = current:GetAttribute(name)
		if value ~= nil then
			return value
		end
		current = current.Parent
	end
	return nil
end

-- La parte que representa a la instancia: ella misma, la PrimaryPart de un modelo o su primera parte.
function KitWorld.part(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

function KitWorld.position(instance: Instance): Vector3?
	if instance:IsA("PVInstance") then
		return instance:GetPivot().Position
	end
	if instance:IsA("Attachment") then
		return instance.WorldPosition
	end
	return nil
end

-- El antepasado (o ella misma) con esa etiqueta: la base de un espacio, por ejemplo.
function KitWorld.ancestor(instance: Instance, tag: string): Instance?
	local current: Instance? = instance
	while current and current ~= game do
		if current:HasTag(tag) then
			return current
		end
		current = current.Parent
	end
	return nil
end

function KitWorld.humanoid(player: Player): Humanoid?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

function KitWorld.root(player: Player): BasePart?
	local humanoid = KitWorld.humanoid(player)
	return if humanoid then humanoid.RootPart else nil
end

-- ¿El personaje está a `range` studs (más el margen) de la instancia o el punto?
function KitWorld.near(player: Player, target: Instance | Vector3, range: number): boolean
	local root = KitWorld.root(player)
	if not root then
		return false
	end
	local position: Vector3?
	if typeof(target) == "Vector3" then
		position = target
	else
		position = KitWorld.position(target)
	end
	return position ~= nil and (root.Position - position).Magnitude <= range + SLACK
end

-- El jugador dueño del personaje al que pertenece la parte tocada.
function KitWorld.playerFromPart(hit: Instance): Player?
	local model = hit:FindFirstAncestorWhichIsA("Model")
	while model do
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end

-- Cartel estilo hit sobre la instancia (lo dibuja cada cliente). Cambiar el texto actualiza el cartel.
function KitWorld.sign(instance: Instance, text: string, variant: string?, icon: string?, width: number?)
	instance:SetAttribute("Text", text)
	instance:SetAttribute("Variant", variant)
	instance:SetAttribute("Icon", icon)
	instance:SetAttribute("Width", width)
	if not instance:HasTag(SIGN_TAG) then
		instance:AddTag(SIGN_TAG)
	end
end

-- ProximityPrompt en la parte de la instancia (o el mismo, si ya existe con ese nombre).
function KitWorld.prompt(instance: Instance, props: PromptProps): ProximityPrompt?
	local part = KitWorld.part(instance)
	if not part then
		warn("[KitWorld] " .. instance:GetFullName() .. " no tiene partes para el prompt " .. props.action)
		return nil
	end
	local name = props.name or "KitPrompt"
	local existing = part:FindFirstChild(name)
	local p: ProximityPrompt
	if existing and existing:IsA("ProximityPrompt") then
		p = existing
	else
		p = Instance.new("ProximityPrompt")
		p.Name = name
		p.RequiresLineOfSight = false
		p.Parent = part
	end
	p.ActionText = props.action
	p.ObjectText = props.object or ""
	p.HoldDuration = props.hold or 0
	p.MaxActivationDistance = props.distance or PROMPT_DISTANCE
	if props.key then
		p.KeyboardKeyCode = props.key
	end
	return p
end

-- Conecta el prompt: el servidor vuelve a medir la distancia y frena los disparos seguidos.
function KitWorld.onPrompt(prompt: ProximityPrompt, handler: (Player) -> (), cooldown: number?): RBXScriptConnection
	local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
	local wait = cooldown or PROMPT_COOLDOWN
	return prompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now - (last[player] or 0) < wait then
			return
		end
		local parent = prompt.Parent
		if not parent or not KitWorld.near(player, parent, prompt.MaxActivationDistance) then
			return
		end
		last[player] = now
		-- El cast deja leer el error: pcall de una función sin retorno solo tipa el booleano.
		local ok, err = pcall(handler :: (Player) -> ...any, player)
		if not ok then
			warn("[KitWorld] error en el prompt " .. prompt.ActionText .. ": " .. tostring(err))
		end
	end)
end

-- Pad que se pisa (cobrar, vender, depositar, ganar): llama `handler` una vez cada `cooldown` segundos
-- por jugador vivo que lo toca de verdad.
function KitWorld.onTouch(part: BasePart, handler: (Player) -> (), cooldown: number?): RBXScriptConnection
	local last: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any
	local wait = cooldown or TOUCH_COOLDOWN
	return part.Touched:Connect(function(hit: BasePart)
		local player = KitWorld.playerFromPart(hit)
		if not player or not KitWorld.humanoid(player) then
			return
		end
		local now = os.clock()
		if now - (last[player] or 0) < wait then
			return
		end
		if not KitWorld.near(player, part, part.Size.Magnitude / 2) then
			return
		end
		last[player] = now
		local ok, err = pcall(handler :: (Player) -> ...any, player)
		if not ok then
			warn("[KitWorld] error en el pad " .. part:GetFullName() .. ": " .. tostring(err))
		end
	end)
end

return KitWorld
