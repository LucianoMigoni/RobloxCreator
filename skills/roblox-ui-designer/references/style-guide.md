# Guía de estilo

El estilo de los simuladores y tycoons grandes de Roblox: formas redondas y gordas, borde oscuro grueso, color saturado con brillo arriba, texto blanco con contorno, todo rebota. Los valores por defecto están en `scripts/UIKit.luau`; si el usuario trae paleta propia, se cambia ahí.

## Colores con significado fijo

Nunca reutilizar un color para otro significado: el jugador aprende el código en segundos.

| Significado | Uso | Gradiente (arriba → abajo) |
|---|---|---|
| Accept (verde) | Comprar, aceptar, reclamar, jugar | `#5BE33C` → `#2EA81E` |
| Close (rojo) | Cerrar, cancelar, peligro | `#FF5656` → `#C81E2D` |
| Premium (dorado) | Robux, pases, ofertas premium | `#FFD640` → `#F09614` |
| Info (azul) | Navegación, info, pestañas | `#50B4FF` → `#1E6EE6` |
| Neutral (pizarra) | Fondos de paneles y popups | `#464A64` → `#2D3046` |
| Borde | `UIStroke` de todo | `#191628` |
| Texto | Blanco con contorno oscuro | `#FFFFFF` / contorno `#191628` |

## Tipografía
- Principal: **Fredoka One** (`Enum.Font.FredokaOne`). Títulos llamativos: **Luckiest Guy** (`Enum.Font.LuckiestGuy`). Alternativas gruesas: `GothamBlack`, `Bangers`.
- Texto siempre con `UIStroke` en modo `Contextual` (contorno de letra), grosor 2.
- Máximo 2 fuentes por juego. Textos cortos: "¡COMPRAR!" mejor que "Haz clic aquí para comprar".

## Componentes

| Componente | Forma | Detalles |
|---|---|---|
| Botón | `UICorner` 0.25 (Scale), borde 3 px, gradiente vertical | Texto `TextScaled`, rebote al presionar |
| Botón lateral | Cuadrado, ~12 % del alto de pantalla, mín. 48 px | Icono arriba + palabra corta abajo |
| Contador de moneda | Píldora (`UICorner` 0.5), relación 3:1 | Icono de la moneda a la izquierda, número abreviado (1.2K, 3.4M) |
| Popup | Panel neutral, `UICorner` 0.08, borde 4 px, relación ~1.4:1 | Título arriba, cerrar rojo en la esquina superior derecha, sobresaliendo |
| Notificación | Píldora arriba al centro | Entra deslizando, se va sola en 2–3 s |
| Etiqueta de ahorro | Cinta dorada o roja inclinada | Solo con ahorro real (ver `roblox-monetization`) |

## Layout del HUD (horizontal)

```
┌─────────────────────────────────────────────┐
│ [barra Roblox]   (💰 1.2K) (💎 35)           │  ← monedas arriba, bajo la barra
│                                             │
│ [Tienda]                                    │
│ [Mochila]                        zona libre │
│ [Pases ]                         para jugar │
│ [Ajustes]                                   │
│                                [joystick / salto de Roblox abajo] │
└─────────────────────────────────────────────┘
```

- Botones laterales a la izquierda, centrados verticalmente; el pulgar derecho queda libre para saltar/acción.
- Nada interactivo en la franja inferior derecha (controles táctiles de Roblox) ni bajo la barra superior.
- Máximo 5–6 botones laterales. Lo demás va dentro de popups.

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
