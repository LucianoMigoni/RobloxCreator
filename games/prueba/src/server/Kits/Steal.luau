--!strict
-- Bloque Steal del armador, hecho de cero: robar una unidad de otra base y llevarla a la propia, como
-- Steal a Brainrot.
-- - Cada unidad colocada (Plots.Shown) tiene un prompt "Steal" que se mantiene apretado.
-- - Mientras el ladrón la lleva, la unidad sigue en los datos de la víctima: él la ve sobre su cabeza
--   y camina más lento (carrySpeed); la víctima recibe el aviso y el modelo de su base queda marcado
--   (atributo "BeingStolen") para que el cliente lo muestre.
-- - Al entrar a su propia base, pasa a ser suya (Units.transfer) y se coloca si hay espacio.
-- - Si muere, se va, lo empujan (PushPlayer) o tarda más de TIMEOUT, vuelve todo como estaba.
-- - Protecciones (Lib/StealRules): base trabada, recién llegados, lo recién robado y, si la receta
--   quiere, lo mejor de cada base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local KitTypes = require(ReplicatedStorage.Shared.Kits.Types)
local UnitModel = require(ReplicatedStorage.Shared.Kits.UnitModel)
local StealRules = require(ReplicatedStorage.Shared.Lib.StealRules)
local DataService = require("../Data/DataService")
local ShopService = require("../Shop/ShopService")
local Remotes = require("../Net/Remotes")
local Validate = require("../Net/Validate")
local AnnounceService = require("../Social/AnnounceService")
local Signals = require("../Signals")
local KitFx = require("./KitFx")
local KitWorld = require("./KitWorld")
local Plots = require("./Plots")
local Units = require("./Units")

type Carry = {
	victim: Player,
	uid: number,
	startedAt: number,
	slotModel: Model?,
	visual: Model?,
	connections: { RBXScriptConnection },
}

local Steal = {}

local TIMEOUT = 90
local CHECK_EVERY = 0.25
local PUSH_COOLDOWN = 1.5
local PUSH_SPEED = 55 -- studs/s que sale despedido el empujado
local PROMPT_DISTANCE = 10
local SPEED_SOURCE = "Steal"

local config: KitTypes.StealConfig? = nil
local announceRank = 0
local joinedAt: { [Player]: number } = {}
local carrying: { [Player]: Carry } = {}
local stolenAt: { [string]: number } = {} -- "<userId>:<uid>" → cuándo llegó robada (protege al nuevo dueño)
local lastPush: { [Player]: number } = {}

local function key(player: Player, uid: number): string
	return player.UserId .. ":" .. uid
end

-- La unidad colocada que más paga en la base de ese jugador (empate: la más vieja).
local function best(owner: Player): number?
	local top: Units.Unit? = nil
	local topIncome = -1
	for _, unit in Units.list(owner) do
		if unit.slot then
			local income = Units.income(unit)
			if income > topIncome or (income == topIncome and top ~= nil and unit.uid < top.uid) then
				top = unit
				topIncome = income
			end
		end
	end
	return if top then top.uid else nil
end

-- ¿El punto está dentro de la caja de la base (con margen para arriba)?
local function inside(plot: Model, position: Vector3): boolean
	local box, size = plot:GetBoundingBox()
	local relative = box:PointToObjectSpace(position)
	return math.abs(relative.X) <= size.X / 2 and math.abs(relative.Z) <= size.Z / 2 and math.abs(relative.Y) <= size.Y / 2 + 10
end

local function finish(thief: Player, carry: Carry)
	carrying[thief] = nil
	for _, connection in carry.connections do
		connection:Disconnect()
	end
	local visual = carry.visual
	if visual then
		visual:Destroy()
	end
	local slotModel = carry.slotModel
	if slotModel and slotModel.Parent then
		slotModel:SetAttribute("BeingStolen", nil)
	end
	KitWorld.setSpeedFactor(thief, SPEED_SOURCE, nil)
end

