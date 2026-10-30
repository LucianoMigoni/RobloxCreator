--!strict
-- Barra de acción del armador, abajo al centro (en el teléfono, entre el joystick y el salto): los
-- botones grandes de lo que se hace ahora, como en los hits ("TAP!", "Cast", "Sell All", "Collect").
-- Cada bloque agrega los suyos y los muestra u oculta según el contexto. Los botones se reparten el
-- ancho: con muchos se achican, pero nunca bajan de 44 px de alto si entran.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)
local HudController = require("../Controllers/HudController")
local Juice = require("../UI/Juice")
local Sound = require("../UI/Sound")

export type Props = {
	text: string, -- en inglés
	icon: string?, -- shared/Icons
	variant: UIKit.Variant?,
	order: number?,
	key: Enum.KeyCode?, -- atajo en PC (se ve chico en la esquina del botón)
	repeatEvery: number?, -- mantener apretado repite cada tantos segundos (toques)
	onClick: () -> (),
}

type Entry = { button: TextButton, props: Props, visible: boolean }

local ActionBar = {}

local MAX_ASPECT = 2.4
local MIN_ASPECT = 1.5
local GAP = 0.03 -- fracción del ancho entre botones

local bar: Frame? = nil
local entries: { [string]: Entry } = {}

local function layout()
	local frame = bar
	if not frame then
		return
	end
	local size = frame.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	local shown: { Entry } = {}
	for _, entry in entries do
		if entry.visible then
			table.insert(shown, entry)
		end
	end
	local n = #shown
	if n == 0 then
		return
	end
	local gap = size.X * GAP
	local width = (size.X - gap * (n - 1)) / n
	local height = math.min(size.Y, width / MIN_ASPECT)
	width = math.min(width, height * MAX_ASPECT)
	for _, entry in shown do
		entry.button.Size = UDim2.fromScale(width / size.X, height / size.Y)
	end
end

local function trigger(entry: Entry)
	if not entry.visible then
		return
	end
	Sound.play("Click")
	-- El cast deja leer el error: pcall de una función sin retorno solo tipa el booleano.
	local ok, err = pcall(entry.props.onClick :: () -> ...any)
	if not ok then
		warn("[ActionBar] error en " .. entry.button.Name .. ": " .. tostring(err))
	end
end

function ActionBar.start(hud: HudController.Hud)
	if bar then
		return
	end
	local frame = UIKit.new("Frame", {
		Name = "ActionBar",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, hud.bottom) :: Frame
	UIKit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(GAP, 0),
	}, frame)
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	bar = frame
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		for _, entry in entries do
			if entry.props.key == input.KeyCode then
				trigger(entry)
				Juice.pop(entry.button, 0.08)
				local every = entry.props.repeatEvery
				if every then
					task.spawn(function()
						task.wait(math.max(every, 0.25))
						while UserInputService:IsKeyDown(input.KeyCode) and entry.visible do
							trigger(entry)
							task.wait(every)
						end
					end)
				end
			end
		end
	end)
end

-- Agrega (o reemplaza) un botón. Arranca visible.
function ActionBar.add(id: string, props: Props): TextButton?
	local frame = bar
	if not frame then
		warn("[ActionBar] add antes de start: " .. id)
		return nil
	end
	ActionBar.remove(id)
	local button = UIKit.button({
		name = id,
		text = props.text,
		variant = props.variant or "Accept",
		icon = props.icon,
		aspectRatio = 0,
		layoutOrder = props.order or 0,
		parent = frame,
	})
	local entry: Entry = { button = button, props = props, visible = true }
	entries[id] = entry
	if props.key and not UserInputService.TouchEnabled then
		UIKit.label(button, "Key", props.key.Name, {
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0.04, -0.12),
			Size = UDim2.fromScale(0.3, 0.36),
			ZIndex = 5,
		})
	end
	local holding = false
	button.MouseButton1Down:Connect(function()
		local every = props.repeatEvery
		if not every then
			return
		end
		holding = true
		trigger(entry)
		task.spawn(function()
			task.wait(math.max(every, 0.25))
			while holding and entry.visible and button.Parent do
				trigger(entry)
				task.wait(every)
			end
		end)
	end)
	local function release()
		holding = false
	end
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	button.Activated:Connect(function()
		if not props.repeatEvery then
			trigger(entry)
		end
	end)
	Juice.bounceIn(button, (props.order or 0) * 0.04)
	layout()
	return button
end

function ActionBar.remove(id: string)
	local entry = entries[id]
	if entry then
		entry.button:Destroy()
		entries[id] = nil
		layout()
	end
end

function ActionBar.show(id: string, visible: boolean)
	local entry = entries[id]
	if entry and entry.visible ~= visible then
		entry.visible = visible
		entry.button.Visible = visible
		if visible then
			Juice.bounceIn(entry.button)
		end
		layout()
	end
end

function ActionBar.setText(id: string, text: string)
	local entry = entries[id]
	if entry then
		UIKit.setText(entry.button, text)
	end
end

function ActionBar.get(id: string): TextButton?
	local entry = entries[id]
	return if entry then entry.button else nil
end

return ActionBar
