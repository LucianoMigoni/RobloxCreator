---
name: roblox-qa-performance
description: Prueba un juego de Roblox antes de cada publicación con foco en móvil de gama baja (memoria, carga, streaming, scripts) y en que todo funcione (playtest con el MCP de Studio, consola sin errores, auditorías de UI y seguridad). Usar en la fase 6 del pipeline y antes de cada update.
---

# roblox-qa-performance

## Objetivo
Que el juego cargue rápido, no se caiga en un teléfono modesto y no tenga errores, antes de que lo vea un jugador. Una carga lenta o un error en el primer minuto es bounce, y el algoritmo lo castiga (`skills/_shared/algoritmo-descubrimiento.md`). Sale `games/<juego>/docs/qa.md`.

## Cuándo usarlo
- Fase 6 del pipeline, con un build jugable.
- Antes de cada update (`references/checklist.md`).
- Cuando `roblox-metrics-growth` ve bounce alto o caídas de rendimiento.

**Lo llaman:** `roblox-ui-designer` (prueba en móvil), `roblox-security` (prueba en Studio), `roblox-publishing` y `roblox-liveops` (antes de publicar).
**Llama a:** el skill dueño de cada falla encontrada.

## Base oficial (verificado el 2026-10-25, `/performance-optimization`)
- **Dispositivo base:** elegir al menos un dispositivo de gama baja y probar en él durante todo el desarrollo. Los móviles tienen poca memoria y se cierran por falta de memoria.
- **El emulador de Studio** sirve para relación de aspecto y controles, **no** para memoria: en Studio corren servidor y cliente juntos.
- **Instance streaming** (`Workspace.StreamingEnabled`) carga y descarga contenido 3D: mejora memoria y tiempo de entrada en la mayoría de los lugares. Los lugares muy grandes se pueden dividir con teleport.
- **Materiales nativos** antes que texturas propias; reutilizar mallas y texturas en vez de importar copias.
- **Herramientas:** Developer Console (F9) para memoria (un `LuaHeap` alto o que crece indica una fuga), estadísticas de render y MicroProfiler para tiempo de scripts y física.
- **Después de publicar:** probar en dispositivos reales (calentamiento, red mala) y seguir los paneles de rendimiento de Creator Analytics.

## Flujo
1. **Chequeo estático:** `python tools/check.py` en verde.
2. **Playtest con el MCP** (nombres en `skills/_shared/mcp-tools.md`): `list_roblox_studios` → `start_stop_play` → jugar el primer minuto con `character_navigation`, `user_mouse_input` y `user_keyboard_input` → `get_console_output` **sin errores ni warnings nuevos**.
3. **Foto de rendimiento:** `execute_luau` con `scripts/perf_snapshot.luau`, en Client y en Server. Comparar con la foto anterior en `docs/qa.md`: memoria, instancias, draw calls. Cualquier salto se explica o se corrige.
4. **Auditorías:** `audit_ui.luau` (`roblox-ui-designer`) en teléfono chico y tablet con el emulador; `audit_remotes.luau` y `abuse_test.luau` (`roblox-security`).
5. **Dispositivo real** (persona): abrir el juego publicado en el teléfono base y medir el tiempo hasta poder jugar, la memoria en la Developer Console, los controles táctiles (zonas reservadas) y si los textos se leen.
6. **Escribir `docs/qa.md`** con la checklist, las fotos de rendimiento y los problemas encontrados (cada uno con su dueño), y mostrarlo.

## Checklist
Ver `references/checklist.md`. Bloqueantes: errores en consola, una auditoría con ERROR, crash o carga de más de 60 s en el dispositivo base, y compras o datos que fallan.

## Límites
- Los números de Studio orientan pero no reemplazan el dispositivo real.
- No hay umbrales oficiales de memoria o partes: se compara contra el propio historial y el dispositivo base.
- No arregla: deriva cada falla al skill dueño.
