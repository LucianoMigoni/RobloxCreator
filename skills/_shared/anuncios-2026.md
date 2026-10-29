# Publicidad y lanzamiento de juegos de Roblox (octubre 2026)

Investigación del 2026-10-28 para el skill `roblox-campaigns`.

**Fuentes:**
- Documentación oficial: `/production/promotion/*`, `/production/publishing/thumbnails`, `/production/analytics/acquisition`, `/cloud/guides/advertising` y `/cloud/guides/analytics/metrics`.
- Anuncios oficiales del DevForum (con fecha).
- Reportes de desarrolladores en el DevForum, con números.

**Límites de la investigación:**
- YouTube bloquea el acceso automatizado desde la nube ("Sign in to confirm you're not a bot") y Reddit también. De los videos más vistos solo se usaron título, canal y vistas, para saber qué temas importan.
- Los datos de cada desarrollador son **anécdotas**: sirven de rango, no de promesa.

## 1. Qué hay para publicitar un juego

| Canal | Costo | Para qué sirve | Notas |
|---|---|---|---|
| **Ads Manager** (mosaico patrocinado en Home y en búsqueda) | Pago por subasta | Tráfico inicial, probar miniaturas, juntar jugadores para Kids y Select, recuperar jugadores | El principal. Ver §2 |
| **Personalización de miniaturas** (Home) | Gratis | Que cada grupo vea la miniatura que más lo hace jugar | De 2 a 5 activas: +8,5 % de jugadas que cuentan en promedio, hasta +50 % |
| **Video de gameplay** en Home | Gratis (3 subidas por mes) | Mostrar el loop antes del clic | Superstar Baseball: +30 % jugadas desde RFY; Notoriety: +41 % |
| **Eventos del juego** ("Notify Me") | Gratis | Traer gente a una hora fija; aparecen en Charts con 1 000 inscriptos | Hasta 10 eventos activos o futuros |
| **Anuncio de update** a quienes activaron notificaciones | Gratis | Recordar el juego con cada update | 60 caracteres, uno cada 3 días |
| **Share links** con LaunchData | Gratis | Medir cada canal externo (TikTok, YouTube) y dar un premio de bienvenida | Sin límite de links |
| **Referidos** (`ReferredByPlayerId`) e invitaciones | Gratis | Que los jugadores traigan amigos | Premio para los dos |
| **Roblox Moments** + Captures API | Gratis | Los jugadores graban clips de 30 s que otros ven y desde los que entran | En búsqueda y "More"; se puede invitar a grabar en los momentos épicos |
| **Clips cortos** (TikTok, Shorts, Reels) | Tiempo o pago a editor | Viralidad de chicos y adolescentes | Fuente externa principal de los hits |
| **Creadores de contenido** | Tarifa fija o regalos | Ola de jugadores el día del video | Contrato claro y aviso de publicidad |
| **Portal ads** (el jugador cruza una puerta desde otro juego) | Por subasta | Tráfico desde otros juegos | Necesita un botón para volver |

## 2. Ads Manager: cómo funciona hoy

Fuente: `/production/promotion/ads-manager`, consultada el 2026-10-28.

- **Cuenta:**
  - 13+ con email verificado, en create.roblox.com/advertise.
  - Se paga con tarjeta (18+; la primera campaña cobra 5 USD a cuenta) o con **ad credits**, comprados con Robux de forma irreversible.
  - Los juegos del grupo tienen su propia cuenta de anuncios, con permisos de rol.
  - La conversión toma primero los Robux ganados con la tasa US 18+ y les aplica su valor mayor.
- **Objetivos:**
  - **Plays**: más jugadores al menor costo.
  - **Earnings**: jugadores que gastan, medido con ROAS. Hoy está habilitado para unos 30 000 juegos con ARPU de 6 Robux o más.
  - **Engagement**: jugadores "muy comprometidos" que cuentan para Kids y Select. Es más caro por partida y no se pausa solo al llegar al umbral.
- **Público:**
  - Todos, Nuevos (nunca jugaron o hace más de 180 días), Recientes (exige 10 000 jugadores recientes) o Inactivos de 30 a 180 días (exige 20 000).
  - Segmentación avanzada por país, edad, género, género de juego y dispositivo.
