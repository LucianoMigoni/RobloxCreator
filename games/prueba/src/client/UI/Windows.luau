--!strict
-- Lo que pasa alrededor de una ventana abierta, como en los hits: fondo oscurecido que la cierra al
-- tocarlo, desenfoque suave del mundo y sonido al abrir y cerrar. Escucha UIKit.PopupToggled.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Sound = require("./Sound")

local Windows = {}

local FADE = TweenInfo.new(0.2)

function Windows.start(screen: ScreenGui)
	local shade = Instance.new("TextButton")
	shade.Name = "Shade"
	shade.Text = ""
	shade.AutoButtonColor = false
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 1
	shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1)
	shade.Visible = false
	shade.ZIndex = 19 -- debajo de las ventanas (20) y arriba del HUD
	shade.Parent = screen
	local blur = Instance.new("BlurEffect")
	blur.Name = "WindowBlur"
	blur.Size = 0
	blur.Parent = Lighting

	shade.Activated:Connect(function()
		local open = UIKit.current()
		if open then
			UIKit.close(open)
		end
	end)

	UIKit.PopupToggled:Connect(function(_popup: GuiObject, isOpen: boolean)
		if isOpen then
			Sound.play("Open")
			shade.Visible = true
			TweenService:Create(shade, FADE, { BackgroundTransparency = 0.55 }):Play()
			TweenService:Create(blur, FADE, { Size = 10 }):Play()
		else
			Sound.play("Close")
			-- Cambiar de una ventana a otra no apaga el fondo.
			task.defer(function()
				if UIKit.current() == nil then
					local tween = TweenService:Create(shade, FADE, { BackgroundTransparency = 1 })
					tween.Completed:Once(function()
						if UIKit.current() == nil then
							shade.Visible = false
						end
					end)
					tween:Play()
					TweenService:Create(blur, FADE, { Size = 0 }):Play()
				end
			end)
		end
	end)
end

return Windows
