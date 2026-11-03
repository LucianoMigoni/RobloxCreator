--!strict
-- Animaciones de "dopamina" para la UI, como en los hits: rebote al aparecer, pulso de lo que se puede
-- reclamar, números que suben contando, monedas que vuelan hasta el contador, texto arcoíris, brillo
-- que cruza los botones de oferta, temblor de pantalla y de cámara. Todo con UIScale/rotación para no
-- pisar Size ni Position de los layouts. Las funciones en bucle devuelven una función para pararlas.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Juice = {}

export type Stop = () -> ()

local BACK = Enum.EasingStyle.Back
local OUT = Enum.EasingDirection.Out

local function scaleOf(obj: Instance, name: string?): UIScale
	local key = name or "Juice"
	local existing = obj:FindFirstChild(key)
	if existing and existing:IsA("UIScale") then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = key
	scale.Parent = obj
	return scale
end

-- Golpe rápido de tamaño: al cobrar, al comprar, al llegar una moneda.
function Juice.pop(obj: GuiObject, amount: number?)
	local scale = scaleOf(obj)
	scale.Scale = 1 + (amount or 0.18)
	TweenService:Create(scale, TweenInfo.new(0.35, BACK, OUT), { Scale = 1 }):Play()
end

-- Aparece creciendo desde 0 con rebote.
function Juice.bounceIn(obj: GuiObject, delay: number?)
	local scale = scaleOf(obj)
	scale.Scale = 0
	task.delay(delay or 0, function()
		TweenService:Create(scale, TweenInfo.new(0.45, BACK, OUT), { Scale = 1 }):Play()
	end)
end

-- Pulso continuo: lo que se puede reclamar ya ("FREE!", "CLAIM").
function Juice.pulse(obj: GuiObject, amount: number?, period: number?): Stop
	local scale = scaleOf(obj, "Pulse")
	local tween = TweenService:Create(
		scale,
		TweenInfo.new((period or 0.9) / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Scale = 1 + (amount or 0.08) }
	)
	tween:Play()
	return function()
		tween:Cancel()
		scale.Scale = 1
	end
end

-- Balanceo suave de rotación (íconos de ofertas, regalos listos).
function Juice.wiggle(obj: GuiObject, degrees: number?, period: number?): Stop
	local base = obj.Rotation
	local tween = TweenService:Create(
		obj,
		TweenInfo.new((period or 1.2) / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Rotation = base + (degrees or 8) }
	)
	obj.Rotation = base - (degrees or 8)
	tween:Play()
	return function()
		tween:Cancel()
		obj.Rotation = base
	end
end

-- Temblor corto (error, "NOT ENOUGH", golpe).
function Juice.shake(obj: GuiObject, degrees: number?, duration: number?)
	local base = obj.Rotation
	local d = degrees or 8
	local steps = 6
	task.spawn(function()
		for i = 1, steps do
			obj.Rotation = base + (if i % 2 == 0 then d else -d) * (1 - i / steps)
			task.wait((duration or 0.3) / steps)
		end
		obj.Rotation = base
	end)
end

-- Gira para siempre (rayos detrás de un premio).
function Juice.spin(obj: GuiObject, degreesPerSecond: number?): Stop
	local speed = degreesPerSecond or 30
	local connection = RunService.RenderStepped:Connect(function(dt: number)
		obj.Rotation = (obj.Rotation + speed * dt) % 360
	end)
	return function()
		connection:Disconnect()
	end
end

-- Cuenta de un número a otro en la etiqueta, con el formato dado ("$%s" ya formateado por `format`).
function Juice.countUp(label: TextLabel, from: number, to: number, duration: number?, format: (number) -> string)
	local total = duration or 0.8
	local started = os.clock()
	task.spawn(function()
		while label.Parent do
			local t = math.min(1, (os.clock() - started) / total)
			local eased = 1 - (1 - t) ^ 3
			label.Text = format(from + (to - from) * eased)
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end)
end

-- Degradé arcoíris que corre (rarezas Secret, "JACKPOT"). Sirve para texto (va en el TextLabel) o fondos.
function Juice.rainbow(obj: GuiObject, speed: number?): Stop
	local gradient = Instance.new("UIGradient")
	gradient.Name = "Rainbow"
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.85, 1)))
	end
	gradient.Color = ColorSequence.new(keys)
	gradient.Parent = obj
	local offset = 0
	local connection = RunService.RenderStepped:Connect(function(dt: number)
		offset = (offset + dt * (speed or 0.6)) % 2
		gradient.Offset = Vector2.new(offset - 1, 0)
	end)
	return function()
		connection:Disconnect()
		gradient:Destroy()
	end
