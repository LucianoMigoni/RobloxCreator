# Guía de estilo

El estilo de los hits actuales de Roblox (`hud-hits.md`): formas redondas y gordas, borde oscuro grueso, color saturado con brillo arriba y studs, texto blanco con contorno, todo rebota. Los valores por defecto están en `template/src/shared/UIKit.luau`; si el usuario trae paleta propia, se cambia ahí.

## Colores con significado fijo

Nunca reutilizar un color para otro significado: el jugador aprende el código en segundos. Son los de `UIKit.Colors` (degradé del claro al oscuro, con labio oscuro abajo).

| Significado | Uso | Base → oscuro |
|---|---|---|
| Accept (verde) | Comprar, aceptar, reclamar, la tienda | `#46D64B` → `#23A62E` |
| Close (rojo) | Cerrar, cancelar, oferta especial | `#FF3B4F` → `#C81E32` |
| Premium (dorado) | Robux, pases, ofertas premium, premios | `#FFD23A` → `#F2A10F` |
| Info (celeste) | Índice, navegación, información | `#2EC5F5` → `#1B8FD6` |
| Pink (rosa) | Renacer | `#FF5C8A` → `#E0245E` |
| Purple (violeta) | Regalos, intercambio, calendario | `#A35CFF` → `#6E2BD6` |
| Orange (naranja) | Regalos gratis, eventos | `#FFA62B` → `#F06A10` |
| Neutral (gris) | Botón apagado ("CLAIM" que todavía no se puede) | `#9AA0AD` → `#6B7180` |
| Panel | Cuerpo de las ventanas, gris carbón con studs | `#2D2F3A` → `#1F2029` |
| Borde | `UIStroke` de todo | `#141020` |
| Plata | El número de la plata | `#5DFF4A` |

## Tipografía
- Principal: **Fredoka One** (`Enum.Font.FredokaOne`). La barra de Roblox usa **Builder Sans** (`UIKit.TopbarFont`), y el ícono de Robux es el glifo U+E002 con esa fuente.
- Texto siempre con `UIStroke` en modo `Contextual` y `StrokeSizingMode.ScaledSize` (grosor relativo al tamaño de letra: 0.14).
- Máximo 2 fuentes por juego. Textos cortos y **en inglés** (regla del hub, `CLAUDE.md`): "BUY!" mejor que "Click here to buy this item".
- Nada de texto dentro de imágenes o iconos: la traducción automática de Roblox no lo traduce. El texto va en `TextLabel` con `AutoLocalize = true` (`UIKit.text` lo activa).

## Componentes

Medidas a 1080p y foto de cada uno en `hud-hits.md` (§Material visual y §Medidas de referencia).

| Componente | Forma | Detalles |
|---|---|---|
| Botón | `UICorner` 0.22, borde 5 % (`ScaledSize`), degradé con labio, bisel claro, brillo arriba y studs | Texto `TextScaled`, rebote al presionar |
| Botón del menú | Ancho (ícono plano y nombre, como Steal An Egg) o cuadrado (ícono 3D que se sale y nombre montado abajo, como Anime Dice) | `GameConfig.HUD_MENU`; en táctil siempre cuadrado |
| Plata | Ícono 3D y número gordo verde, sin fondo | Abajo a la izquierda en PC; arriba a la derecha en táctil |
| Ventana | Cabecera de color con franjas, título a la izquierda con el ícono saliéndose, X roja en la esquina, cuerpo gris carbón con studs | Casi a pantalla completa en el teléfono |
| Oferta del HUD | Ícono 3D sobre rayos que giran, etiqueta inclinada ("OP!") y precio en Robux | Columna derecha |
| Notificación | Píldora arriba al centro | Entra deslizando, se va sola en 2–3 s |
| Etiqueta de ahorro | Cinta inclinada | Solo con ahorro real (ver `roblox-monetization`) |

## Layout del HUD (horizontal)

El de los hits, en `hud-hits.md` §Lo que tienen en común, con las muestras `hud-hits/muestra-kit.jpg` (PC) y `hud-hits/muestra-telefono.jpg` (teléfono).

- **PC:** botones propios en la barra de Roblox, objetivo arriba al centro, menú a la izquierda, ofertas a la derecha, plata enorme abajo a la izquierda, impulsos y evento abajo a la derecha, lugar del kit abajo al centro.
- **Táctil:** las esquinas de abajo son del joystick y del salto (ver abajo). Menú en grilla arriba a la izquierda, plata arriba a la derecha, ofertas debajo, impulsos arriba al centro, lugar del kit abajo entre las dos zonas. `HudController` lo cambia solo.
- **Zonas reservadas (móvil):** el joystick dinámico ocupa abajo a la izquierda (≈ 41 % izquierdo de la pantalla, desde el 43 % del alto hacia abajo) y el salto, abajo a la derecha. Nada interactivo ni información importante ahí. Fuente: https://create.roblox.com/docs/ui/position-and-size (Reserved zones).
- Acciones frecuentes del juego (atacar, recolectar) cerca del botón de salto, posicionadas en relación con `JumpButton` (ejemplo en la misma página oficial), para alcanzarlas con el pulgar derecho.
- Pocos botones de menú grandes (en táctil entran 8). Lo demás va dentro de ventanas.

## Animaciones (TweenService)

| Acción | Tween |
|---|---|
| Presionar botón | `UIScale` → 0.9 en 0.06 s (Quad Out) |
| Soltar botón | `UIScale` → 1 en 0.2 s (Back Out) |
| Abrir popup | `UIScale` 0 → 1 en 0.25 s (Back Out), desde el centro (`AnchorPoint` 0.5, 0.5) |
| Cerrar popup | `UIScale` 1 → 0 en 0.15 s (Back In), luego `Visible = false` |
| Ganar monedas | contador hace pulso `UIScale` 1 → 1.15 → 1 |

Rápidas y cortas: ninguna animación bloquea la entrada más de 0.3 s.

## Tomar el estilo, no copiar
- Sí: formas, proporciones, código de colores, ritmo de animación, ubicación de elementos.
- No: iconos, logos, mascotas, nombres, combinaciones exactas de pantalla ni capturas de juegos existentes. Los iconos se generan nuevos o salen del catálogo con licencia.
