# Plantilla de `docs/lanzamiento.md`

Copiar en `games/<juego>/docs/lanzamiento.md` y completar. Lo marcado **(hub)** es criterio nuestro; lo demás sale de la documentación oficial citada en `../SKILL.md`.

## 1. Metadata

**Idioma:** todo en **inglés**, para público internacional (regla del hub, `CLAUDE.md`). En el Creator Dashboard → Localization:
- idioma de origen inglés;
- *Use Translated Content* activado, con los idiomas elegidos en la pestaña Languages (Roblox traduce automáticamente a 18 idiomas el nombre, la descripción y los textos del juego);
- *Capture text from experience UI while users play* activado.

La traducción automática **no** cubre el texto dentro de imágenes (icono, miniaturas) ni los nombres y descripciones de badges y pases (fuente: `/production/localization/automatic-translations`, verificado el 2026-10-26). Por eso el icono y las miniaturas van sin texto o con muy poco.

**Nombre:** …
- Estable: no se piensa renombrar después del lanzamiento.
- Sin palabras repetidas; como mucho uno o dos emojis bien ubicados.
- No se parece al de un juego existente (juego "no único" = menos exposición).

**Descripción**
- Primera oración: qué es el juego y qué hace el jugador. Es lo primero que se ve.
- Después: mecánicas principales y lo que lo diferencia, con las palabras clave que un jugador usaría para buscarlo.
- Sin listas de palabras sueltas, sin nombres de otros juegos, sin promesas de Robux ni recompensas, apta para todo público.
- Opcional, de una guía **experimental** de Roblox para SEO externo (Roblox no la recomienda para todos los juegos): gancho de hasta ~160 caracteres (es lo que se ve en el móvil antes de expandir), un bloque corto de novedades, contenido principal, dispositivos soportados y preguntas frecuentes. No usar hashtags (no se usan para ranking) ni listar controles (se enseñan en el juego).

**Género / subgénero:** … / …
- El que describe el loop principal. Se cambia una vez cada 3 meses: elegirlo solo cuando esté claro.

**Contrastar con la spec:** cada cosa que nombran el título, la descripción, el icono y las miniaturas existe en el juego hoy.

## 2. Icono
- [ ] Cuadrado, ≥ 512×512.
- [ ] Se entiende a 150×150 (probar reducido).
- [ ] Muestra el tema, el tono o el género; único y relevante (nada ambiguo en las esquinas).
- [ ] Colores acordes al tono (saturados para fantasía, apagados para algo sombrío).
- [ ] Assets con licencia comercial (catálogo) y registrados si son nuevos.

## 3. Miniaturas
| # | Hipótesis (qué la haría elegir) | Captura de | Estado |
|---|---|---|---|
| 1 | La mecánica principal en acción | … | |
| 2 | Amigos jugando juntos (co-play) **(hub)** | … | |
| 3 | El mundo o el escenario más llamativo | … | |
| 4 | La progresión o la recompensa (sin prometer Robux) | … | |

- [ ] 16:9, ideal 1920×1080, menos de 3 MB para la personalización.
- [ ] Nada esencial en la parte de abajo.
- [ ] Imágenes del juego real; retoques menores de brillo o contraste y el logo están bien.
- [ ] Entre 2 y 5 activas en **Home Page → Edit active thumbnails** para la personalización.
- [ ] Texto alternativo cargado (accesibilidad).

**Video (opcional):** gameplay real, cámara libre permitida, sin voz, narración ni música con letra, sin imágenes reales, texto solo para explicar ("Junta monedas para saltar más"). Cupo: 3 subidas por mes, los rechazados cuentan.

## 4. Plan de lanzamiento
| Fecha | Paso | Responsable | Criterio |
|---|---|---|---|
| … | Testers (hasta 10, File → Invite early testers) | … | Sin errores en consola; entienden el juego sin explicación |
| … | Lanzamiento a 16+ | … | QA, cumplimiento y monetización sin bloqueantes |
| … | Cuestionario completo y requisitos de cuenta para menores de 16 | … | Etiqueta Minimal, Mild o Moderate; ver `roblox-compliance` |
| … | Evaluación para Kids y Select | … | 250 jugadas únicas de jugadores 16+ muy comprometidos en 60 días (panel **Audience Reach**) |
| … | Promoción | … | Qué canal, cuánto y qué se mide |
| D1, D7, D28 | Revisión con `roblox-metrics-growth` | … | Datos con fuente y fecha |

Notas **(hub)**:
- El FAQ del algoritmo dice que no hay castigo por un mal arranque: un lanzamiento chico sirve para encontrar errores, no para "proteger" el algoritmo.
- Si el público objetivo incluye menores de 16, el primer público real es 16+ (la evaluación se cuenta con ellos): la vitrina y el primer minuto tienen que funcionar también para ese público.
- La evaluación no exige una fuente de jugadores en particular. Los traídos por ads, amigos o redes ayudan a que Home elija el juego como candidato, pero no cuentan para el ranking de Recommended for You.
- Ads: Ads Manager (cuenta de 13+ con email verificado). Antes de pagar, definir presupuesto, qué métrica se espera mover y cuándo se revisa.
