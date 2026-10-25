# Checklist antes de cada publicación

Copiar en `docs/qa.md` con fecha y versión, y marcar. **B** = bloqueante: si falla, no se publica.

## Código
- [ ] **B** `python tools/check.py` en verde (tipos, tests, reglas de seguridad y de monetización).
- [ ] **B** Los remotes nuevos pasaron por `roblox-security` (`audit_remotes.luau` y `abuse_test.luau` sin ERROR).

## Playtest en Studio (MCP)
- [ ] **B** `get_console_output` sin errores durante el primer minuto y durante una compra.
- [ ] El primer minuto se juega sin leer: acción en segundos (bounce).
- [ ] Los pasos del embudo de onboarding se disparan en orden (ver en la salida o en analíticas de prueba).
- [ ] **B** Datos: comprar algo, salir y volver; persiste (en la copia de prueba con acceso a API).

## UI y controles
- [ ] **B** `audit_ui.luau` sin ERROR en teléfono chico horizontal y en tablet (emulador).
- [ ] Nada interactivo en las zonas del joystick y del salto, ni bajo la barra de Roblox.
- [ ] Textos legibles en el teléfono chico.

## Rendimiento
- [ ] `perf_snapshot.luau` (Client y Server) anotado y comparado con la versión anterior; los saltos están explicados.
- [ ] `StreamingEnabled` activado, salvo un motivo anotado.
- [ ] Mallas nuevas registradas en el catálogo con ≤ 20 000 triángulos.

## Dispositivo base real (persona)
- [ ] **B** Entra y se puede jugar en menos de 60 s.
- [ ] **B** 15 minutos de juego sin crash; memoria estable en la Developer Console (sin `LuaHeap` creciendo).
- [ ] Controles táctiles cómodos con dos pulgares.

## Contenido y publicación
- [ ] `roblox-compliance` al día si cambió contenido o texto de jugadores.
- [ ] `roblox-monetization`: auditoría al día si cambió la tienda.
- [ ] Changelog escrito (`roblox-liveops`).
