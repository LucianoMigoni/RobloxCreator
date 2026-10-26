-- Auditoría de UI. Pegar en `execute_luau` del MCP de Studio:
--   datamodel Edit   → audita StarterGui (UI hecha en Studio)
--   datamodel Client → audita PlayerGui en playtest (UI hecha por código con UIKit)
-- Devuelve un reporte. ERROR = corregir antes de seguir; WARN = revisar a mano.
-- Popups cerrados (UIScale 0 o invisibles) no se miden: abrirlos y volver a auditar.

local MIN_TOUCH_PX = 44
local MIN_TEXT_SIZE = 14
local IGNORE = { TouchGui = true, Freecam = true, BubbleChat = true } -- UI propia de Roblox

local Players = game:GetService("Players")
local root: Instance = if Players.LocalPlayer
	then Players.LocalPlayer:WaitForChild("PlayerGui")
	else game:GetService("StarterGui")
local camera = workspace.CurrentCamera
local viewport = if camera then camera.ViewportSize else Vector2.zero

local report = {}
local function add(level: string, inst: Instance, msg: string)
	table.insert(report, string.format("%s %s: %s", level, inst:GetFullName(), msg))
end

local function ignored(inst: Instance): boolean
	local gui = inst:FindFirstAncestorWhichIsA("ScreenGui")
	return gui ~= nil and IGNORE[gui.Name] == true
end

-- Producto de los UIScale del objeto y sus ancestros; 0 = cerrado/no medible.
local function effectiveScale(inst: Instance): number
	local scale = 1
	local node: Instance? = inst
	while node and node ~= root do
		if node:IsA("GuiObject") and not node.Visible then
			return 0
		end
		local s = node:FindFirstChildOfClass("UIScale")
		if s then
			scale *= s.Scale
		end
		node = node.Parent
	end
	return scale
end

for _, inst in root:GetDescendants() do
	if ignored(inst) or (inst:IsA("ScreenGui") and IGNORE[inst.Name]) then
		continue
	end

	if inst:IsA("ScreenGui") then
		if inst.ScreenInsets == Enum.ScreenInsets.None and inst:FindFirstChildWhichIsA("GuiButton", true) then
			add("ERROR", inst, "ScreenInsets=None con botones: usar CoreUISafeInsets")
		end
	elseif inst:IsA("GuiObject") then
		local size = inst.Size
		local inGrid = inst.Parent ~= nil and inst.Parent:FindFirstChildOfClass("UIGridLayout") ~= nil

		if not inGrid and inst.AutomaticSize == Enum.AutomaticSize.None and (size.X.Offset ~= 0 or size.Y.Offset ~= 0) then
			add("ERROR", inst, "Size usa Offset " .. tostring(size) .. ": pasar a Scale")
		end

		local shaped = inst:IsA("GuiButton") or inst:IsA("ImageLabel")
		if shaped and not inGrid and size.X.Scale > 0 and size.Y.Scale > 0
			and not inst:FindFirstChildOfClass("UIAspectRatioConstraint") then
			add("WARN", inst, "sin UIAspectRatioConstraint: se deforma entre pantallas")
		end

		if inst:IsA("GuiButton") then
			local c = inst:FindFirstChildOfClass("UISizeConstraint")
			local hasFloor = c ~= nil and c.MinSize.X >= MIN_TOUCH_PX and c.MinSize.Y >= MIN_TOUCH_PX
			-- Se mide siempre: un MinSize junto a UIAspectRatioConstraint y layouts no garantiza el
			-- tamaño (en un Galaxy A06 dio 44x30 con MinSize 44x44).
			local k = effectiveScale(inst)
			if k > 0 then
				local abs = inst.AbsoluteSize / k
				if abs.X < MIN_TOUCH_PX or abs.Y < MIN_TOUCH_PX then
					add("ERROR", inst, string.format("botón de %dx%d px, menor a %d px para dedo", abs.X, abs.Y, MIN_TOUCH_PX))
				elseif not hasFloor then
					add("WARN", inst, "sin UISizeConstraint.MinSize: puede quedar chico en teléfonos")
				end
			end
		end

		if (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) and inst.Text ~= "" then
			if inst.TextScaled and not inst:FindFirstChildOfClass("UITextSizeConstraint") then
				add("WARN", inst, "TextScaled sin UITextSizeConstraint")
			elseif not inst.TextScaled and inst.TextSize < MIN_TEXT_SIZE then
				add("WARN", inst, "TextSize " .. inst.TextSize .. " ilegible en móvil")
			end
		end

		if inst.Name:match("Popup$") and not inst:FindFirstChild("CloseButton", true) then
			add("ERROR", inst, "popup sin CloseButton")
		end
	end
end

local errors = 0
for _, line in report do
	if line:sub(1, 5) == "ERROR" then
		errors += 1
	end
end
table.insert(report, 1, string.format(
	"Auditoría UI de %s (viewport %dx%d): %d ERROR, %d WARN",
	root:GetFullName(), viewport.X, viewport.Y, errors, #report - errors
))
return table.concat(report, "\n")