- **Presupuesto:**
  - Diario o total, con fecha y duración. Puja automática.
  - **Auto-reload** recarga un día de créditos.
  - Los créditos que sobran se devuelven al terminar.
  - Se puede cancelar hasta 6 h antes de empezar.
- **Creatividades:**
  - **Hasta 10 miniaturas por campaña**, repartidas en partes iguales y activables una por una. Se ven en 16:9.
  - Hay biblioteca de assets y generador con IA (100 pedidos por día). La comunidad rechaza las imágenes con cara de IA: usar capturas y renders reales (DevForum, 2026-07-24).
  - Video en el mosaico patrocinado "en las próximas semanas" (anunciado el 2026-10-02).
- **Dónde sale:** la misma campaña aparece en Home y en búsqueda. Correr anuncios **no cambia** el puesto en "Recommended For You".
- **Moderación:** de horas pasó a minutos (2026-10-02).
- **Aprendizaje:**
  - Las primeras 24–48 h son de aprendizaje.
  - **Cada pausa lo reinicia** (FAQ oficial del 2026-10-02), y también agregar miniaturas nuevas según varios desarrolladores.
- **Unirse con datos:**
  - Opciones avanzadas: lugar de inicio y **LaunchData**, que el juego lee con `player:GetJoinData().LaunchData`.
  - Roblox sugiere un **premio exclusivo para quien entra por el anuncio**: "Exclusive rewards are a good way to increase campaign conversion".
- **Reportes:**
  - Impresiones y clics en tiempo real. Jugadas, tiempo y ganancias por atribución durante 30 días, con hasta 48 h de demora.
  - Métricas: gasto, impresiones, clics, CTR, jugadas, tasa de juego, CPP (costo por partida), tiempo jugado, ganancias y ROAS.
  - Detalle **por miniatura** dentro de cada campaña.
- **Fraude:** Roblox devuelve el tráfico inválido 14–16 días después de terminar. Usar bots suspende la cuenta.
- **Juegos no únicos:** "pueden terminar sin gasto ni conversiones". Un clon no se puede publicitar.

### 2.1 Qué dijo Roblox con números (DevForum)

- **2026-10-02, "Ads Manager RDC Recap":**
  - En 21 estudios con grupo de control, todas las campañas trajeron jugadas incrementales: mediana de **+14 % de sesiones** y **+10 % de usuarios retenidos a D7**.
  - De más de 1 200 juegos con campañas Earnings, **2 de cada 3 que reinvirtieron hasta el 4 % de sus ganancias superaron el 100 % de ROAS**.
  - **Los juegos con alta retención reciben mejor distribución** (mejor CPP y ROAS).
  - Los mosaicos patrocinados ya llegan a **menores de 13**, con las mismas reglas de edad.
- **2026-06-16, "Kids and Select Global Launch":**
  - Objetivo Engagement en beta.
  - **Revisión rápida para Kids y Select por 100 000 Robux por juego**, que se devuelven si a los 90 días el juego está en regla y llegó al umbral. Tarda hasta 48 h y no exige el umbral de jugadores comprometidos.
  - Los links a redes solo los ven los usuarios de 16 años o más con edad verificada.
- **2026-03-20, "New Advertising Policies & Standards":**
  - Desde el 4 de mayo hay publicidad para todas las edades.
  - Para menores de 13 están **prohibidos los formatos con recompensa** y algunas categorías (comida, cosmética, farmacia y finanzas).
  - Los anuncios con premio externos se migraron al formato nativo.
  - Las integraciones de marca se registran y llevan etiqueta.

### 2.2 Qué reportan los desarrolladores (2026)

