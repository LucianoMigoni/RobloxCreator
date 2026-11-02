# Cómo cargar las claves de OpenAI y Google

Sirven para las imágenes con IA: íconos, miniaturas y anuncios (`tools/imagegen.py`). La de OpenAI es la necesaria; la de Google es opcional, para comparar. La lista completa de claves está en `team/pendientes.md`.

**Nunca** las pegues en el chat ni en un archivo del repo.

## 1. OpenAI (ChatGPT)

1. Entrá a https://platform.openai.com. Sirve la misma cuenta de ChatGPT.
2. En **Settings → Billing**, cargá saldo con **Add to credit balance**. Con USD 10 alcanza para empezar; la suscripción de ChatGPT Plus no sirve para esto.
3. En https://platform.openai.com/api-keys, tocá **Create new secret key** y copiala. Empieza con `sk-` y se ve una sola vez.
4. Si al generar imágenes pide verificar la organización: **Settings → Organization → Verify**.

## 2. Google (Gemini), opcional

1. En https://aistudio.google.com/apikey, tocá **Create API key**, elegí o creá un proyecto y copiala. Empieza con `AIza`.
2. Activá la facturación del proyecto cuando AI Studio lo pida (el modelo de imágenes la necesita).

## 3. En Claude (nube)

1. En la app de Claude, con la sesión abierta, tocá el nombre del entorno de la nube en la barra del título y después **Edit**.
2. Cargalas en **Network secrets** (en apps viejas se llama *API credentials*). Si esa sección no aparece, usá **Environment variables**, una por línea:
   ```
   OPENAI_API_KEY=sk-...
   GEMINI_API_KEY=AIza...
   ```
3. Guardá. Las toman las sesiones nuevas, no la que está abierta.

## 4. En cada PC (Windows)

En PowerShell o CMD:

```
setx OPENAI_API_KEY "sk-..."
setx GEMINI_API_KEY "AIza..."
```

Después cerrá y volvé a abrir la terminal y Claude Code.
