// Íconos 3D estilo hit hechos por código (three.js en Chromium sin pantalla): modelos simples con
// sombreado de dibujo animado (tres tonos planos y un brillo blanco duro), contorno por pieza y contorno
// oscuro grueso por fuera, como los de Anime Dice, Steal An Egg, Throw Food For Animals o PS99
// (skills/roblox-ui-designer/references/hud-hits.md §Íconos). No usa IA: salen iguales cada vez, sin
// límite y son nuestros.
//
//   cd tools/render3d && npm install && npx playwright install chromium   (una vez)
//   node tools/render3d/icons.cjs list
//   node tools/render3d/icons.cjs render [nombre ...] [--out assets/ui/icons3d] [--size 512] [--style 3d|glyph|both]
//   node tools/render3d/icons.cjs flat [nombre ...] [--out assets/ui/icons-flat] [--size 256]
//
// --style glyph saca la versión plana (blanca con contorno) para botones chicos, como los de Steal An Egg.
// Los modelos están en icons/models.js: para uno nuevo, agregar una función con el nombre del ícono.
// `flat` pasa a PNG los SVG de <out>/svg (los baja tools/flat_icons.py): blanco con contorno y, en plain/,
// blanco liso.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const args = process.argv.slice(2);
const cmd = args.shift();
const flags = { out: path.join(__dirname, '..', '..', 'assets', 'ui', 'icons3d'), size: '512', style: '3d' };
const names = [];
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith('--')) flags[args[i].slice(2)] = args[++i];
  else names.push(args[i]);
}
if (!['list', 'render', 'flat'].includes(cmd)) {
  console.error('uso: node icons.cjs list | render [nombre ...] [--out carpeta] [--size 512] [--style 3d|glyph|both] | flat [nombre ...] [--out carpeta] [--size 256]');
  process.exit(2);
}
if (cmd === 'flat') {
  if (!args.includes('--out')) flags.out = path.join(__dirname, '..', '..', 'assets', 'ui', 'icons-flat');
  if (!args.includes('--size')) flags.size = '256';
}

const roots = {
  '/three/': path.join(path.dirname(require.resolve('three')), '..', '/'), // build/three.cjs -> raíz del paquete
  '/icons/': path.join(__dirname, 'icons') + '/',
};
const types = { '.js': 'text/javascript', '.html': 'text/html', '.json': 'application/json' };

const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  let file = url === '/' ? path.join(__dirname, 'icons', 'page.html') : null;
  for (const [prefix, dir] of Object.entries(roots)) {
    if (url.startsWith(prefix)) file = path.join(dir, url.slice(prefix.length));
  }
  // Solo se sirven archivos dentro de las carpetas permitidas.
  const allowed = file && Object.values(roots).some((dir) => path.resolve(file).startsWith(path.resolve(dir)));
  if (!allowed || !fs.existsSync(file)) {
    res.writeHead(404);
    res.end();
    return;
  }
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
    const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
    page.on('pageerror', (e) => console.error('  [página] ' + e.message));
    await page.goto(`http://127.0.0.1:${server.address().port}/`);
    await page.waitForFunction(() => window.__ready, null, { timeout: 60000 });
    if (cmd === 'flat') {
      const svgDir = path.join(flags.out, 'svg');
      const files = fs.readdirSync(svgDir).filter((f) => f.endsWith('.svg') && (!names.length || names.includes(f.slice(0, -4))));
      if (!files.length) throw new Error('no hay SVG en ' + svgDir + ' (python tools/flat_icons.py fetch)');
      fs.mkdirSync(path.join(flags.out, 'plain'), { recursive: true });
      for (const f of files) {
        const svg = fs.readFileSync(path.join(svgDir, f), 'utf8');
        for (const [outlined, dir] of [[true, flags.out], [false, path.join(flags.out, 'plain')]]) {
          const url = await page.evaluate(([t, size, o]) => window.renderFlat(t, size, o), [svg, Number(flags.size), outlined]);
          fs.writeFileSync(path.join(dir, f.replace('.svg', '.png')), Buffer.from(url.split(',')[1], 'base64'));
        }
        console.log('  [ok] flat ' + f.slice(0, -4));
      }
      return;
    }
    const all = await page.evaluate(() => window.iconNames());
    if (cmd === 'list') {
      console.log(all.join('\n'));
      return;
    }
    const wanted = names.length ? names : all;
    const unknown = wanted.filter((n) => !all.includes(n));
    if (unknown.length) throw new Error('íconos desconocidos: ' + unknown.join(', '));
    const styles = flags.style === 'both' ? ['3d', 'glyph'] : [flags.style];
    for (const style of styles) {
      const dir = style === 'glyph' ? path.join(flags.out, 'glyph') : flags.out;
      fs.mkdirSync(dir, { recursive: true });
      for (const name of wanted) {
        const url = await page.evaluate(([n, s, size]) => window.renderIcon(n, s, size), [name, style, Number(flags.size)]);
        fs.writeFileSync(path.join(dir, name + '.png'), Buffer.from(url.split(',')[1], 'base64'));
        console.log(`  [ok] ${style} ${name}`);
      }
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