| Dato | Valor | Fuente (DevForum) |
|---|---|---|
| CTR promedio de un mosaico patrocinado | 2–2,5 %; **bueno desde 3 %, excelente desde 4 %**; menos de 2 % = cambiar la miniatura | tema 4735473 (2026-07-15) |
| Mejor miniatura después de probar unas 50 | 3,1–3,6 % de CTR (antes 1,8 %) | 4960622 (2026-10-27) |
| Impresiones por dólar | 6 000–10 000 lo normal; 3 000 = público caro | 4960622 |
| CPP de una campaña Plays normal | **0,013 créditos por jugada** (39,49 créditos → 2 950 jugadas) | 4934157 (2026-10-14) |
| CPP de una campaña Earnings mal calibrada | 1,38 por jugada (45,7 créditos → 33 jugadas); "la subasta está inflada esta semana" | 4934157 |
| Campaña chica para Kids y Select | 10 créditos en 2 días: 13 000 impresiones, CTR 2,36 %, unas 200 jugadas | 4806311 (2026-08-12) |
| Consejo para llegar al umbral | Unos 16 créditos por día en Plays hasta llegar; después Home acelera | 4806311 |
| 100 USD con CTR del 5 % | 135 jugadores muy comprometidos | 4920507 (2026-10-08) |
| Juego solo 16+ con 20 USD por día | 4 veces menos impresiones que otro igual meses antes (menos público disponible) | 4696745 (2026-06-21) |
| Advertencia | En algunos juegos ya establecidos, **cortar los anuncios duplicó el tiempo de juego** y después Home los empujó: el tráfico pago de menor calidad bajó sus métricas | 4909790, respuestas (2026-10-02) |
| Juegos multijugador obligatorios | Los anuncios traen gente de a uno ("goteo"): caro e ineficaz si el juego necesita 6 jugadores | 4806311 |

Lectura para nosotros:

1. **El anuncio no arregla un juego malo, lo amplifica.** Primero el primer minuto, la retención D1 y una vitrina con PTR sano. Recién después, escalar.
2. **El CTR lo decide la miniatura.** Probar muchas: 10 por campaña, renovando las que pierden.
3. **Los hits que apuntan a chicos necesitan Kids y Select.** Sin eso el público disponible es 16+ y los anuncios rinden peor.
4. **Nuestros juegos no dependen de tener muchos jugadores a la vez:** se juegan solos y el robo es opcional, así que el goteo de anuncios no los rompe.

## 3. Cuánto poner: presupuestos de referencia

Los ad credits se compran en USD o con Robux (Ads Manager muestra la conversión antes de confirmar). Los montos y umbrales de esta tabla son **criterio del hub**, armado con los datos de §2: puntos de partida para medir, no garantías.

| Etapa | Objetivo | Presupuesto | Duración | Pasa a la siguiente si… |
|---|---|---|---|---|
| 0. Prueba de humo | ¿El juego retiene a desconocidos? | 10–20 USD por día | 3–4 días, desde un jueves | D1 de los que llegan por anuncio ≥ 20 % y rebote en 60 s ≤ 30 % |
| 1. Miniaturas | ¿Qué imagen hace clic? | 15–30 USD por día, 6 a 10 miniaturas | 5–7 días | Alguna con CTR ≥ 3 % y CPP en el rango normal del momento |
| 2. Kids y Select | Llegar a menores de 16 | Plays u Engagement, 15–20 USD por día, o revisión rápida de 100 000 Robux (devolvible) | Hasta llegar al umbral | Juego habilitado para menores de 16 |
| 3. Empuje | Entrar en Home | 50–150 USD por día, empezando el jueves para llegar al pico del sábado | 7–10 días, sin pausar | Home recommendations sube sola y los que llegan por Home retienen |
| 4. Mantenimiento | Recuperar y monetizar | Earnings (si está habilitado): hasta el 4 % de las ganancias, con ROAS ≥ 100 %; Inactivos o Nuevos con cada update grande | Continuo | ROAS ≥ 100 % estimado |

Reglas de corte (criterio del hub, ajustable por juego; se revisan cada 24 h después de las primeras 48):
- **CTR menor a 2 %** con más de 20 000 impresiones: apagar esa miniatura.
- **CPP mayor a 3 veces la mediana** de las campañas de la cuenta, sostenido por 48 h: revisar la segmentación o cortar.
- **D7 de los que llegan por anuncio menor a la mitad del D7 orgánico:** el anuncio trae mal público o el primer minuto falla. Pausar y arreglar el juego antes de seguir gastando.
- **Earnings con ROAS estimado menor al 70 %** a los 7 días: bajar el presupuesto. Con 100 % o más, subir de a 20–30 % por vez.

## 4. Fuera de Roblox

