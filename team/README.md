# Cómo trabajamos

Dos personas, cada una con su IA, sobre un solo repo. El tablero (`tareas.md`) dice quién hace qué. Las decisiones quedan en `decisiones.md` y todo entra a `main` por Pull Request.

## Flujo diario

1. **Actualizar:** `git switch main && git pull`.
2. **Tomar una tarea** de "Pendiente" en `tareas.md` (los detalles de cada paso del hub están en `ROADMAP.md`).
3. **Rama:** `git switch -c <persona>/<tarea>` (ej. `leonel/ui-inventario`).
4. **Marcarla:** moverla a "En curso" con tu `@` y tu rama, commit, push, y abrir el PR **como borrador** (`gh pr create --draft --fill`). El borrador es lo que avisa al otro que la tarea ya está tomada.
5. **Trabajar con la IA:** "hacé la tarea *X* de `team/tareas.md`". La IA sigue `CLAUDE.md` y el skill de la fase.
6. **Cerrar:** mover la tarea a "Hecho", anotar las decisiones (las del hub en `team/decisiones.md`, las de un juego en `games/<juego>/docs/decisiones.md`), commit y push.
7. **Pedir revisión:** sacar el PR de borrador (`gh pr ready`). La descripción dice qué se hizo, cómo se probó y lo que falta (con capturas si hay UI).
8. **Revisión:** el otro revisa, pide cambios o aprueba. Con la aprobación, merge a `main` y borrar la rama.

Una tarea en curso por persona. Si `main` avanzó mientras trabajabas: `git merge main` en tu rama antes de pedir revisión. En un conflicto en `tareas.md`, quedarse con las líneas de los dos.

## Para las IAs

Cuando te pidan una tarea de `tareas.md`:

1. Leer `CLAUDE.md`, la línea de la tarea y, si es del hub, su paso en `ROADMAP.md`.
2. Confirmar que estás en la rama de la tarea (nunca en `main`). Si no existe, crearla con el formato `<persona>/<tarea>`.
3. Al terminar: mover la línea a "Hecho" (cambiar `[ ]` por `[x]` y agregar la fecha), anotar decisiones y actualizar la fila de `ROADMAP.md` si es un paso del hub, todo en el mismo commit que el trabajo.
4. Lo que quede pendiente (algo que necesita a una persona, una prueba en Windows o en Studio) va como tarea nueva en "Pendiente", con el `@` de quien tiene que hacerlo.

## Formato del tablero

```
- [ ] <tarea> — <área> · @<persona> · rama <rama> · juego: <juego|hub>
```

- `área`: hub, servidor, cliente, mapa, ui, docs…
- Sin asignar: `@nadie`. Sin rama todavía: `rama —`.
- En "Hecho": `- [x] … · <fecha AAAA-MM-DD>`.
