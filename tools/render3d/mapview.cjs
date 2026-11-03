// Vista previa del mapa que arma MapKit para una receta del armador: vuelca el plan con el CLI de Luau
// (map/dump.luau, la misma lógica que corre en el servidor) y lo dibuja con three.js en Chromium sin
// pantalla. Sirve para revisar el armado de una receta sin abrir Studio (y para mostrarlo en el PR).
//
//   cd tools/render3d && npm install   (una vez)
//   node tools/render3d/mapview.cjs [--recipe template/src/shared/Config/KitConfig.luau]
//        [--out games/<juego>/docs/mapa] [--view both|hero|top] [--size 1600]
//
// Sale <out>-hero.png (perspectiva sobre el lobby) y <out>-top.png (todo desde arriba). Los avisos del plan
// (lo que no entró) se muestran en la consola.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { chromium } = require('playwright');

const ROOT = path.join(__dirname, '..', '..');
const flags = { recipe: 'template/src/shared/Config/KitConfig.luau', out: 'mapa', view: 'both', size: '1600' };
const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  if (!args[i].startsWith('--') || args[i + 1] === undefined) {
    console.error('uso: node tools/render3d/mapview.cjs [--recipe ruta.luau] [--out prefijo] [--view both|hero|top] [--size 1600]');
    process.exit(2);
  }
  flags[args[i].slice(2)] = args[++i];
}

// 1) El plan, con la misma lógica de Luau que usa el servidor.
const mapDir = path.join(__dirname, 'map');
const recipe = path.resolve(ROOT, flags.recipe).replace(/\.luau$/, '');
if (!fs.existsSync(recipe + '.luau')) {
  console.error('  [error] no existe la receta ' + recipe + '.luau');
  process.exit(1);
}
// El require de Luau no sale de la carpeta del repo: una receta de afuera (sin requires propios) se
// copia a map/.preview/ (ignorada por git).
let source = recipe;
if (path.relative(ROOT, recipe).startsWith('..')) {
  const copy = path.join(mapDir, '.preview', 'recipe');
  fs.mkdirSync(path.dirname(copy), { recursive: true });
  fs.copyFileSync(recipe + '.luau', copy + '.luau');
  source = copy;
}
let relative = path.relative(mapDir, source).split(path.sep).join('/');
if (!relative.startsWith('./') && !relative.startsWith('../')) relative = './' + relative;
let plan;
try {
  const json = execFileSync('luau', [path.join(mapDir, 'dump.luau'), '-a', relative], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  plan = JSON.parse(json);
} catch (e) {
  console.error('  [error] no se pudo armar el plan: ' + (e.stderr || e.message));
  process.exit(1);
}
for (const w of plan.warnings) console.warn('  [aviso] ' + w);
console.log(`  receta ${plan.recipe}: ${plan.parts.length} partes, ${plan.groups.length} grupos, tema ${plan.theme}`);

// 2) Página con three.js y las fuentes del repo.
const roots = {
  '/three/': path.join(path.dirname(require.resolve('three')), '..', '/'),
  '/fonts/': path.join(ROOT, 'assets', 'fonts') + '/',
};
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  let file = url === '/' ? path.join(mapDir, 'page.html') : null;
  for (const [prefix, dir] of Object.entries(roots)) {
    if (url.startsWith(prefix)) file = path.join(dir, url.slice(prefix.length));
  }
  const allowed = file && (file === path.join(mapDir, 'page.html') || Object.values(roots).some((dir) => path.resolve(file).startsWith(path.resolve(dir))));
  if (!allowed || !fs.existsSync(file)) {
    res.writeHead(404);
    res.end();
    return;
  }
  const types = { '.js': 'text/javascript', '.html': 'text/html', '.ttf': 'font/ttf' };
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

async function launch() {
  const opts = { args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] };
  try {
    return await chromium.launch(opts);
  } catch (e) {
    // Sesiones en la nube: Chromium ya instalado fuera de Playwright.
    const fallback = process.env.PLAYWRIGHT_CHROMIUM || '/opt/pw-browsers/chromium';
    if (!fs.existsSync(fallback)) throw e;
    return chromium.launch({ ...opts, executablePath: fallback });
  }
}

server.listen(0, '127.0.0.1', async () => {
  let code = 0;
  const browser = await launch();
  try {
    const page = await browser.newPage({ viewport: { width: 800, height: 600 } });
    page.on('pageerror', (e) => console.error('  [página] ' + e.message));
    await page.goto(`http://127.0.0.1:${server.address().port}/`);
    await page.waitForFunction(() => window.__ready, null, { timeout: 60000 });
    const views = flags.view === 'both' ? ['hero', 'top'] : [flags.view];
    const out = path.resolve(ROOT, flags.out);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    for (const view of views) {
      const url = await page.evaluate(([p, v, s]) => window.renderMap(p, v, s), [plan, view, Number(flags.size)]);
      const file = `${out}-${view}.png`;
      fs.writeFileSync(file, Buffer.from(url.split(',')[1], 'base64'));
      console.log('  [ok] ' + path.relative(ROOT, file));
    }
  } catch (e) {
    console.error('  [error] ' + e.message);
    code = 1;
  } finally {
    await browser.close();
    server.close();
    process.exitCode = code;
  }
});