- **Clips cortos** (TikTok, YouTube Shorts, Instagram Reels):
  - Es la principal fuente externa de jugadores según los desarrolladores del DevForum (temas 4016948 y 4932602).
  - Roblox cuenta más de un billón de vistas de contenido de Roblox en YouTube (anuncio de Moments, 2025-09-05).
  - Qué funciona: el loop en los primeros 2 segundos, la revelación rara ("1 in 1,000,000"), el robo con suspenso, la reacción, el número gigante.
  - Formato vertical 9:16, sin voz en off obligatoria (música de moda) y con el título del juego visible.
  - Cada canal con su share link (Creator Hub → Creations → Share Links) para medir jugadas, D7 y gasto por canal.
- **Creadores de contenido:**
  - Chicos (10 000–50 000 suscriptores) con contenido de Roblox para chicos.
  - Pagar por video, con aviso de publicidad.
  - Darles un código o un share link propio para medir.
  - Por contrato, el contenido no promete recompensas falsas ni pide likes a cambio de premios.
- **La comunidad:** grupo de Roblox (bono por unirse, permitido) y anuncios de update en el grupo. Los links a redes solo los ve el público de 16+.

## 5. APIs para automatizar (Open Cloud)

| API | Qué hace | Estado | Permisos |
|---|---|---|---|
| Ads API `https://apis.roblox.com/ads-management/v1` | Lista juegos publicitables (`advertisable-universes`), opciones (`campaign-options`), crea campañas (`POST campaigns` con `x-idempotency-key`), estado (`campaigns:batchGetStatus`), pausa, reanuda y presupuesto (`PATCH campaigns/{id}`) | **Experimental**: puede cambiar | `ad.campaign:read`, `ad.campaign:write` y `ad.billing:read`. Solo clave de usuario, no de grupo |
| Analytics Query API | Métricas por día: retención, adquisición por fuente (`QualifiedEndToEndCVR`, `ImpressionCVR`), señales de Home (`RFY*`) y miniaturas (`ThumbnailQualifiedPTR`, `ThumbnailImpressions`, `ThumbnailQualifiedPlays`) | Estable | `universe.analytics:read` |
| Thumbnail Personalization API | Subir y activar miniaturas de Home | Experimental, cuerpos sin documentar | `universe.thumbnail:read` y `write` |
| Events and Updates API | Crear eventos con "Notify Me" | Nueva | `virtual-events` |
| Assets API | Subir las imágenes de las campañas y obtener su id | Beta | `asset:read` y `write` |

Detalles de la Ads API (documentación del 2026-10-28):
- En v1, el objetivo `ENGAGEMENT` es "llevar visitas".
- `paymentType` admite `CREDIT_CARD`, `ADS_CREDIT` o `INVOICE`.
- Presupuesto en **micro-USD como texto** (`"5000000"` = 5 USD), `DAILY` o `LIFETIME`, con un mínimo que informa el error.
- `schedule`: `startTime` (no en el pasado) y `durationInDays` (no acepta `endTime`).
- Segmentación: `ageGroups` (`AGE_13_17`, `AGE_18_24`, `AGE_25_PLUS`), `countries` (ISO) y `devices` (`PHONE`, `TABLET`, `DESKTOP`, `CONSOLE`).
- Sube el presupuesto en el acto; lo baja a la medianoche de la cuenta.
- El rendimiento no está en esta API: va por Analytics o por la exportación del dashboard.

`tools/campaigns.py` usa la Ads API con simulación por defecto. Para gastar hace falta `--yes`, porque crear una campaña gasta dinero real.

## 6. Los videos más vistos (para entender qué preocupa)

Búsqueda "roblox ads manager 2026" en YouTube (2026-10-28):

| Video | Canal | Vistas |
|---|---|---|
| How I Advertise My Games on Roblox | Yann | 108 000 |
| How to make an ad campaign with Roblox Ads Manager | **Roblox Creators** (oficial) | 95 000 |
| I Spent 100K Robux Advertising My Roblox Game | Yann | 94 000 |
| How To ACTUALLY Advertise A Roblox Game | bubDEV | 91 000 |
| What I Learned After Spending 50,000 Robux on Ads | Raul | 32 000 |
| The Exact Roblox Ads Strategy I Use on Every Game I Launch | MoseyTube77 | 47 000 |

Los temas que más se repiten coinciden con lo de arriba:
- Cuánto gastar y en qué orden.
- Probar miniaturas.
- Retención antes de escalar.
- Experimentos de "gasté X Robux, estos son los resultados".
