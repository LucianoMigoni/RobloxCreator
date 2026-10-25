# Checklist de cumplimiento

Copiar en `docs/cumplimiento.md` con fecha y versión del juego. **B** = bloqueante: si falla, no se publica.

## Inventario para el cuestionario Maturity & Compliance
Para cada categoría: ¿hay? ¿dónde? ¿intensidad y frecuencia? Responder por el **momento más extremo** del juego, incluidos assets, título, descripción y miniaturas. Categorías oficiales (`/production/promotion/content-maturity`):

| Categoría | Qué anotar | Ojo |
|---|---|---|
| Violencia | Leve, moderada o fuerte; ocasional o repetida | Si la consecuencia es realista aunque sea una vez, ya no es leve. Fuerte = solo 18+ |
| Sangre | Realista o no; poca o mucha | Sangre realista abundante = solo 18+ |
| Miedo | Intensidad y frecuencia | Una parte chica repetida ya cuenta como repetida |
| Humor grosero | Leve o moderado | |
| Apuestas no jugables | Si se muestran (un casino de fondo) | Las apuestas jugables están prohibidas |
| Lenguaje fuerte | Si lo hay o se habilita | Solo 18+ |
| Temas románticos, espacios privados o para adultos | Incluido el título | Solo 18+ |
| Alcohol | Mostrado o mencionado | Solo 18+ |
| Social hangout | Si charlar es la actividad principal; espacios privados | 16+; con espacios privados, 18+ |
| Creación libre | Dibujar o escribir libremente | 16+. Construir con piezas 3D no cuenta |
| Tema sensible | Si es el tema principal | 16+ |
| Ítems aleatorios pagos | Si hay; si se respeta `ArePaidRandomItemsRestricted` | |
| Comercio de ítems pagos | Si hay; si se respeta `IsPaidItemTradingAllowed` | |
| Medios | Compartir capturas o videos; feeds con carga continua o autoplay; contenido de otros juegos | `IsContentSharingAllowed` |
| IA | Si los jugadores interactúan con IA generativa y de qué forma | No cuenta haber usado IA para hacer el juego |

- [ ] **B** Inventario completo y revisado por el usuario.
- [ ] Etiqueta esperada anotada y compatible con el público objetivo (si no, cambio de contenido propuesto).
- [ ] **B** Cuestionario enviado por una persona en **Publish settings → Content rating**, con la vista previa (etiqueta, descriptores y regiones no conformes) copiada en `docs/cumplimiento.md`.
- [ ] **B** En cada update: si cambió alguna respuesta, cuestionario reenviado.

## Texto de jugadores
- [ ] **B** Lista de todos los lugares donde un jugador escribe algo que otro ve (fuera del chat de Roblox).
- [ ] **B** Cada uno se filtra en el servidor con `TextService:FilterStringAsync` dentro de `pcall`, y después `GetNonChatStringForBroadcastAsync` o `GetNonChatStringForUserAsync`.
- [ ] **B** Si el filtrado falla, el texto no se muestra a nadie.
- [ ] El texto guardado (DataStores) se vuelve a filtrar al mostrarlo.
- [ ] El remote que recibe el texto valida largo máximo y frecuencia (`roblox-security`).

## Políticas por jugador
- [ ] **B** Cada producto o función con política consulta `PolicyService:GetPolicyInfoForPlayerAsync` en el servidor (con `pcall`) y la oculta o bloquea cuando no corresponde: aleatorios pagos, comercio de ítems pagos, anuncios, suscripciones, productos comerciales, compartir contenido.
- [ ] Si la consulta falla, se asume la opción restrictiva.

## Contenido y propiedad intelectual
- [ ] **B** Ningún asset sin `commercialUse: true` en el catálogo, ni marcas, personajes, música o imágenes ajenas sin licencia.
- [ ] Título, descripción, icono y miniaturas muestran lo que hay en el juego, sin promesas de Robux ni recompensas.
- [ ] Textos del juego aptos para todo público (Community Standards).

## Cuenta dueña del juego (persona)
Para llegar a menores de 16:
- [ ] Verificación de la cuenta (estimación facial si es menor de 18; documento si es mayor).
- [ ] 2FA activado.
- [ ] Roblox Plus o Premium activo hace 2 meses seguidos, o tarifa reembolsable de 1000 Robux pagada (**Audience → Reach**).
- [ ] Evaluación en curso: seguimiento en **Audience Reach** (250 jugadas únicas de jugadores 16+ muy comprometidos en 60 días).
