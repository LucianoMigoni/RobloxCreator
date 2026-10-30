# Reglas técnicas (verificadas en create.roblox.com/docs el 2026-10-21; revisadas contra Roblox/creator-docs el 2026-10-24 y el 2026-10-30)

| Regla | API | Fuente |
|---|---|---|
| Zonas reservadas táctiles | En móvil, los controles por defecto ocupan las esquinas inferiores: joystick dinámico abajo a la izquierda (en el dibujo oficial, ≈ 41 % izquierdo del ancho, desde el 43 % del alto hacia abajo) y salto abajo a la derecha. "Avoid placing important info or virtual buttons in these zones". Para botones de acción, posicionarlos relativos a `JumpButton` (en `PlayerGui`, esperar `IsLoaded`). | /ui/position-and-size (Reserved zones, Thumb zones) |
| Pantallas chicas | La guía de diseño adaptable pide reordenar o condensar en pantallas chicas (por ejemplo, botones menos importantes en un menú). | /production/publishing/adaptive-design |
| Zona segura para notch y barra de Roblox | `ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` (recomendado para UI interactiva; es el valor por defecto). `None` solo para fondos no interactivos. `ClipToDeviceSafeArea` recorta al área segura. `GuiService.TopbarInset` (Rect) da el espacio libre en la barra superior. | /reference/engine/enums/ScreenInsets, /reference/engine/classes/ScreenGui, /reference/engine/classes/GuiService |
| Bordes redondeados | `UICorner.CornerRadius` (UDim). Scale se mide contra el lado más corto: ≥ 0.5 da píldora. | /ui/appearance-modifiers |
| Borde grueso / contorno de texto | `UIStroke`. En objetos de texto, `ApplyStrokeMode.Contextual` contornea las letras y `Border` dibuja el borde del objeto; se pueden poner dos `UIStroke` (uno de cada modo). `Thickness` en píxeles salvo `StrokeSizingMode.ScaledSize`: ahí es una fracción del lado menor del padre (en texto, del tamaño de letra). `UIKit` usa `ScaledSize`: `UIKit.style(obj, variante, esquina, 0.05)` es 5 %, nunca píxeles. `BorderStrokePosition`: Center, Inner, Outer. | /ui/appearance-modifiers, /reference/engine/classes/UIStroke, /reference/engine/enums/StrokeSizingMode |
| No tweenear grosor de contorno de texto | Tweenear `Thickness` de un `UIStroke` sobre texto genera muchos tamaños de glifo por frame: parpadeo y costo. | /ui/appearance-modifiers |
| Gradiente | `UIGradient.Color` (ColorSequence), `Transparency` (NumberSequence), `Rotation`, `Offset`. El color se multiplica con el fondo: usar `BackgroundColor3` blanco. | /ui/appearance-modifiers |
| Proporción fija | `UIAspectRatioConstraint.AspectRatio` (ancho/alto), hijo del objeto. Si compite con un `UIListLayout`, gana la restricción. Con `FitWithinMaxSize` el objeto toma el mayor tamaño que entra en su propio tamaño: la documentación no dice qué pasa con un eje en 0, así que no se usa así (ver `UIKit.fitHeight`). | /ui/size-modifiers, /reference/engine/classes/UIAspectRatioConstraint |
| Llenar lo que sobra | `UIFlexItem` hijo de un elemento de un `UIListLayout`, con `FlexMode = Fill`: crece o se achica para llenar la fila o columna; los demás conservan su tamaño. Sirve para apilar partes sin que se encimen (el índice de la plantilla). | /ui/list-flex-layouts, /reference/engine/classes/UIFlexItem |
| Carteles en el mundo | `BillboardGui`: la escala de `Size` es en studs y el offset en píxeles; `StudsOffsetWorldSpace`, `MaxDistance`, `LightInfluence`. Las flechas del camino son un `Beam` con `TextureMode.Wrap` y `TextureSpeed` positivo (avanzan de `Attachment0` a `Attachment1`). | /reference/engine/classes/BillboardGui, /reference/engine/classes/Beam |
| Tamaño mínimo/máximo | `UISizeConstraint.MinSize/MaxSize` (píxeles). | /ui/size-modifiers |
| Texto escalable | `TextScaled = true` + `UITextSizeConstraint.MinTextSize/MaxTextSize`; MinTextSize no menor a 9. | /ui/size-modifiers |
| Animar sin romper layout | `UIScale.Scale` multiplica el tamaño absoluto y escala hijos, `UIStroke` y `UICorner`. | /ui/size-modifiers |
| Tweens | `TweenService:Create(obj, TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime), goals)`. `Enum.EasingStyle` incluye Back, Bounce, Elastic, Quad, etc. | /reference/engine/datatypes/TweenInfo, /reference/engine/enums/EasingStyle |
| Fuentes | `Font.fromEnum(Enum.Font.FredokaOne)`, `Font.fromName(name, weight, style)`, `Font.fromId(id, ...)`. `Enum.Font` incluye FredokaOne, LuckiestGuy, GothamBlack, Bangers. | /reference/engine/datatypes/Font, /reference/engine/enums/Font |
| Tipo de entrada | `UserInputService.PreferredInput` (`Touch`, `Gamepad`, `KeyboardAndMouse`) para adaptar la UI; preferirlo sobre `TouchEnabled` en dispositivos mixtos. | /reference/engine/classes/UserInputService |
| Clic multiplataforma | `GuiButton.Activated` funciona con mouse, toque y gamepad. | /reference/engine/classes/GuiButton |

## Tamaño táctil
La documentación de Roblox no fija un mínimo en píxeles. Se usa 44×44 px (guía de interfaz de Apple, 44 pt) como piso y se mide con `audit_ui.luau`. Separación entre botones ≥ 3 % del alto de pantalla.
- En el HUD, con `UISizeConstraint.MinSize`.
- Dentro de las ventanas, por diseño: un `MinSize` junto a una relación de aspecto agranda el botón dentro de una fila y lo encima con lo de al lado (y en un Galaxy A06 tampoco garantizó el tamaño: dio 44×30). Se logra con:
  - ventanas casi a pantalla completa en el teléfono (`UIKit.window` lo hace solo);
  - menos columnas cuando `UIKit.isSmallScreen()`;
  - filas con alto mínimo (`UIKit.fitHeight(fila, relación, 64)`).

## En el teléfono acostado
Muestra: `hud-hits/muestra-telefono.jpg` (con y sin las zonas reservadas marcadas). El HUD táctil de la plantilla:
- menú en grilla de 4×2 arriba a la izquierda (también el evento, invitar y los botones de la derecha);
- plata arriba a la derecha;
- ofertas debajo, terminando antes del botón de salto;
- impulsos arriba al centro, debajo del objetivo;
- lugar del kit abajo, entre el joystick y el salto.

## Por qué `SizeConstraint = RelativeYY` en botones laterales
Hace que ancho y alto dependan del alto de pantalla: el botón mide lo mismo en un teléfono 19.5:9 que en una tablet 4:3, en vez de estirarse con el ancho.
