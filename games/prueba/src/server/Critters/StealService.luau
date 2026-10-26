--!strict
-- Robo, empujón, traba y protecciones (M7–M10 de docs/spec.md). El servidor decide todo:
-- - Cada critter tiene un prompt "Steal" que el servidor apaga cuando no se puede robar (base trabada,
--   dueño nuevo, su critter más valioso, recién robado). El cliente del dueño lo oculta en su base.
-- - Robar saca el critter de la base del dueño y lo pone sobre el ladrón; llega a la base del ladrón
--   cuando este entra en ella. Si lo empujan, muere o se va, el critter vuelve a su dueño.
-- Las horas se guardan como atributos de la base (con GetServerTimeNow) para que el cliente muestre
-- las cuentas regresivas; solo el servidor las escribe.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local UiText = require(ReplicatedStorage.Shared.Config.UiText)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require("../Data/DataService")
local Remotes = require("../Net/Remotes")
local OnboardingService = require("../Onboarding/OnboardingService")
local CritterService = require("./CritterService")
local CritterVisual = require("./CritterVisual")
local PlotService = require("./PlotService")
local StealRules = require("./StealRules")

local StealService = {}

type Carry = { critter: Types.Critter, from: Player, model: Model, speed: number }

local carrying: { [Player]: Carry } = {}
local recentlyStolen: { [string]: number } = {} -- uid → os.clock() hasta el que no se puede robar
local notify: RemoteEvent? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local function tell(player: Player, text: string)
	if notify then
		notify:FireClient(player, text)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function closed(plot: Model): boolean
	local t = now()
	return (plot:GetAttribute("LockedUntil") or 0) > t or (plot:GetAttribute("ProtectedUntil") or 0) > t
end

local function isRecent(uid: string): boolean
	local untilTime = recentlyStolen[uid]
	return untilTime ~= nil and untilTime > os.clock()
end

-- Prende o apaga los prompts de robo de una base según las reglas vigentes.
local function refresh(owner: Player)
	local data = DataService.get(owner)
	local plot = PlotService.get(owner)
	if not data or not plot then
		return
	end
	local isClosed = closed(plot)
	local best = StealRules.mostValuable(data.critters, function(critter)
		return CritterService.income(owner, critter)
	end)
	for _, critter in data.critters do
		local model = CritterService.display(owner, critter.uid)
		local prompt = model and (model.PrimaryPart :: BasePart):FindFirstChild("StealPrompt") :: ProximityPrompt?
		if prompt then
			prompt.Enabled = not isClosed and critter.uid ~= best and not isRecent(critter.uid)
		end
	end
end

local function dropCarry(thief: Player): Carry?
	local carry = carrying[thief]
	if not carry then
		return nil
	end
	carrying[thief] = nil
	carry.model:Destroy()
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = carry.speed
	end
	if character then
		character:SetAttribute("CarryingFrom", nil)
	end
	return carry
end

-- shortcut: si el dueño se fue o llenó su base mientras se lo llevaban, el critter se pierde; reservar
-- su pedestal al robar si pasa seguido.
local function giveBack(carry: Carry)
	if carry.from.Parent == Players and CritterService.add(carry.from, carry.critter.tier, carry.critter.mutation) then
		tell(carry.from, string.format(UiText.CAME_BACK, GameplayConfig.TIERS[carry.critter.tier].name))
	end
end

local function returnToOwner(thief: Player)
	local carry = dropCarry(thief)
	if carry then
		giveBack(carry)
	end
end

local function deliver(thief: Player)
	local carry = dropCarry(thief) :: Carry
	local critter = CritterService.add(thief, carry.critter.tier, carry.critter.mutation)
	if not critter then
		-- La base del ladrón se llenó en el camino: vuelve a su dueño.
		giveBack(carry)
		tell(thief, UiText.BASE_FULL)
		return
	end
	recentlyStolen[critter.uid] = os.clock() + GameplayConfig.RECENTLY_STOLEN_SECONDS
	refresh(thief)
	task.delay(GameplayConfig.RECENTLY_STOLEN_SECONDS, function()
		recentlyStolen[critter.uid] = nil
		refresh(thief)
	end)
	tell(thief, string.format(UiText.STOLE, GameplayConfig.TIERS[critter.tier].name))
	OnboardingService.complete(thief, "FirstSteal")
end

