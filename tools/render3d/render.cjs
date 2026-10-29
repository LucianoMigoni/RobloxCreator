// Renderiza modelos .glb/.gltf a PNG con fondo transparente (three.js en Chromium sin pantalla).
// Sirve para tener referencias de los assets del juego sin abrir Blender ni Studio:
//
//   cd tools/render3d && npm install && npx playwright install chromium   (una vez)
//   node tools/render3d/render.cjs modelo.glb salida.png [--size 1024] [--yaw 30] [--pitch 14] [--distance 3.4]
//
// El recorte al borde del modelo lo hace tools/imagegen.py al cargar la referencia; acá sale el cuadro entero.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const args = process.argv.slice(2);
const flags = { size: '1024', yaw: '30', pitch: '14', distance: '3.4' };
const positional = [];
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith('--')) flags[args[i].slice(2)] = args[++i];
  else positional.push(args[i]);
}
if (positional.length !== 2) {
  console.error('uso: node render.cjs modelo.glb salida.png [--size 1024] [--yaw 30] [--pitch 14] [--distance 3.4]');
  process.exit(2);
}
const [modelPath, out] = positional.map((p) => path.resolve(p));
const roots = {
  '/three/': path.join(path.dirname(require.resolve('three')), '..', '/'),  // build/three.cjs -> raíz del paquete
  '/model/': path.dirname(modelPath) + '/',
};
const types = { '.js': 'text/javascript', '.html': 'text/html', '.glb': 'model/gltf-binary', '.gltf': 'application/json',
  '.bin': 'application/octet-stream', '.png': 'image/png', '.jpg': 'image/jpeg' };

const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  let file = url === '/' ? path.join(__dirname, 'page.html') : null;
  for (const [prefix, dir] of Object.entries(roots)) {
    if (url.startsWith(prefix)) file = path.join(dir, url.slice(prefix.length));
  }
  // Solo se sirven archivos dentro de las carpetas permitidas.
  const allowed = file && [__dirname, ...Object.values(roots)].some((dir) => path.resolve(file).startsWith(path.resolve(dir)));
  if (!allowed || !fs.existsSync(file)) {
    res.writeHead(404);
    res.end();
    return;
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

server.listen(0, '127.0.0.1', async () => {
  let code = 0;
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  try {
    const page = await browser.newPage({ viewport: { width: Number(flags.size), height: Number(flags.size) } });
    const query = new URLSearchParams({ model: path.basename(modelPath), ...flags });
    await page.goto(`http://127.0.0.1:${server.address().port}/?${query}`);
    const status = await (await page.waitForFunction(() => window.__done, null, { timeout: 60000 })).jsonValue();
    if (status !== 'ok') throw new Error(status);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    await page.locator('canvas').screenshot({ path: out, omitBackground: true });
    console.log('  [ok] ' + out);
  } catch (e) {
    console.error('  [error] ' + e.message);
    code = 1;
  } finally {
    await browser.close();
    server.close();
    process.exitCode = code;
  }
});