-- Se cae lo que lleva: vuelve a la base de la víctima como estaba.
function Steal.drop(thief: Player, reason: string)
	local carry = carrying[thief]
	if not carry then
		return
	end
	finish(thief, carry)
	if thief.Parent then
		KitFx.send(thief, "StealFailed", { reason = reason })
	end
	if carry.victim.Parent then
		KitFx.send(carry.victim, "StealStopped", { reason = reason })
	end
end

local function attach(thief: Player, unit: Units.Unit): Model?
	local def = Units.def(unit.kind)
	local character = thief.Character
	local head = if character then character:FindFirstChild("Head") else nil
	if not def or not character or not head or not head:IsA("BasePart") then
		return nil
	end
	local visual = UnitModel.make(def, unit)
	visual:RemoveTag(UnitModel.TAG)
	UnitModel.standOn(visual, head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.5, 0))
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = head
			weld.Part1 = part
			weld.Parent = part
		end
	end
	visual.Parent = character
	return visual
end

local function start(thief: Player, victim: Player, uid: number, model: Model)
	local cfg = config
	if not cfg or thief == victim or not victim.Parent then
		return
	end
	local unit = Units.find(victim, uid)
	if not unit or unit.slot == nil then
		return
	end
	if not Plots.plotOf(thief) then
		KitFx.send(thief, "Error", { code = "NO_PLOT" })
		return
	end
	for _, other in carrying do
		if other.victim == victim and other.uid == uid then
			KitFx.send(thief, "Error", { code = "TAKEN" })
			return
		end
	end
	local victimPlot = Plots.plotOf(victim)
	local ok, reason = StealRules.check({
		now = os.time(),
		own = false,
		locked = victimPlot ~= nil and Plots.isLocked(victimPlot),
		victimJoinedAt = joinedAt[victim] or 0,
		protectNewSeconds = cfg.protectNewSeconds,
		stolenAt = stolenAt[key(victim, uid)],
		recentSeconds = cfg.recentSeconds,
		isBest = best(victim) == uid,
		protectBest = cfg.protectBest == true,
		thiefFull = Units.isFull(thief),
		carrying = carrying[thief] ~= nil,
	})
	if not ok then
		KitFx.send(thief, "Error", { code = reason })
		return
	end
	local carry: Carry = { victim = victim, uid = uid, startedAt = os.clock(), slotModel = model, connections = {} }
	carrying[thief] = carry
	carry.visual = attach(thief, unit)
	model:SetAttribute("BeingStolen", thief.UserId)
	local speed = cfg.carrySpeed
	local fastPass = cfg.fastPass
	if fastPass and cfg.fastSpeed and ShopService.ownsPass(thief, fastPass) then
		speed = cfg.fastSpeed
	end
	KitWorld.setSpeedFactor(thief, SPEED_SOURCE, speed)
	local humanoid = KitWorld.humanoid(thief)
	if humanoid then
		table.insert(carry.connections, humanoid.Died:Connect(function()
			Steal.drop(thief, "DIED")
		end))
	end
	local name = Units.name(unit)
	KitFx.send(thief, "Carrying", { name = name, victim = victim.DisplayName })
	KitFx.send(victim, "BeingStolen", { name = name, thief = thief.DisplayName, uid = uid })
	Signals.track(thief, "StealStart", 1)
end

local function deliver(thief: Player, carry: Carry)
	local victim = carry.victim
	local unit = Units.find(victim, carry.uid)
	finish(thief, carry)
	if not unit then
		return
	end
	local name = Units.name(unit)
	local rank = Units.rank(unit)
	local got = Units.transfer(victim, thief, carry.uid, "Steal")
	if not got then
		KitFx.send(thief, "StealFailed", { reason = "FULL" })
		return
	end
	stolenAt[key(thief, got.uid)] = os.time()
	-- La víctima se guarda ya: si el servidor se cayera con el ladrón guardado (por ejemplo, al salir) y
	-- la víctima no, la unidad quedaría en los dos.
	task.spawn(DataService.saveAsync, victim)
	if got.slot == nil then
		Plots.place(thief, got.uid)
	end
	Signals.track(thief, "Steal", 1)
	Signals.track(victim, "Stolen", 1)
	KitFx.send(thief, "Stole", { name = name, kind = got.kind, variant = got.variant, size = got.size })
	KitFx.send(victim, "WasStolen", { name = name, thief = thief.DisplayName })
	if announceRank > 0 and rank >= announceRank then
		AnnounceService.server({ text = string.format(UiText.STEAL_ANNOUNCE, thief.DisplayName, name, victim.DisplayName), sound = "Legendary" })
	end
