# Plantillas de live ops

## `docs/liveops.md`: calendario

Actualizar al empezar cada ciclo. Fechas en formato AAAA-MM-DD.

**Señal a mejorar este ciclo** (de `docs/metricas.md`): …
**Update grande en curso:** … (entrega estimada: …)

| Semana | Tipo | Qué | Métrica objetivo | Dueño | Estado |
|---|---|---|---|---|---|
| … | Cadencia | Ej.: 3 mascotas nuevas sobre el sistema existente | Play days D2–7 | … | |
| … | Evento | Ej.: torneo de pesca, del … al … | Co-play days, sesiones | … | |
| … | QoL | Ej.: tienda con menos toques | Spend days | … | |
| … | Arreglo | Ej.: error al reconectar | Bounce < 60 s | … | |

Eventos del ciclo:
| Evento | Inicio | Fin | Recompensas (y su efecto en la economía) | Oferta auditada | Experience Event creado | Comunicado |
|---|---|---|---|---|---|---|
| … | … | … | … | sí/no | sí/no | dentro / fuera del juego, fecha |

## `docs/changelog/AAAA-MM-DD.md`: un archivo por update

```markdown
# Versión <número> — AAAA-MM-DD

**Tipo:** cadencia | update grande | QoL | arreglo
**Por qué:** la señal que se quiere mover y el dato que lo motivó (fuente y fecha).
**Métrica objetivo:** <métrica>, de <valor actual> a <valor esperado>. Revisión: AAAA-MM-DD.

## Para jugadores
(Texto que se puede publicar, **en inglés** (regla del hub): corto, sin presión ni promesas.)
- Nuevo: …
- Mejoras: …
- Arreglos: …

**Anuncio (≤ 60 caracteres):** …

## Para el equipo
- PR: <enlace>
- QA: `docs/qa.md` (fecha) — bloqueantes: ninguno
- Cumplimiento: sin cambios | cuestionario reenviado el AAAA-MM-DD
- Monetización: sin cambios | auditoría del AAAA-MM-DD
- Miniaturas nuevas en prueba: sí/no

## Revisión (completar en la fecha)
- Resultado: <métrica> pasó de … a … (misma ventana de días de la semana).
- Decisión: se mantiene | se ajusta | se revierte, y por qué.
```