end

-- Brillo blanco que cruza el botón cada tanto (ofertas, "BEST VALUE").
function Juice.shine(obj: GuiObject, every: number?): Stop
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BorderSizePixel = 0
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.Size = UDim2.fromScale(0.25, 1.6)
	shine.Position = UDim2.fromScale(-0.3, 0.5)
	shine.Rotation = 20
	shine.ZIndex = obj.ZIndex + 1
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = shine
	obj.ClipsDescendants = true
	shine.Parent = obj
	local running = true
	task.spawn(function()
		while running and shine.Parent do
			shine.Position = UDim2.fromScale(-0.3, 0.5)
			TweenService:Create(shine, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(1.3, 0.5) }):Play()
			task.wait(every or 2.5)
		end
	end)
	return function()
		running = false
		shine:Destroy()
	end
end

-- Destello de pantalla completa (revelación rara).
function Juice.flash(screen: Instance, color: Color3?, duration: number?)
	local frame = Instance.new("Frame")
	frame.Name = "Flash"
	frame.BackgroundColor3 = color or Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 200
	frame.Parent = screen
	local tween = TweenService:Create(frame, TweenInfo.new(duration or 0.5), { BackgroundTransparency = 1 })
	tween.Completed:Once(function()
		frame:Destroy()
	end)
	tween:Play()
end

-- Íconos que vuelan en arco desde `from` (posición en píxeles de pantalla) hasta `target` (el contador).
-- `onArrive` se llama por cada uno que llega (sonido de moneda, pop del contador).
function Juice.flyTo(screen: Instance, from: Vector2, target: GuiObject, makeIcon: () -> GuiObject, count: number?, onArrive: (() -> ())?)
	local n = math.clamp(count or 8, 1, 20)
	for i = 1, n do
		task.delay((i - 1) * 0.045, function()
			if not target.Parent then
				return
			end
			local icon = makeIcon()
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Size = UDim2.fromOffset(42, 42)
			icon.ZIndex = 150
			local scatter = Vector2.new(math.random(-90, 90), math.random(-70, 40))
			local start = from + scatter * 0.3
			icon.Position = UDim2.fromOffset(start.X, start.Y)
			icon.Parent = screen
			local mid = from + scatter
			-- Primero se abren en abanico, después van al contador.
			local out = TweenService:Create(icon, TweenInfo.new(0.22, Enum.EasingStyle.Quad, OUT), { Position = UDim2.fromOffset(mid.X, mid.Y) })
			out:Play()
			out.Completed:Wait()
			local goal = target.AbsolutePosition + target.AbsoluteSize / 2
			local fly = TweenService:Create(
				icon,
				TweenInfo.new(0.45 + math.random() * 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromOffset(goal.X, goal.Y), Size = UDim2.fromOffset(26, 26) }
			)
			fly:Play()
			fly.Completed:Wait()
			icon:Destroy()
			Juice.pop(target, 0.12)
			if onArrive then
				onArrive()
			end
		end)
	end
end

-- Centro de un objeto de UI en píxeles (para flyTo desde un botón).
function Juice.center(obj: GuiObject): Vector2
	return obj.AbsolutePosition + obj.AbsoluteSize / 2
end

-- Temblor de cámara (golpe, revelación SECRET). Usa CameraOffset del Humanoid para no pelear con la cámara.
function Juice.cameraShake(intensity: number?, duration: number?)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local power = intensity or 0.4
	local total = duration or 0.4
	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		if t >= total or not humanoid.Parent then
			humanoid.CameraOffset = Vector3.zero
			connection:Disconnect()
			return
		end
		local fade = 1 - t / total
		humanoid.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * power * fade
	end)
end

-- Zoom de cámara corto (revelación, compra grande).
function Juice.fovPunch(amount: number?, duration: number?)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local base = camera.FieldOfView
	camera.FieldOfView = base - (amount or 8)
	TweenService:Create(camera, TweenInfo.new(duration or 0.5, BACK, OUT), { FieldOfView = base }):Play()
end

return Juice