end

local function push(pusher: Player, userId: number)
	local cfg = config
	if not cfg then
		return
	end
	local now = os.clock()
	if now - (lastPush[pusher] or 0) < PUSH_COOLDOWN then
		return
	end
	local target = Players:GetPlayerByUserId(userId)
	local root = KitWorld.root(pusher)
	local targetRoot = if target then KitWorld.root(target) else nil
	if not target or target == pusher or not root or not targetRoot then
		return
	end
	if not KitWorld.near(pusher, targetRoot.Position, cfg.pushRange) then
		return
	end
	lastPush[pusher] = now
	local flat = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
	local direction = if flat.Magnitude > 0.01 then flat.Unit else root.CFrame.LookVector
	-- La raíz del empujado es de su cliente (dueño automático): la documentación de ApplyImpulse permite
	-- llamarlo desde el servidor en ese caso.
	targetRoot:ApplyImpulse((direction * PUSH_SPEED + Vector3.new(0, PUSH_SPEED * 0.4, 0)) * targetRoot.AssemblyMass)
	Steal.drop(target, "PUSHED")
	Signals.track(pusher, "Push", 1)
	KitFx.send(target, "Pushed", { by = pusher.DisplayName })
end

function Steal.isCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

function Steal.init(recipe: KitTypes.KitConfig)
	config = recipe.steal
	local units = recipe.units
	local from = if units then units.announceFrom else nil
	if from then
		announceRank = table.find(Units.rarities(), from) or 0
	end
end

function Steal.start(_recipe: KitTypes.KitConfig)
	local cfg = config
	if not cfg then
		return
	end
	Plots.Shown:Connect(function(owner: Player, unit: Units.Unit, model: Model)
		local prompt = KitWorld.prompt(model, {
			action = UiText.PROMPT_STEAL,
			object = Units.name(unit),
			hold = cfg.holdSeconds,
			distance = PROMPT_DISTANCE,
			name = "Steal",
		})
		if prompt then
			-- El cliente del dueño lo esconde: no se roba a sí mismo.
			prompt:SetAttribute("Owner", owner.UserId)
			local uid = unit.uid
			KitWorld.onPrompt(prompt, function(thief: Player)
				start(thief, owner, uid, model)
			end, 1)
		end
	end)
	Remotes.onEvent("PushPlayer", {
		args = { Validate.number({ integer = true, min = 1 }) },
		rate = { count = 3, perSeconds = 1 },
	}, push)
	for _, player in Players:GetPlayers() do
		joinedAt[player] = os.time()
	end
	Players.PlayerAdded:Connect(function(player: Player)
		joinedAt[player] = os.time()
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		Steal.drop(player, "LEFT")
		for thief, carry in carrying do
			if carry.victim == player then
				Steal.drop(thief, "GONE")
			end
		end
		joinedAt[player] = nil
		lastPush[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			for thief, carry in carrying do
				if not carry.victim.Parent or not Units.find(carry.victim, carry.uid) then
					Steal.drop(thief, "GONE")
				elseif os.clock() - carry.startedAt > TIMEOUT then
					Steal.drop(thief, "TIMEOUT")
				else
					local plot = Plots.plotOf(thief)
					local root = KitWorld.root(thief)
					if plot and root and inside(plot, root.Position) then
						deliver(thief, carry)
					end
				end
			end
		end
	end)
end

return Steal
