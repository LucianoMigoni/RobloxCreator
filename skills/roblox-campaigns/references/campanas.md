# Campañas: guía práctica

Complementa `SKILL.md` con las piezas de cada etapa. Datos y fuentes en `skills/_shared/anuncios-2026.md`.

## 1. Etapas del lanzamiento (`--goal launch`)

| Etapa | Qué se aprende | Público | Creatividades | Señal para seguir |
|---|---|---|---|---|
| Humo (4 días) | Si el juego retiene a desconocidos | New Players | 4: una por receta principal | D1 por anuncio de 20 % o más; rebote en 60 s de 30 % o menos |
| Miniaturas (7 días) | Qué imagen hace clic | New Players | 10: 6 hipótesis + 4 variantes | Alguna con CTR de 3 % o más |
| Kids y Select (hasta el umbral) | Llegar a menores de 16 | All Players, objetivo Engagement | 3 ganadoras | Audience Reach habilitado |
| Empuje (10 días, desde jueves) | Entrar en Home | New Players | 3 ganadoras + 2 variantes nuevas | Home recommendations crece sola |

- **Juegos para chicos:** si el plan incluye la etapa `kids`, el resto del lanzamiento rinde más después de habilitar a menores de 16, porque hay más público disponible. Por eso conviene hacerla **antes** del empuje.
- **Revisión rápida:** si el usuario prefiere pagar los 100 000 Robux de la revisión rápida (devolvibles a los 90 días si el juego está en regla y llegó al umbral), se borra la etapa `kids` y su presupuesto pasa al empuje.

## 2. Premio de bienvenida por LaunchData

Ads Manager → Advanced options → launch data, con el mismo texto que el plan (`ad_humo`, `ad_empuje`...). En el juego, `Config/CampaignConfig.luau` relaciona cada código con su premio:

- **Un premio chico y no aleatorio:** un boost de 10 a 15 minutos, una mascota cosmética o moneda inicial. Se da **una sola vez por jugador** y se muestra al entrar con un popup "Welcome gift!".
- **Los share links** de cada canal externo usan otro código (`tiktok_<campaña>`), con el mismo premio o uno distinto, para comparar canales.
- **Medición:** el servicio registra un evento personalizado por código, con jugadores que entran, D1 y compras. Se lee en Creator Analytics, junto con la fuente "Sponsored ads" de Acquisition.
- **Probar antes de gastar:** la URL de prueba que da Ads Manager abre el juego con ese LaunchData.

## 3. Fuera de Roblox

**Clips verticales** (TikTok, YouTube Shorts, Instagram Reels), de 9 a 20 s:

1. El gancho en el primer segundo: la revelación rara, el robo con suspenso o el número gigante.
2. La reacción o el resultado: el SECRET aparece, el número salta, la base llena.
3. El nombre del juego en pantalla y en la descripción, con el share link del canal.

**Producción:**
- Grabar en Studio con la cámara libre o en el teléfono, con amigos jugando.
- Editar en el teléfono y usar música de moda de la propia plataforma.

**Ritmo:** de 3 a 5 clips por semana durante el lanzamiento y uno por update. Repetir lo que funciona: el mismo formato con otra criatura.

**Creadores de contenido:**
- Con 10 000 a 50 000 suscriptores, que hagan contenido de Roblox para el mismo público.
- Contrato simple:
  - Qué se entrega y para cuándo.
  - El aviso de publicidad.
  - Que no se prometan premios falsos.
  - Su share link o código propio para medir.
  - El pago.
- Nunca pedirles que inviten a dar like a cambio de premios.

**Grupo de Roblox:** el bono por unirse está permitido. Los anuncios de update van al grupo y al "Notify Me" de los eventos.

## 4. Lectura del reporte

`python tools/campaigns.py report <csv>` calcula por campaña y por creatividad:

| Métrica | Fórmula | Lectura |
|---|---|---|
| CTR | clics ÷ impresiones | La miniatura: 2–2,5 % normal, 3 % bueno, 4 % excelente |
| Tasa de juego | jugadas ÷ impresiones | Miniatura + página del juego + carga |
| CPM | gasto ÷ impresiones × 1000 | Lo caro que está el público (6 000–10 000 impresiones por dólar es lo normal) |
| CPP | gasto ÷ jugadas | El número que manda; comparar entre etapas y contra la mediana de la cuenta |
| ROAS | ganancias ÷ gasto | Solo en Earnings o con ganancias atribuidas; estimado los primeros días |

- Jugadas y ganancias tardan hasta 48 h en aparecer: no cortar por eso el primer día.
- "Muchos clics y casi ninguna jugada" puede ser demora de atribución o una página del juego que no convence (descripción, video, tiempo de carga).

## 5. Plantilla del aprendizaje (para `docs/decisiones.md`)

```
| Fecha | Campaña / etapa | Qué probamos | Resultado (CTR, CPP, D1/D7) | Decisión |
|---|---|---|---|---|
| 2026-11-12 | Launch / miniaturas | 10 miniaturas, 6 hipótesis | `numero-gigante` 4,4 % CTR; `robo-tension` 1,7 % | Variantes de `numero-gigante` para el empuje |
```
