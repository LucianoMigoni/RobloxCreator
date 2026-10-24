# Reglas técnicas (verificadas en create.roblox.com/docs el 2026-10-21; revisadas contra Roblox/creator-docs el 2026-10-24)

| Regla | API | Fuente |
|---|---|---|
| Zonas reservadas táctiles | En móvil, los controles por defecto ocupan las esquinas inferiores: joystick dinámico abajo a la izquierda, salto abajo a la derecha. No poner botones ni información importante ahí. Para botones de acción, posicionarlos relativos a `JumpButton` (en `PlayerGui`, esperar `IsLoaded`). | /ui/position-and-size (Reserved zones, Thumb zones) |
| Zona segura para notch y barra de Roblox | `ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` (recomendado para UI interactiva; es el valor por defecto). `None` solo para fondos no interactivos. `ClipToDeviceSafeArea` recorta al área segura. `GuiService.TopbarInset` (Rect) da el espacio libre en la barra superior. | /reference/engine/enums/ScreenInsets, /reference/engine/classes/ScreenGui, /reference/engine/classes/GuiService |
| Bordes redondeados | `UICorner.CornerRadius` (UDim). Scale se mide contra el lado más corto: ≥ 0.5 da píldora. | /ui/appearance-modifiers |
| Borde grueso / contorno de texto | `UIStroke`. En objetos de texto, `ApplyStrokeMode.Contextual` contornea las letras y `Border` dibuja el borde del objeto; se pueden poner dos `UIStroke` (uno de cada modo). `Thickness` en píxeles salvo `StrokeSizingMode.ScaledSize`. `BorderStrokePosition`: Center, Inner, Outer. | /ui/appearance-modifiers, /reference/engine/classes/UIStroke |
| No tweenear grosor de contorno de texto | Tweenear `Thickness` de un `UIStroke` sobre texto genera muchos tamaños de glifo por frame: parpadeo y costo. | /ui/appearance-modifiers |
| Gradiente | `UIGradient.Color` (ColorSequence), `Transparency` (NumberSequence), `Rotation`, `Offset`. El color se multiplica con el fondo: usar `BackgroundColor3` blanco. | /ui/appearance-modifiers |
| Proporción fija | `UIAspectRatioConstraint.AspectRatio` (ancho/alto), hijo del objeto. Si compite con un `UIListLayout`, gana la restricción. | /ui/size-modifiers |
| Tamaño mínimo/máximo | `UISizeConstraint.MinSize/MaxSize` (píxeles). | /ui/size-modifiers |
| Texto escalable | `TextScaled = true` + `UITextSizeConstraint.MinTextSize/MaxTextSize`; MinTextSize no menor a 9. | /ui/size-modifiers |
| Animar sin romper layout | `UIScale.Scale` multiplica el tamaño absoluto y escala hijos, `UIStroke` y `UICorner`. | /ui/size-modifiers |
| Tweens | `TweenService:Create(obj, TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime), goals)`. `Enum.EasingStyle` incluye Back, Bounce, Elastic, Quad, etc. | /reference/engine/datatypes/TweenInfo, /reference/engine/enums/EasingStyle |
| Fuentes | `Font.fromEnum(Enum.Font.FredokaOne)`, `Font.fromName(name, weight, style)`, `Font.fromId(id, ...)`. `Enum.Font` incluye FredokaOne, LuckiestGuy, GothamBlack, Bangers. | /reference/engine/datatypes/Font, /reference/engine/enums/Font |
| Tipo de entrada | `UserInputService.PreferredInput` (`Touch`, `Gamepad`, `KeyboardAndMouse`) para adaptar la UI; preferirlo sobre `TouchEnabled` en dispositivos mixtos. | /reference/engine/classes/UserInputService |
| Clic multiplataforma | `GuiButton.Activated` funciona con mouse, toque y gamepad. | /reference/engine/classes/GuiButton |

## Tamaño táctil
La documentación de Roblox no fija un mínimo en píxeles. Se usa 44×44 px (guía de interfaz de Apple, 44 pt) como piso, aplicado con `UISizeConstraint.MinSize`. Separación entre botones ≥ 3 % del alto de pantalla.

## Por qué `SizeConstraint = RelativeYY` en botones laterales
Hace que ancho y alto dependan del alto de pantalla: el botón mide lo mismo en un teléfono 19.5:9 que en una tablet 4:3, en vez de estirarse con el ancho.