local function trySteal(thief: Player, owner: Player, uid: string)
	local ownerPlot = PlotService.get(owner)
	local thiefData = DataService.get(thief)
	local ownerData = DataService.get(owner)
	local model = CritterService.display(owner, uid)
	local root = rootOf(thief)
	if not ownerPlot or not thiefData or not ownerData or not model or not root then
		return
	end
	local body = model.PrimaryPart :: BasePart
	if (root.Position - body.Position).Magnitude > GameplayConfig.STEAL_DISTANCE + GameplayConfig.STEAL_DISTANCE_TOLERANCE then
		return
	end
	local best = StealRules.mostValuable(ownerData.critters, function(critter)
		return CritterService.income(owner, critter)
	end)
	local reason = StealRules.blockReason({
		isOwner = thief == owner,
		carrying = carrying[thief] ~= nil,
		thiefHasRoom = CritterService.hasFreePedestal(thief),
		locked = (ownerPlot:GetAttribute("LockedUntil") or 0) > now(),
		protected = (ownerPlot:GetAttribute("ProtectedUntil") or 0) > now(),
		mostValuable = uid == best,
		recentlyStolen = isRecent(uid),
	})
	if reason then
		if reason == "NO_ROOM" then
			tell(thief, UiText.BASE_FULL)
		end
		return
	end
	local critter = CritterService.remove(owner, uid)
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not critter or not character or not humanoid then
		return
	end
	-- El critter va sobre la cabeza del ladrón, soldado al personaje (se destruye si muere).
	local carried = CritterVisual.build(critter.tier, critter.mutation)
	local carriedBody = carried.PrimaryPart :: BasePart
	carriedBody.Anchored = false
	carriedBody.Massless = true
	carriedBody.CFrame = root.CFrame * CFrame.new(0, 4, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = carriedBody
	weld.Parent = carriedBody
	carried.Parent = character
	carrying[thief] = { critter = critter, from = owner, model = carried, speed = humanoid.WalkSpeed }
	humanoid.WalkSpeed *= GameplayConfig.CARRY_SPEED_MULTIPLIER
	character:SetAttribute("CarryingFrom", owner.UserId)
	tell(owner, string.format(UiText.STEAL_ALERT, GameplayConfig.TIERS[critter.tier].name))
end

local function checkDeliveries()
	for thief in carrying do
		local plot = PlotService.get(thief)
		local root = rootOf(thief)
		if plot and root then
			local floor = plot.PrimaryPart :: BasePart
			local offset = floor.CFrame:PointToObjectSpace(root.Position)
			if StealRules.inside(offset.X, offset.Z, GameplayConfig.PLOT_SIZE) then
				deliver(thief)
			end
		end
	end
end

local function push(pusher: Player)
	local root = rootOf(pusher)
	if not root then
		return
	end
	local target: Player?, nearest = nil, GameplayConfig.PUSH_RANGE
	for thief in carrying do
		local thiefRoot = rootOf(thief)
		if thief ~= pusher and thiefRoot then
			local distance = (thiefRoot.Position - root.Position).Magnitude
			if distance <= nearest then
				target, nearest = thief, distance
			end
		end
	end
	if target then
		returnToOwner(target)
	end
end

local function lock(player: Player)
	local plot = PlotService.get(player)
	if not plot or (plot:GetAttribute("LockReadyAt") or 0) > now() then
		return
	end
	local t = now()
	plot:SetAttribute("LockedUntil", t + GameplayConfig.LOCK_SECONDS)
	plot:SetAttribute("LockReadyAt", t + GameplayConfig.LOCK_SECONDS + GameplayConfig.LOCK_COOLDOWN_SECONDS)
	local barrier = plot:FindFirstChild("Barrier") :: BasePart
	barrier.Transparency = 0.85
	refresh(player)
	task.delay(GameplayConfig.LOCK_SECONDS, function()
		if PlotService.get(player) == plot then
			barrier.Transparency = 1
			refresh(player)
		end
	end)
end

local function onAssigned(owner: Player, plot: Model)
	local data = DataService.waitForData(owner)
	if not data or PlotService.get(owner) ~= plot then
		return
	end
	if data.firstPlayedAt == 0 then
		data.firstPlayedAt = os.time()
	end
	local remaining = GameplayConfig.NEW_PLAYER_PROTECTION_SECONDS - (os.time() - data.firstPlayedAt)
	if remaining > 0 then
		plot:SetAttribute("ProtectedUntil", now() + remaining)
		task.delay(remaining, function()
			if PlotService.get(owner) == plot then
				refresh(owner)
			end
		end)
	end
	refresh(owner)
end

-- Llamar antes de PlotService.start(), como CritterService.
function StealService.start()
	notify = Remotes.toClient("Notify")
	Remotes.onEvent("Push", { args = {}, rate = GameplayConfig.PUSH_RATE }, push)
	Remotes.onEvent("LockBase", { args = {}, rate = GameplayConfig.LOCK_RATE }, lock)

	CritterService.Shown:Connect(function(owner: Player, critter: Types.Critter, model: Model)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealPrompt"
		prompt.ActionText = "Steal"
		prompt.ObjectText = GameplayConfig.TIERS[critter.tier].name
		prompt.HoldDuration = GameplayConfig.STEAL_HOLD_SECONDS
		prompt.MaxActivationDistance = GameplayConfig.STEAL_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.Parent = model.PrimaryPart
		prompt.Triggered:Connect(function(thief: Player)
			trySteal(thief, owner, critter.uid)
		end)
	end)
	CritterService.Changed:Connect(refresh)
	PlotService.Assigned:Connect(onAssigned)

	-- Si el ladrón muere, reaparece o se va, el critter vuelve a su dueño.
	local function watch(player: Player)
		local function onCharacter(character: Model)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Connect(function()
				returnToOwner(player)
			end)
		end
		player.CharacterAdded:Connect(onCharacter)
		player.CharacterRemoving:Connect(function()
			returnToOwner(player)
		end)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(returnToOwner)
	task.spawn(function()
		while true do
			task.wait(GameplayConfig.CARRY_CHECK_SECONDS)
			checkDeliveries()
		end
	end)
end

return StealService
