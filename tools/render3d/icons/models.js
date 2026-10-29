// Modelos de los íconos 3D (tools/render3d/icons.cjs). Cada función devuelve { object, yaw, pitch, fill }:
// el objeto armado con piezas simples (cajas redondeadas, extrusiones, tornos y tubos) y el ángulo de
// cámara. Colores saturados y formas gordas de juguete, como los íconos de los hits.
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { TextGeometry } from 'three/addons/geometries/TextGeometry.js';
import { FontLoader } from 'three/addons/loaders/FontLoader.js';
import { toon } from './toon.js';

let FONT = null;
export async function loadFont() {
  FONT = await new FontLoader().loadAsync('/three/examples/fonts/helvetiker_bold.typeface.json');
}

// --- materiales -------------------------------------------------------------------------------
// Todos con el sombreado de dibujo (toon.js): el "material" solo cambia color, brillo y transparencia.

const plastic = (color, o = {}) => toon(color, { glow: o.glow ?? 0, spec: o.spec ?? 0.75, flat: o.flat });
const metal = (color, o = {}) => toon(color, { spec: 1, shininess: 34, glow: o.glow ?? 0.04, shade: [0.78, 0.6, 0.48] });
const gold = () => metal(0xffc21f);
const silver = () => toon(0xd3dbe6, { spec: 1, shininess: 40, shade: [0.66, 0.68, 0.8] });
const gem = (color) => toon(color, { flat: true, spec: 1, shininess: 30, glow: 0.08, lift: 0.1 });
const glass = (color, opacity = 0.5) => toon(color, { opacity, spec: 1, shininess: 50, lift: 0.15 });
const light = (color, intensity = 0.7) => toon(color, { glow: intensity * 0.45, spec: 0.6 });
function texture(draw, w = 512, h = 512) {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  draw(c.getContext('2d'), w, h);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.NoColorSpace;
  t.anisotropy = 8;
  return t;
}
const painted = (map, o = {}) => toon(0xffffff, { map, spec: o.spec ?? 0.5 });

// --- piezas -----------------------------------------------------------------------------------

function mesh(geo, mat, pos = [0, 0, 0], rot = [0, 0, 0], scale = 1) {
  const m = new THREE.Mesh(geo, mat);
  m.position.set(...pos);
  m.rotation.set(...rot);
  if (Array.isArray(scale)) m.scale.set(...scale);
  else m.scale.setScalar(scale);
  return m;
}
const group = (...children) => {
  const g = new THREE.Group();
  for (const c of children) g.add(c);
  return g;
};
const rbox = (w, h, d, r = 0.08) => new RoundedBoxGeometry(w, h, d, 5, Math.min(r, w / 2, h / 2, d / 2));
function extrude(shape, depth, bevel = 0.06, curve = 40) {
  const g = new THREE.ExtrudeGeometry(shape, {
    depth, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 5, curveSegments: curve,
  });
  g.center();
  return g;
}
function lathe(points, segments = 64) {
  return new THREE.LatheGeometry(points.map(([x, y]) => new THREE.Vector2(x, y)), segments);
}
function tube(points, radius, closed = false) {
  const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(...p)), closed);
  return new THREE.TubeGeometry(curve, 96, radius, 20, closed);
}
function arcPoints(r, from, to, steps = 24, z = 0) {
  const pts = [];
  for (let i = 0; i <= steps; i++) {
    const a = THREE.MathUtils.degToRad(from + ((to - from) * i) / steps);
    pts.push([Math.cos(a) * r, Math.sin(a) * r, z]);
  }
  return pts;
}
function text(str, size, depth, bevel = 0.02) {
  const g = new TextGeometry(str, {
    font: FONT, size, depth, curveSegments: 12, bevelEnabled: true, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 3,
  });
  g.center();
  return g;
}

// --- formas 2D ----------------------------------------------------------------------------------

function roundedRect(w, h, r) {
  const s = new THREE.Shape();
  const x = -w / 2, y = -h / 2;
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y);
  s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, y + h - r);
  s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h);
  s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, y + r);
  s.quadraticCurveTo(x, y, x + r, y);
  return s;
}
function star(points = 5, outer = 1, inner = 0.5, roundness = 0.0) {
  const s = new THREE.Shape();
  for (let i = 0; i <= points * 2; i++) {
    const r = i % 2 === 0 ? outer : inner;
    const a = Math.PI / 2 + (i * Math.PI) / points;
    const x = Math.cos(a) * r, y = Math.sin(a) * r;
    if (i === 0) s.moveTo(x, y);
    else s.lineTo(x, y);
  }
  return s;
}
function heart(size = 1) {
  const s = new THREE.Shape();
  const k = size;
  s.moveTo(0, -0.95 * k);
  s.bezierCurveTo(-0.35 * k, -0.62 * k, -1.0 * k, -0.25 * k, -1.0 * k, 0.25 * k);
  s.bezierCurveTo(-1.0 * k, 0.72 * k, -0.42 * k, 0.95 * k, 0, 0.5 * k);
  s.bezierCurveTo(0.42 * k, 0.95 * k, 1.0 * k, 0.72 * k, 1.0 * k, 0.25 * k);
  s.bezierCurveTo(1.0 * k, -0.25 * k, 0.35 * k, -0.62 * k, 0, -0.95 * k);
  return s;
}
function polygon(pts) {
  const s = new THREE.Shape();
  pts.forEach(([x, y], i) => (i === 0 ? s.moveTo(x, y) : s.lineTo(x, y)));
  s.closePath();
  return s;
}
const bolt = () => polygon([[0.1, 1], [-0.7, -0.1], [-0.08, -0.1], [-0.36, -1], [0.7, 0.22], [0.08, 0.22], [0.48, 1]]);
function gear(teeth = 8, outer = 1, inner = 0.78, hole = 0.34) {
  const s = new THREE.Shape();
  const step = (Math.PI * 2) / teeth;
  for (let i = 0; i < teeth; i++) {
    const a = i * step;
    const pts = [[inner, a - step * 0.5], [inner, a - step * 0.27], [outer, a - step * 0.17], [outer, a + step * 0.17], [inner, a + step * 0.27]];
    pts.forEach(([r, ang], j) => {
      const x = Math.cos(ang) * r, y = Math.sin(ang) * r;
      if (i === 0 && j === 0) s.moveTo(x, y);
      else s.lineTo(x, y);
    });
  }
  s.closePath();
  const h = new THREE.Path();
  h.absarc(0, 0, hole, 0, Math.PI * 2, true);
  s.holes.push(h);
  return s;
}
function arrow(len = 1.8, shaft = 0.36, head = 0.86, headLen = 0.7) {
  const x0 = -len / 2, x1 = len / 2 - headLen;
  return polygon([[x0, -shaft / 2], [x1, -shaft / 2], [x1, -head / 2], [len / 2, 0], [x1, head / 2], [x1, shaft / 2], [x0, shaft / 2]]);
}
function ticket(w = 1.9, h = 1.1, notch = 0.22, r = 0.12) {
  const s = new THREE.Shape();
  const x = -w / 2, y = -h / 2;
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y);
  s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, -notch);
  s.absarc(x + w, 0, notch, -Math.PI / 2, Math.PI / 2, true);
  s.lineTo(x + w, y + h - r);
  s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h);
  s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, notch);
  s.absarc(x, 0, notch, Math.PI / 2, -Math.PI / 2, true);
  s.lineTo(x, y + r);
  s.quadraticCurveTo(x, y, x + r, y);
  return s;
}
function crescent() {
  const s = new THREE.Shape();
  s.absarc(0, 0, 1, Math.PI * 0.22, Math.PI * 1.78 + Math.PI * 0.0, false);
  s.absarc(0.42, 0.12, 0.78, Math.PI * 1.62, Math.PI * 0.42, true);
  return s;
}
function shield(w = 1.6, h = 1.9) {
  const s = new THREE.Shape();
  s.moveTo(0, h / 2);
  s.bezierCurveTo(w * 0.22, h * 0.42, w * 0.38, h * 0.4, w / 2, h * 0.38);
  s.bezierCurveTo(w / 2, -h * 0.05, w * 0.32, -h * 0.32, 0, -h / 2);
  s.bezierCurveTo(-w * 0.32, -h * 0.32, -w / 2, -h * 0.05, -w / 2, h * 0.38);
  s.bezierCurveTo(-w * 0.38, h * 0.4, -w * 0.22, h * 0.42, 0, h / 2);
  return s;
}
const check = () => polygon([[-0.82, 0.08], [-0.48, 0.4], [-0.2, 0.12], [0.5, 0.82], [0.84, 0.48], [-0.2, -0.56]]);
function plus(size = 1, t = 0.36) {
  const a = size / 2, b = t / 2;
  return polygon([[-b, a], [b, a], [b, b], [a, b], [a, -b], [b, -b], [b, -a], [-b, -a], [-b, -b], [-a, -b], [-a, b], [-b, b]]);
}
function cross(size = 1, t = 0.36) {
  const s = plus(size, t);
  const g = new THREE.Shape(s.getPoints().map((p) => p.clone().rotateAround(new THREE.Vector2(0, 0), Math.PI / 4)));
  return g;
}
function shoe() {
  // Perfil de zapatilla mirando a la derecha.
  const s = new THREE.Shape();
  s.moveTo(-1.02, -0.34);
  s.lineTo(0.95, -0.34);
  s.bezierCurveTo(1.18, -0.34, 1.22, -0.02, 1.0, 0.06);
  s.bezierCurveTo(0.78, 0.14, 0.5, 0.18, 0.28, 0.3);
  s.bezierCurveTo(0.08, 0.42, -0.06, 0.6, -0.2, 0.66);
  s.bezierCurveTo(-0.42, 0.74, -0.7, 0.72, -0.86, 0.6);
  s.bezierCurveTo(-1.02, 0.48, -1.1, 0.1, -1.02, -0.34);
  return s;
}
function sole() {
  const s = new THREE.Shape();
  s.moveTo(-1.08, -0.52);
  s.lineTo(1.0, -0.52);
  s.bezierCurveTo(1.22, -0.52, 1.26, -0.3, 1.12, -0.26);
  s.lineTo(-1.1, -0.26);
  s.bezierCurveTo(-1.16, -0.32, -1.16, -0.5, -1.08, -0.52);
  return s;
}
function arm() {
  // Brazo y antebrazo en L mirando a la derecha; el bíceps y el puño van como piezas aparte.
  const s = new THREE.Shape();
  s.moveTo(-1.0, -0.62);
  s.bezierCurveTo(-0.5, -0.76, 0.35, -0.8, 0.62, -0.64);
  s.bezierCurveTo(0.88, -0.48, 0.88, -0.2, 0.82, 0.1);
  s.lineTo(0.76, 0.52);
  s.lineTo(0.32, 0.52);
  s.lineTo(0.34, 0.1);
  s.bezierCurveTo(0.32, -0.1, 0.2, -0.2, 0.02, -0.18);
  s.lineTo(-0.7, -0.12);
  s.bezierCurveTo(-0.92, -0.12, -1.06, -0.32, -1.0, -0.62);
  return s;
}
function flame() {
  const s = new THREE.Shape();
  s.moveTo(0, -1);
  s.bezierCurveTo(0.75, -1, 0.95, -0.35, 0.7, 0.15);
  s.bezierCurveTo(0.55, 0.45, 0.6, 0.7, 0.35, 1.0);
  s.bezierCurveTo(0.3, 0.7, 0.1, 0.55, -0.05, 0.5);
  s.bezierCurveTo(0.05, 0.8, -0.1, 0.95, -0.3, 1.0);
  s.bezierCurveTo(-0.25, 0.7, -0.75, 0.4, -0.8, -0.2);
  s.bezierCurveTo(-0.85, -0.75, -0.45, -1, 0, -1);
  return s;
}
function fishShape() {
  const s = new THREE.Shape();
  s.moveTo(1.0, 0);
  s.bezierCurveTo(0.9, 0.5, 0.2, 0.68, -0.35, 0.36);
  s.lineTo(-0.95, 0.62);
  s.bezierCurveTo(-0.82, 0.2, -0.82, -0.2, -0.95, -0.62);
  s.lineTo(-0.35, -0.36);
  s.bezierCurveTo(0.2, -0.68, 0.9, -0.5, 1.0, 0);
  return s;
}
function keyhole() {
  const s = new THREE.Shape();
  s.absarc(0, 0.12, 0.13, Math.PI * -0.25, Math.PI * 1.25, false);
  s.lineTo(-0.1, -0.24);
  s.lineTo(0.1, -0.24);
  s.closePath();
  return s;
}

// --- texturas pintadas ---------------------------------------------------------------------------

const billTexture = () => texture((c, w, h) => {
  const g = c.createLinearGradient(0, 0, 0, h);
  g.addColorStop(0, '#5fe07a');
  g.addColorStop(1, '#2fae4c');
  c.fillStyle = g;
  c.fillRect(0, 0, w, h);
  c.strokeStyle = '#1d7d36';
  c.lineWidth = 18;
  c.strokeRect(22, 22, w - 44, h - 44);
  c.fillStyle = '#8af29c';
  c.beginPath();
  c.ellipse(w / 2, h / 2, h * 0.3, h * 0.3, 0, 0, Math.PI * 2);
  c.fill();
  c.fillStyle = '#1d7d36';
  c.font = `bold ${Math.round(h * 0.5)}px sans-serif`;
  c.textAlign = 'center';
  c.textBaseline = 'middle';
  c.fillText('$', w / 2, h / 2 + 4);
}, 512, 256);

function spotsTexture(base, spot, opts = {}) {
  return texture((c, w, h) => {
    c.fillStyle = base;
    c.fillRect(0, 0, w, h);
    let seed = opts.seed ?? 7;
    const rnd = () => ((seed = (seed * 9301 + 49297) % 233280) / 233280);
    const n = opts.count ?? 26;
    for (let i = 0; i < n; i++) {
      const x = rnd() * w, y = h * 0.1 + rnd() * h * 0.8, r = (opts.size ?? 0.045) * w * (0.6 + rnd() * 0.8);
      c.fillStyle = Array.isArray(spot) ? spot[i % spot.length] : spot;
      c.beginPath();
      c.ellipse(x, y, r, r * 0.8, 0, 0, Math.PI * 2);
      c.fill();
      c.beginPath();
      c.ellipse(x - w, y, r, r * 0.8, 0, 0, Math.PI * 2);
      c.fill();
    }
  }, 512, 256);
}

const wheelTexture = (colors) => texture((c, w, h) => {
  const cx = w / 2, cy = h / 2, r = w / 2;
  colors.forEach((col, i) => {
    const a0 = (i / colors.length) * Math.PI * 2, a1 = ((i + 1) / colors.length) * Math.PI * 2;
    c.fillStyle = col;
    c.beginPath();
    c.moveTo(cx, cy);
    c.arc(cx, cy, r, a0, a1);
    c.closePath();
    c.fill();
    c.strokeStyle = '#ffffff';
    c.lineWidth = 10;
    c.stroke();
  });
});

const clockTexture = () => texture((c, w, h) => {
  c.fillStyle = '#ffffff';
  c.fillRect(0, 0, w, h);
  c.translate(w / 2, h / 2);
  c.strokeStyle = '#2a2440';
  for (let i = 0; i < 12; i++) {
    c.save();
    c.rotate((i / 12) * Math.PI * 2);
    c.lineWidth = i % 3 === 0 ? 22 : 12;
    c.beginPath();
    c.moveTo(0, -w * 0.4);
    c.lineTo(0, -w * (i % 3 === 0 ? 0.31 : 0.35));
    c.stroke();
    c.restore();
  }
  c.lineCap = 'round';
  c.lineWidth = 30;
  c.beginPath();
  c.moveTo(0, 0);
  c.lineTo(0, -w * 0.26);
  c.stroke();
  c.strokeStyle = '#ff3b4f';
  c.lineWidth = 22;
  c.beginPath();
  c.moveTo(0, 0);
  c.lineTo(w * 0.2, w * 0.1);
  c.stroke();
  c.fillStyle = '#2a2440';
  c.beginPath();
  c.arc(0, 0, 26, 0, Math.PI * 2);
  c.fill();
});

const swirlTexture = (a, b) => texture((c, w, h) => {
  const g = c.createRadialGradient(w / 2, h / 2, 10, w / 2, h / 2, w / 2);
  g.addColorStop(0, '#ffffff');
  g.addColorStop(0.25, b);
  g.addColorStop(1, a);
  c.fillStyle = g;
  c.fillRect(0, 0, w, h);
  c.translate(w / 2, h / 2);
  c.strokeStyle = 'rgba(255,255,255,0.65)';
  c.lineCap = 'round';
  for (let k = 0; k < 4; k++) {
    c.rotate(Math.PI / 2);
    c.lineWidth = 16;
    c.beginPath();
    for (let t = 0; t < 1; t += 0.01) {
      const r = t * w * 0.48, ang = t * Math.PI * 2.4;
      const x = Math.cos(ang) * r, y = Math.sin(ang) * r;
      if (t === 0) c.moveTo(x, y);
      else c.lineTo(x, y);
    }
    c.stroke();
  }
});

const mapTexture = () => texture((c, w, h) => {
  c.fillStyle = '#f6e3b4';
  c.fillRect(0, 0, w, h);
  c.fillStyle = '#9fd67a';
  c.beginPath();
  c.ellipse(w * 0.3, h * 0.35, w * 0.2, h * 0.16, 0.3, 0, Math.PI * 2);
  c.fill();
  c.fillStyle = '#7cc6f0';
  c.beginPath();
  c.ellipse(w * 0.72, h * 0.7, w * 0.18, h * 0.14, -0.4, 0, Math.PI * 2);
  c.fill();
  c.setLineDash([26, 22]);
  c.strokeStyle = '#c0392b';
  c.lineWidth = 14;
  c.beginPath();
  c.moveTo(w * 0.15, h * 0.8);
  c.bezierCurveTo(w * 0.35, h * 0.5, w * 0.55, h * 0.9, w * 0.72, h * 0.32);
  c.stroke();
  c.setLineDash([]);
  c.lineWidth = 24;
  c.beginPath();
  c.moveTo(w * 0.66, h * 0.22);
  c.lineTo(w * 0.8, h * 0.4);
  c.moveTo(w * 0.8, h * 0.22);
  c.lineTo(w * 0.66, h * 0.4);
  c.stroke();
});

// --- piezas compuestas ------------------------------------------------------------------------------

function badge(color, shape, pos, size = 0.62) {
  const base = mesh(rbox(size, size, size * 0.34, size * 0.2), plastic(color), pos);
  base.userData.glyphHide = true;
  const sym = mesh(extrude(shape, 0.06, 0.03), plastic(0xffffff, { glow: 0.2 }), [pos[0], pos[1], pos[2] + size * 0.2], [0, 0, 0], size * 0.36);
  return group(base, sym);
}
function eggProfile(scale = 1) {
  const pts = [];
  for (let i = 0; i <= 40; i++) {
    const t = i / 40;
    const y = -1 + 2 * t;
    const r = 0.74 * Math.sqrt(Math.max(0, 1 - y * y)) * (1 - 0.14 * y);
    pts.push([r * scale, y * scale * 0.98]);
  }
  return pts;
}
function egg(base, spot, opts = {}) {
  const mat = opts.metal ? metal(base) : painted(spotsTexture(base, spot, opts), { roughness: 0.3, clearcoat: 1 });
  const e = mesh(lathe(eggProfile()), mat, [0, 0, 0], [0, -0.6, 0]);
  return { object: group(e), yaw: 0, pitch: 8, fill: 0.78 };
}
function coinMesh(color = 0xffbf2e, emblem = 'star') {
  const body = mesh(lathe([[0, -0.12], [0.92, -0.12], [1.0, -0.06], [1.0, 0.06], [0.92, 0.12], [0.8, 0.12], [0.76, 0.08], [0, 0.08]], 72), metal(color));
  const parts = [body];
  if (emblem === 'star') parts.push(mesh(extrude(star(5, 0.5, 0.24), 0.06, 0.03), metal(0xffd860), [0, 0.12, 0], [-Math.PI / 2, 0, 0]));
  return group(...parts);
}

// --- íconos -----------------------------------------------------------------------------------------

export const MODELS = {
  async cash() {
    const top = painted(billTexture(), { roughness: 0.55, clearcoat: 0.25 });
    const side = plastic(0x2a9a46, { roughness: 0.55, clearcoat: 0.2 });
    const g = new THREE.Group();
    for (let i = 0; i < 5; i++) {
      const b = mesh(new THREE.BoxGeometry(1.7, 0.09, 0.86), [side, side, top, side, side, side], [0, i * 0.1, 0], [0, i % 2 ? 0.05 : -0.04, 0]);
      g.add(b);
    }
    g.add(mesh(rbox(0.3, 0.56, 0.92, 0.04), plastic(0xffc21a), [0, 0.2, 0]));
    return { object: g, yaw: 32, pitch: 34, fill: 0.86 };
  },
  async coins() {
    const a = coinMesh();
    a.rotation.set(1.15, 0, 0.1);
    const b = coinMesh();
    b.rotation.set(1.35, 0, -0.2);
    b.position.set(-0.75, -0.45, -0.3);
    const c = coinMesh();
    c.rotation.set(1.45, 0, 0.25);
    c.position.set(0.8, -0.5, -0.2);
    return { object: group(b, c, a), yaw: 0, pitch: 10, fill: 0.84 };
  },
  async gem() {
    const g = mesh(lathe([[0, -0.95], [1.0, 0.05], [0.66, 0.46], [0, 0.46]], 8), gem(0x2f8cff), [0, 0, 0], [0, Math.PI / 8, 0]);
    return { object: group(g), yaw: 0, pitch: 16, fill: 0.8 };
  },
  async gift() {
    const red = plastic(0xff3355), yellow = plastic(0xffd23a);
    const parts = [
      mesh(rbox(1.2, 0.95, 1.2, 0.07), red, [0, -0.2, 0]),
      mesh(rbox(1.34, 0.3, 1.34, 0.07), red, [0, 0.38, 0]),
      mesh(new THREE.BoxGeometry(0.28, 0.98, 1.22), yellow, [0, -0.2, 0]),
      mesh(new THREE.BoxGeometry(1.22, 0.98, 0.28), yellow, [0, -0.2, 0]),
      mesh(new THREE.BoxGeometry(0.3, 0.32, 1.37), yellow, [0, 0.38, 0]),
      mesh(new THREE.BoxGeometry(1.37, 0.32, 0.3), yellow, [0, 0.38, 0]),
      mesh(new THREE.TorusGeometry(0.26, 0.1, 16, 40), yellow, [-0.27, 0.7, 0], [0, 0.35, 0.45], [1, 0.75, 0.55]),
      mesh(new THREE.TorusGeometry(0.26, 0.1, 16, 40), yellow, [0.27, 0.7, 0], [0, -0.35, -0.45], [1, 0.75, 0.55]),
      mesh(new THREE.SphereGeometry(0.14, 24, 16), yellow, [0, 0.6, 0]),
    ];
    return { object: group(...parts), yaw: 28, pitch: 22, fill: 0.84 };
  },
  async index() {
    const blue = plastic(0x2f6dff), pages = plastic(0xfff1cf, { roughness: 0.7, clearcoat: 0.1 });
    const parts = [
      mesh(rbox(1.16, 1.5, 0.09, 0.04), blue, [0.02, 0, 0.2]),
      mesh(rbox(1.16, 1.5, 0.09, 0.04), blue, [0.02, 0, -0.2]),
      mesh(rbox(0.16, 1.5, 0.49, 0.06), plastic(0x2350c8), [-0.56, 0, 0]),
      mesh(new THREE.BoxGeometry(1.06, 1.38, 0.32), pages, [0.04, 0, 0]),
      mesh(extrude(star(5, 0.34, 0.16), 0.05, 0.025), plastic(0xffcc1f), [0.04, 0.05, 0.27]),
    ];
    return { object: group(...parts), yaw: 28, pitch: 10, fill: 0.84 };
  },
  async shop_bag() {
    const pink = plastic(0xff3f8e);
    const body = new THREE.Shape();
    body.moveTo(-0.62, -0.68);
    body.lineTo(0.62, -0.68);
    body.lineTo(0.56, 0.5);
    body.lineTo(-0.56, 0.5);
    body.closePath();
    const parts = [
      mesh(extrude(body, 0.5, 0.08), pink, [0, -0.1, 0]),
      mesh(rbox(1.24, 0.18, 0.7, 0.06), plastic(0xff79b3), [0, 0.42, 0]),
      mesh(new THREE.TorusGeometry(0.3, 0.06, 14, 40, Math.PI), plastic(0xc81e64), [0, 0.5, 0.18]),
      mesh(new THREE.TorusGeometry(0.3, 0.06, 14, 40, Math.PI), plastic(0xc81e64), [0, 0.5, -0.18]),
      mesh(extrude(star(5, 0.3, 0.14), 0.05, 0.025), plastic(0xffd23a), [0, -0.12, 0.36]),
    ];
    return { object: group(...parts), yaw: 24, pitch: 14, fill: 0.84 };
  },
  async shop() {
    // Canasta de compras como la de Anime Dice y PS99: cuerpo con tablillas, borde grueso y asa.
    const red = plastic(0xff3b6b), dark = plastic(0xd61f52), rim = plastic(0xff79a3);
    const body = new THREE.Shape();
    body.moveTo(-0.72, -0.62);
    body.lineTo(0.72, -0.62);
    body.lineTo(0.9, 0.22);
    body.lineTo(-0.9, 0.22);
    body.closePath();
    const parts = [
      mesh(extrude(body, 0.9, 0.08), red, [0, -0.22, 0]),
      mesh(rbox(1.98, 0.22, 1.12, 0.1), rim, [0, 0.24, 0]),
      mesh(tube([[-0.82, 0.3, 0], [-0.7, 0.86, 0], [0, 1.08, 0], [0.7, 0.86, 0], [0.82, 0.3, 0]], 0.08), plastic(0x9aa6ff)),
    ];
    for (let i = -2; i <= 2; i++) {
      parts.push(mesh(rbox(0.13, 0.6, 0.06, 0.03), dark, [i * 0.3, -0.24, 0.52], [0, 0, -i * 0.06]));
    }
    parts.push(mesh(new THREE.SphereGeometry(0.26, 24, 16), plastic(0x3ddc5a), [-0.38, 0.46, -0.1]));
    parts.push(mesh(rbox(0.42, 0.42, 0.42, 0.08), plastic(0xffc21f), [0.32, 0.5, -0.12], [0.3, 0.5, 0.2]));
    parts.push(mesh(new THREE.SphereGeometry(0.2, 24, 16), plastic(0x2f8cff), [0.0, 0.52, 0.18]));
    return { object: group(...parts), yaw: 22, pitch: 20, fill: 0.86 };
  },
  async rebirth() {
    const r = 0.72, t = 0.17;
    const a = mesh(tube(arcPoints(r, 200, 335), t), plastic(0xff3b5c));
    const ah = mesh(extrude(polygon([[-0.32, 0], [0.32, 0], [0, 0.42]]), 0.2, 0.05), plastic(0xff3b5c), [Math.cos(THREE.MathUtils.degToRad(338)) * r, Math.sin(THREE.MathUtils.degToRad(338)) * r, 0], [0, 0, THREE.MathUtils.degToRad(338)]);
    const b = mesh(tube(arcPoints(r, 20, 155), t), plastic(0x23b4ff));
    const bh = mesh(extrude(polygon([[-0.32, 0], [0.32, 0], [0, 0.42]]), 0.2, 0.05), plastic(0x23b4ff), [Math.cos(THREE.MathUtils.degToRad(158)) * r, Math.sin(THREE.MathUtils.degToRad(158)) * r, 0], [0, 0, THREE.MathUtils.degToRad(158)]);
    return { object: group(a, ah, b, bh), yaw: 12, pitch: 10, fill: 0.82 };
  },
  async auto() {
    const r = 0.72, t = 0.17;
    const parts = [];
    for (const [from, to] of [[200, 335], [20, 155]]) {
      parts.push(mesh(tube(arcPoints(r, from, to), t), plastic(0x3ddc5a)));
      const a = THREE.MathUtils.degToRad(to + 3);
      parts.push(mesh(extrude(polygon([[-0.32, 0], [0.32, 0], [0, 0.42]]), 0.2, 0.05), plastic(0x3ddc5a), [Math.cos(a) * r, Math.sin(a) * r, 0], [0, 0, a]));
    }
    return { object: group(...parts), yaw: 12, pitch: 10, fill: 0.82 };
  },
  async trade() {
    const top = mesh(extrude(arrow(1.8, 0.38, 0.86, 0.66), 0.24, 0.07), plastic(0x3ddc5a), [0.05, 0.34, 0.08]);
    const bottom = mesh(extrude(arrow(1.8, 0.38, 0.86, 0.66), 0.24, 0.07), plastic(0xffa21f), [-0.05, -0.34, -0.08], [0, 0, Math.PI]);
    return { object: group(bottom, top), yaw: 18, pitch: 8, fill: 0.84 };
  },
  async settings() {
    const g = mesh(extrude(gear(8, 1, 0.76, 0.34), 0.32, 0.07), metal(0xaab6c8, { roughness: 0.3, metalness: 0.6 }));
    const jewel = mesh(new THREE.SphereGeometry(0.26, 32, 20), plastic(0x2f8cff), [0, 0, 0.12], [0, 0, 0], [1, 1, 0.55]);
    return { object: group(g, jewel), yaw: 18, pitch: 22, fill: 0.82 };
  },
  async daily() {
    const parts = [
      mesh(rbox(1.36, 1.28, 0.26, 0.12), plastic(0xf7f8fc, { roughness: 0.5 }), [0, -0.08, 0]),
      mesh(rbox(1.38, 0.4, 0.28, 0.1), plastic(0xff4b4b), [0, 0.48, 0]),
      mesh(new THREE.TorusGeometry(0.11, 0.045, 12, 24), silver(), [-0.36, 0.72, 0], [0, Math.PI / 2, 0]),
      mesh(new THREE.TorusGeometry(0.11, 0.045, 12, 24), silver(), [0.36, 0.72, 0], [0, Math.PI / 2, 0]),
      mesh(extrude(star(5, 0.34, 0.16), 0.06, 0.03), plastic(0xffcc1f), [0, -0.16, 0.16]),
    ];
    return { object: group(...parts), yaw: 24, pitch: 12, fill: 0.82 };
  },
  async quests() {
    const parts = [
      mesh(rbox(1.18, 1.5, 0.12, 0.1), plastic(0xc07a3f), [0, 0, 0]),
      mesh(rbox(0.96, 1.22, 0.04, 0.02), plastic(0xffffff, { roughness: 0.6 }), [0, -0.06, 0.08]),
      mesh(rbox(0.5, 0.24, 0.18, 0.06), silver(), [0, 0.68, 0.06]),
      mesh(extrude(check(), 0.12, 0.05), plastic(0x2fcf4a), [0.02, -0.08, 0.2], [0, 0, 0], 0.62),
    ];
    return { object: group(...parts), yaw: 22, pitch: 10, fill: 0.84 };
  },
  async crown() {
    const c = new THREE.Shape();
    c.moveTo(-0.95, -0.55);
    c.lineTo(0.95, -0.55);
    c.lineTo(1.0, 0.38);
    c.lineTo(0.52, 0.02);
    c.lineTo(0.0, 0.62);
    c.lineTo(-0.52, 0.02);
    c.lineTo(-1.0, 0.38);
    c.closePath();
    const parts = [
      mesh(extrude(c, 0.42, 0.12), gold()),
      mesh(rbox(2.06, 0.3, 0.6, 0.12), metal(0xffb000), [0, -0.5, 0]),
      mesh(new THREE.SphereGeometry(0.16, 24, 16), gold(), [-1.0, 0.48, 0]),
      mesh(new THREE.SphereGeometry(0.16, 24, 16), gold(), [1.0, 0.48, 0]),
      mesh(new THREE.SphereGeometry(0.18, 24, 16), gold(), [0, 0.76, 0]),
      mesh(new THREE.SphereGeometry(0.2, 24, 16), gem(0xff2a4d), [0, -0.12, 0.3], [0, 0, 0], [1, 1, 0.6]),
      mesh(new THREE.SphereGeometry(0.13, 24, 16), gem(0x2f8cff), [-0.56, -0.2, 0.28], [0, 0, 0], [1, 1, 0.6]),
      mesh(new THREE.SphereGeometry(0.13, 24, 16), gem(0x2f8cff), [0.56, -0.2, 0.28], [0, 0, 0], [1, 1, 0.6]),
      mesh(new THREE.SphereGeometry(0.1, 20, 14), gem(0x3ddc5a), [0, -0.52, 0.34], [0, 0, 0], [1, 1, 0.6]),
    ];
    return { object: group(...parts), yaw: 12, pitch: 14, fill: 0.84 };
  },
  async luck_blue() {
    const spec = await MODELS.luck();
    spec.object.traverse((o) => { if (o.isMesh && o.material.uniforms) o.material.uniforms.color.value.setHex(o.material.uniforms.color.value.getHex() === 0x23963a ? 0x1f5fd6 : 0x4fb6ff); });
    for (const [x, y, k] of [[0.72, 0.7, 0.5], [-0.78, 0.4, 0.36]]) {
      spec.object.add(mesh(extrude(star(4, 0.5, 0.14), 0.04, 0.02), plastic(0xffffff, { glow: 0.3 }), [x, y, 0.3], [0, 0, 0], k));
    }
    return spec;
  },
  async medal() {
    const ribbon = (x, color, rot) => mesh(extrude(polygon([[-0.2, 0.5], [0.2, 0.5], [0.2, -0.5], [0, -0.32], [-0.2, -0.5]]), 0.08, 0.03), plastic(color), [x, -0.66, -0.1], [0, 0, rot]);
    const rosette = new THREE.Shape();
    for (let i = 0; i <= 24; i++) {
      const a = (i / 24) * Math.PI * 2, r = i % 2 ? 0.86 : 0.98;
      if (i === 0) rosette.moveTo(Math.cos(a) * r, Math.sin(a) * r);
      else rosette.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    const parts = [
      ribbon(-0.3, 0xff3b4f, 0.35), ribbon(0.3, 0x2f8cff, -0.35),
      mesh(extrude(rosette, 0.2, 0.06), plastic(0xff8a1c), [0, 0.12, 0]),
      mesh(new THREE.CylinderGeometry(0.6, 0.6, 0.16, 48), gold(), [0, 0.12, 0.12], [Math.PI / 2, 0, 0]),
      mesh(extrude(star(5, 0.36, 0.16), 0.06, 0.03), plastic(0xff5a1f), [0, 0.12, 0.26]),
    ];
    return { object: group(...parts), yaw: 10, pitch: 8, fill: 0.84 };
  },
  async treadmill() {
    const parts = [
      mesh(rbox(1.9, 0.26, 0.86, 0.1), plastic(0x3b3f52), [0, -0.5, 0]),
      mesh(rbox(1.6, 0.06, 0.66, 0.03), plastic(0x2f86ff), [0, -0.35, 0]),
      mesh(new THREE.CylinderGeometry(0.06, 0.06, 1.1, 16), plastic(0x9aa6ff), [-0.7, 0.18, 0.36], [0, 0, -0.3]),
      mesh(new THREE.CylinderGeometry(0.06, 0.06, 1.1, 16), plastic(0x9aa6ff), [-0.7, 0.18, -0.36], [0, 0, -0.3]),
      mesh(rbox(0.5, 0.36, 0.86, 0.08), plastic(0xff3b4f), [-0.86, 0.72, 0], [0, 0, 0.35]),
      mesh(rbox(0.3, 0.12, 0.06, 0.02), light(0x6ff2ff, 0.8), [-0.82, 0.74, 0.44], [0, 0, 0.35]),
    ];
    return { object: group(...parts), yaw: 30, pitch: 22, fill: 0.86 };
  },
  async luck() {
    const parts = [];
    const leaf = extrude(heart(0.44), 0.16, 0.07);
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * Math.PI * 2 + Math.PI / 4;
      const m = mesh(leaf, plastic(i % 2 ? 0x2fbf45 : 0x3ad152), [Math.cos(a) * 0.5, Math.sin(a) * 0.5, 0], [0, 0, a - Math.PI / 2]);
      parts.push(m);
    }
    parts.push(mesh(new THREE.SphereGeometry(0.16, 24, 16), plastic(0x2fbf45), [0, 0, 0.06], [0, 0, 0], [1, 1, 0.6]));
    parts.push(mesh(tube([[0.05, -0.1, -0.02], [0.2, -0.6, 0], [0.48, -1.05, 0]], 0.075), plastic(0x23963a)));
    return { object: group(...parts), yaw: 10, pitch: 14, fill: 0.84 };
  },
  async boost() {
    const g = extrude(bolt(), 0.24, 0.08);
    return { object: group(mesh(g, [plastic(0xffd21f, { glow: 0.12 }), plastic(0xff8a00)])), yaw: 18, pitch: 8, fill: 0.84 };
  },
  async star() {
    return { object: group(mesh(extrude(star(5, 1, 0.5), 0.26, 0.12), plastic(0xffcc1f, { glow: 0.1 }))), yaw: 14, pitch: 10, fill: 0.84 };
  },
  async heart() {
    return { object: group(mesh(extrude(heart(1), 0.3, 0.12), plastic(0xff3b6b))), yaw: 14, pitch: 8, fill: 0.82 };
  },
  async egg_common() { return egg('#f4f1ea', '#c9c3b8'); },
  async egg_uncommon() { return egg('#c8f7b5', '#43c94f'); },
  async egg_rare() { return egg('#bfe4ff', '#2f8cff'); },
  async egg_epic() { return egg('#e7c8ff', '#9b3cff'); },
  async egg_legendary() { return egg('#fff0a8', ['#ffb21f', '#ff7a00']); },
  async egg_mythic() { return egg('#ffd0e8', ['#ff3b8e', '#ff7ac0']); },
  async egg_secret() { return egg('#1d1a2e', ['#ff3b6b', '#ffd23a', '#3bd1ff', '#8dff4f', '#c86bff'], { size: 0.06, count: 22 }); },
  async egg_gold() { return egg(0xffc93a, null, { metal: true }); },
  async egg_halloween() { return egg('#ff8a1c', ['#3a1a52', '#1d1a2e'], { size: 0.05 }); },
  async egg_winter() { return egg('#e8f8ff', ['#7fd6ff', '#bde9ff'], { size: 0.05, count: 20 }); },
  async potion() {
    const flask = lathe([[0.0, -0.78], [0.42, -0.74], [0.66, -0.42], [0.68, -0.08], [0.48, 0.24], [0.22, 0.36], [0.2, 0.7], [0.0, 0.7]], 64);
    const liquid = lathe([[0.0, -0.7], [0.38, -0.66], [0.6, -0.4], [0.62, -0.08], [0.5, 0.12], [0.0, 0.12]], 64);
    const parts = [
      mesh(liquid, light(0xff3fd2, 0.55)),
      mesh(flask, glass(0xe6f8ff, 0.5)),
      mesh(new THREE.CylinderGeometry(0.2, 0.17, 0.26, 32), plastic(0xb57a45, { roughness: 0.6 }), [0, 0.8, 0]),
      mesh(new THREE.SphereGeometry(0.08, 16, 12), plastic(0xffffff, { glow: 0.4 }), [-0.2, -0.3, 0.45]),
      mesh(new THREE.SphereGeometry(0.05, 16, 12), plastic(0xffffff, { glow: 0.4 }), [0.12, -0.12, 0.5]),
    ];
    parts[0].userData.noOutline = true;
    parts[1].userData.noOutline = true;
    return { object: group(...parts), yaw: 0, pitch: 10, fill: 0.84 };
  },
  async timer() {
    const red = plastic(0xff4b4b);
    const body = mesh(lathe([[0, -0.2], [0.86, -0.2], [0.92, -0.14], [0.92, 0.14], [0.86, 0.2], [0, 0.2]], 64), red, [0, 0, 0], [Math.PI / 2, 0, 0]);
    const face = mesh(new THREE.CircleGeometry(0.76, 64), painted(clockTexture(), { clearcoat: 0.8 }), [0, 0, 0.205]);
    const parts = [
      body, face,
      mesh(new THREE.SphereGeometry(0.3, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2), red, [-0.55, 0.78, 0], [0, 0, 0.6]),
      mesh(new THREE.SphereGeometry(0.3, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2), red, [0.55, 0.78, 0], [0, 0, -0.6]),
      mesh(new THREE.CylinderGeometry(0.07, 0.07, 0.3, 16), silver(), [-0.48, -0.95, 0], [0, 0, -0.5]),
      mesh(new THREE.CylinderGeometry(0.07, 0.07, 0.3, 16), silver(), [0.48, -0.95, 0], [0, 0, 0.5]),
    ];
    return { object: group(...parts), yaw: 10, pitch: 8, fill: 0.84 };
  },
  async lock() {
    const parts = [
      mesh(tube([[-0.36, 0.1, 0], [-0.36, 0.55, 0], [-0.25, 0.86, 0], [0, 0.95, 0], [0.25, 0.86, 0], [0.36, 0.55, 0], [0.36, 0.1, 0]], 0.11), silver()),
      mesh(rbox(1.2, 0.98, 0.44, 0.14), gold(), [0, -0.32, 0]),
      mesh(extrude(keyhole(), 0.06, 0.02), plastic(0x3b2410), [0, -0.3, 0.24], [0, 0, 0], 1.6),
    ];
    return { object: group(...parts), yaw: 18, pitch: 12, fill: 0.82 };
  },
  async trophy() {
    const cup = lathe([[0.0, -0.1], [0.24, -0.08], [0.52, 0.18], [0.66, 0.66], [0.6, 0.7], [0.46, 0.24], [0.2, 0.0], [0.0, 0.0]], 64);
    const parts = [
      mesh(cup, gold(), [0, 0.1, 0]),
      mesh(new THREE.TorusGeometry(0.24, 0.07, 14, 32, Math.PI * 1.2), gold(), [-0.6, 0.46, 0], [0, 0, Math.PI * 0.4]),
      mesh(new THREE.TorusGeometry(0.24, 0.07, 14, 32, Math.PI * 1.2), gold(), [0.6, 0.46, 0], [0, Math.PI, Math.PI * 0.4]),
      mesh(new THREE.CylinderGeometry(0.1, 0.16, 0.36, 24), gold(), [0, -0.12, 0]),
      mesh(rbox(0.86, 0.26, 0.6, 0.06), plastic(0x7a4a2a, { roughness: 0.5 }), [0, -0.42, 0]),
      mesh(extrude(star(5, 0.2, 0.09), 0.05, 0.02), metal(0xfff1a8), [0, 0.42, 0.6]),
    ];
    return { object: group(...parts), yaw: 0, pitch: 12, fill: 0.84 };
  },
  async speed() {
    // Zapatilla de costado: capellada azul, entresuela blanca gruesa, puntera, cordones, boca y un rayo.
    const blue = plastic(0x2f86ff), white = plastic(0xf5f6fa, { roughness: 0.42 });
    const parts = [
      mesh(extrude(shoe(), 0.66, 0.12), blue, [0, 0.08, 0], [0, 0, 0], [1, 1.3, 1]),
      mesh(extrude(sole(), 0.82, 0.06), white, [0.02, -0.44, 0], [0, 0, 0], [1, 1.5, 1]),
      mesh(new THREE.SphereGeometry(0.34, 28, 18), white, [0.86, -0.12, 0], [0, 0, 0], [1.05, 0.62, 1.05]),
      mesh(new THREE.SphereGeometry(0.3, 28, 18, 0, Math.PI * 2, 0, Math.PI / 2), plastic(0x123a8a), [-0.5, 0.86, 0], [0, 0, 0.1], [1.2, 0.35, 0.9]),
      mesh(extrude(bolt(), 0.05, 0.02), plastic(0xffffff, { glow: 0.2 }), [-0.36, 0.18, 0.45], [0, 0, -1.25], [0.34, 0.34, 0.34]),
    ];
    for (let i = 0; i < 3; i++) {
      parts.push(mesh(rbox(0.12, 0.08, 0.74, 0.03), white, [0.42 - i * 0.2, 0.36 + i * 0.13, 0], [0, 0, -0.5]));
    }
    parts.push(badge(0xffc21a, plus(1, 0.36), [0.82, -0.48, 0.46], 0.64));
    return { object: group(...parts), yaw: 16, pitch: 10, fill: 0.86 };
  },
  async strength() {
    // Brazo flexionado como el emoji: brazo horizontal, bíceps redondo arriba, antebrazo parado y puño.
    const skin = plastic(0xffc22e);
    const cap = (r, len) => new THREE.CapsuleGeometry(r, len, 12, 28);
    const parts = [
      mesh(cap(0.3, 0.95), skin, [-0.32, -0.46, 0], [0, 0, Math.PI / 2]),
      mesh(new THREE.SphereGeometry(0.42, 36, 24), skin, [-0.28, -0.12, 0.02], [0, 0, 0.12], [1.18, 0.86, 0.92]),
      mesh(new THREE.SphereGeometry(0.31, 28, 20), skin, [0.42, -0.4, 0]),
      mesh(cap(0.25, 0.62), skin, [0.47, 0.04, 0], [0, 0, 0.12]),
      mesh(rbox(0.64, 0.58, 0.62, 0.24), skin, [0.36, 0.62, 0], [0, 0, 0.3]),
    ];
    for (let i = 0; i < 4; i++) {
      parts.push(mesh(new THREE.SphereGeometry(0.1, 18, 12), skin, [0.12 + i * 0.15, 0.78 - i * 0.05, 0.27], [0, 0, 0.3], [1, 0.85, 0.8]));
    }
    return { object: group(...parts), yaw: 8, pitch: 6, fill: 0.84 };
  },
  async dice() {
    const pip = (x, y, z, rot, color = 0x1a1426) => mesh(new THREE.SphereGeometry(0.11, 20, 14), plastic(color), [x, y, z], rot, [1, 1, 0.35]);
    const f = 0.56;
    const parts = [
      mesh(rbox(1.12, 1.12, 1.12, 0.24), plastic(0xfbfbff, { roughness: 0.35 })),
      pip(0, f, 0, [Math.PI / 2, 0, 0], 0xff3b4f),
      pip(-0.26, 0.26, f, [0, 0, 0]), pip(0, 0, f, [0, 0, 0]), pip(0.26, -0.26, f, [0, 0, 0]),
      pip(f, 0.24, -0.24, [0, Math.PI / 2, 0]), pip(f, -0.24, 0.24, [0, Math.PI / 2, 0]),
    ];
    const g = group(...parts);
    g.rotation.set(0.08, -0.22, 0.05);
    return { object: g, yaw: 30, pitch: 26, fill: 0.8 };
  },
  async fire() {
    const parts = [
      mesh(extrude(flame(), 0.3, 0.1), plastic(0xff5a1f, { glow: 0.2 })),
      mesh(extrude(flame(), 0.2, 0.08), plastic(0xffd23a, { glow: 0.35 }), [0.02, -0.28, 0.18], [0, 0, 0], 0.56),
    ];
    return { object: group(...parts), yaw: 12, pitch: 8, fill: 0.84 };
  },
  async pickaxe() {
    const head = tube(arcPoints(0.95, 35, 145, 32), 0.13);
    const parts = [
      mesh(new THREE.CylinderGeometry(0.09, 0.1, 1.9, 20), plastic(0x9a5a2a, { roughness: 0.5 }), [0, -0.1, 0]),
      mesh(head, silver(), [0, -0.12, 0]),
      mesh(new THREE.ConeGeometry(0.13, 0.36, 20), silver(), [0.86, 0.36, 0], [0, 0, -2.0]),
      mesh(new THREE.ConeGeometry(0.13, 0.36, 20), silver(), [-0.86, 0.36, 0], [0, 0, 2.0]),
      mesh(rbox(0.32, 0.3, 0.3, 0.06), metal(0x8a96a8, { roughness: 0.35 }), [0, 0.82, 0]),
    ];
    const g = group(...parts);
    g.rotation.z = -0.7;
    return { object: g, yaw: 12, pitch: 8, fill: 0.84 };
  },
  async music() {
    const purple = plastic(0x8a5cff);
    const parts = [
      mesh(new THREE.SphereGeometry(0.28, 28, 18), purple, [-0.42, -0.62, 0], [0, 0, 0.4], [1.25, 0.95, 0.7]),
      mesh(new THREE.SphereGeometry(0.28, 28, 18), purple, [0.5, -0.44, 0], [0, 0, 0.4], [1.25, 0.95, 0.7]),
      mesh(new THREE.CylinderGeometry(0.07, 0.07, 1.2, 16), purple, [-0.16, 0.0, 0]),
      mesh(new THREE.CylinderGeometry(0.07, 0.07, 1.2, 16), purple, [0.76, 0.18, 0]),
      mesh(rbox(1.04, 0.24, 0.16, 0.05), purple, [0.3, 0.68, 0], [0, 0, 0.19]),
    ];
    return { object: group(...parts), yaw: 12, pitch: 8, fill: 0.84 };
  },
  async friends() {
    const head = (color, x, y, z, s) => {
      const g = new THREE.Group();
      g.add(mesh(new THREE.SphereGeometry(0.55, 40, 28), plastic(color), [0, 0, 0], [0, 0, 0], [1, 0.94, 0.9]));
      for (const ex of [-0.18, 0.18]) {
        g.add(mesh(new THREE.SphereGeometry(0.085, 20, 14), plastic(0x1a1426), [ex, 0.08, 0.47]));
        g.add(mesh(new THREE.SphereGeometry(0.03, 12, 8), plastic(0xffffff, { glow: 0.5 }), [ex + 0.03, 0.12, 0.54]));
      }
      g.add(mesh(new THREE.TorusGeometry(0.16, 0.035, 10, 24, Math.PI), plastic(0x1a1426), [0, -0.1, 0.47], [0, 0, Math.PI]));
      g.position.set(x, y, z);
      g.scale.setScalar(s);
      return g;
    };
    return { object: group(head(0x2f8cff, -0.4, 0.05, -0.2, 1), head(0x3ddc5a, 0.42, -0.08, 0.15, 0.95)), yaw: 0, pitch: 6, fill: 0.84 };
  },
  async invite() {
    const spec = await MODELS.friends();
    spec.object.add(badge(0x2fcf4a, plus(1, 0.36), [0.82, -0.55, 0.65], 0.6));
    return spec;
  },
  async inventory() {
    const parts = [
      mesh(rbox(1.12, 1.3, 0.72, 0.26), plastic(0xe08a2e), [0, -0.08, 0]),
      mesh(rbox(1.14, 0.52, 0.76, 0.2), plastic(0xb8641c), [0, 0.42, 0]),
      mesh(rbox(0.78, 0.5, 0.24, 0.12), plastic(0xf0a548), [0, -0.38, 0.4]),
      mesh(rbox(0.18, 0.14, 0.1, 0.03), gold(), [0, 0.24, 0.42]),
      mesh(new THREE.TorusGeometry(0.22, 0.06, 12, 28, Math.PI), plastic(0x8a4a14), [0, 0.7, 0]),
    ];
    return { object: group(...parts), yaw: 24, pitch: 14, fill: 0.84 };
  },
  async teleport() {
    const parts = [
      mesh(new THREE.TorusGeometry(0.82, 0.17, 24, 64), plastic(0x6b4cff)),
      mesh(new THREE.CircleGeometry(0.72, 64), toon(0xffffff, { map: swirlTexture('#5b2bd6', '#ff6bf0'), spec: 0, glow: 0.1 }), [0, 0, -0.02]),
    ];
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * Math.PI * 2;
      parts.push(mesh(new THREE.SphereGeometry(0.09, 16, 12), gem(0x6ff2ff), [Math.cos(a) * 0.82, Math.sin(a) * 0.82, 0.15]));
    }
    return { object: group(...parts), yaw: 14, pitch: 8, fill: 0.82 };
  },
  async spin() {
    const face = painted(wheelTexture(['#ff3b5c', '#ffd23a', '#3ddc5a', '#2f8cff', '#c86bff', '#ff8a1c', '#3bd1ff', '#ff6bd5']), { clearcoat: 0.9 });
    const rim = gold();
    const disc = mesh(new THREE.CylinderGeometry(0.92, 0.92, 0.14, 64), [rim, face, rim], [0, 0.08, 0], [Math.PI / 2, 0, 0]);
    const parts = [
      disc,
      mesh(new THREE.TorusGeometry(0.93, 0.07, 14, 64), rim, [0, 0.08, 0]),
      mesh(new THREE.SphereGeometry(0.14, 24, 16), rim, [0, 0.08, 0.1]),
      mesh(extrude(polygon([[-0.16, 0.2], [0.16, 0.2], [0, -0.2]]), 0.1, 0.04), plastic(0xff3b3b), [0, 1.02, 0.1]),
      mesh(rbox(0.9, 0.18, 0.4, 0.06), plastic(0x7a4a2a), [0, -0.96, -0.05]),
    ];
    return { object: group(...parts), yaw: 12, pitch: 8, fill: 0.84 };
  },
  async codes() {
    const parts = [
      mesh(extrude(ticket(), 0.18, 0.05), plastic(0xa35cff)),
      mesh(extrude(star(5, 0.32, 0.15), 0.06, 0.03), plastic(0xffd23a), [0.12, 0, 0.14]),
    ];
    const g = group(...parts);
    g.rotation.z = 0.28;
    return { object: g, yaw: 14, pitch: 12, fill: 0.84 };
  },
  async moon() {
    const parts = [
      mesh(extrude(crescent(), 0.3, 0.1), plastic(0xfff3c4, { glow: 0.1 })),
      mesh(new THREE.SphereGeometry(0.32, 28, 18), plastic(0x8d93a6), [0.38, -0.62, 0.3]),
      mesh(new THREE.SphereGeometry(0.24, 28, 18), plastic(0x8d93a6), [0.0, -0.66, 0.32]),
      mesh(new THREE.SphereGeometry(0.22, 28, 18), plastic(0x8d93a6), [0.72, -0.7, 0.28]),
    ];
    return { object: group(...parts), yaw: 10, pitch: 6, fill: 0.84 };
  },
  async pumpkin() {
    const geo = lathe(Array.from({ length: 33 }, (_, i) => {
      const y = -0.72 + (1.44 * i) / 32;
      return [Math.max(0.001, 0.92 * Math.sqrt(Math.max(0, 1 - (y / 0.74) ** 2))), y];
    }), 96);
    const pos = geo.attributes.position;
    const v = new THREE.Vector3();
    for (let i = 0; i < pos.count; i++) {
      v.fromBufferAttribute(pos, i);
      const a = Math.atan2(v.z, v.x);
      const k = 1 - 0.07 * (1 - Math.cos(a * 8));
      pos.setXYZ(i, v.x * k, v.y, v.z * k);
    }
    geo.computeVertexNormals();
    const face = light(0xffd23f, 0.9);
    const parts = [
      mesh(geo, plastic(0xff8a1c)),
      mesh(new THREE.CylinderGeometry(0.1, 0.15, 0.36, 16), plastic(0x5a8a2a), [0.04, 0.84, 0], [0, 0, -0.2]),
      mesh(extrude(polygon([[-0.16, -0.1], [0.16, -0.1], [0, 0.16]]), 0.08, 0.02), face, [-0.3, 0.16, 0.86]),
      mesh(extrude(polygon([[-0.16, -0.1], [0.16, -0.1], [0, 0.16]]), 0.08, 0.02), face, [0.3, 0.16, 0.86]),
      mesh(extrude(polygon([[-0.48, 0.05], [-0.3, -0.06], [-0.18, 0.04], [0, -0.08], [0.18, 0.04], [0.3, -0.06], [0.48, 0.05], [0.3, -0.3], [-0.3, -0.3]]), 0.08, 0.02), face, [0, -0.24, 0.84]),
    ];
    return { object: group(...parts), yaw: 0, pitch: 10, fill: 0.84 };
  },
  async money_boost() {
    const bag = lathe([[0, -0.78], [0.56, -0.75], [0.8, -0.46], [0.82, -0.06], [0.62, 0.3], [0.28, 0.48], [0.2, 0.52], [0, 0.52]], 64);
    const parts = [
      mesh(bag, plastic(0xffc23a), [0, -0.1, 0]),
      mesh(new THREE.ConeGeometry(0.42, 0.36, 32, 1, true), plastic(0xffc23a), [0, 0.6, 0], [Math.PI, 0, 0]),
      mesh(new THREE.TorusGeometry(0.22, 0.07, 12, 32), plastic(0xb5651d), [0, 0.42, 0], [Math.PI / 2, 0, 0]),
      mesh(text('$', 0.62, 0.1, 0.025), plastic(0x2fae4c), [0, -0.22, 0.78]),
    ];
    return { object: group(...parts), yaw: 0, pitch: 10, fill: 0.84 };
  },
  async chest() {
    const wood = plastic(0xa8622c, { roughness: 0.5 }), trim = gold();
    const parts = [
      mesh(rbox(1.4, 0.72, 0.9, 0.06), wood, [0, -0.3, 0]),
      mesh(new THREE.CylinderGeometry(0.45, 0.45, 1.4, 32, 1, false, 0, Math.PI), wood, [0, 0.06, 0], [0, 0, Math.PI / 2]),
      mesh(new THREE.BoxGeometry(0.16, 0.76, 0.94), trim, [-0.5, -0.3, 0]),
      mesh(new THREE.BoxGeometry(0.16, 0.76, 0.94), trim, [0.5, -0.3, 0]),
      mesh(new THREE.CylinderGeometry(0.47, 0.47, 0.16, 32, 1, false, 0, Math.PI), trim, [-0.5, 0.06, 0], [0, 0, Math.PI / 2]),
      mesh(new THREE.CylinderGeometry(0.47, 0.47, 0.16, 32, 1, false, 0, Math.PI), trim, [0.5, 0.06, 0], [0, 0, Math.PI / 2]),
      mesh(rbox(0.28, 0.34, 0.1, 0.04), trim, [0, -0.08, 0.48]),
    ];
    return { object: group(...parts), yaw: 26, pitch: 18, fill: 0.84 };
  },
  async magnet() {
    const pts = [[-0.45, -0.5, 0], [-0.45, 0.1, 0], [-0.3, 0.48, 0], [0, 0.6, 0], [0.3, 0.48, 0], [0.45, 0.1, 0], [0.45, -0.5, 0]];
    const parts = [
      mesh(tube(pts, 0.22), plastic(0xff3b3b)),
      mesh(new THREE.CylinderGeometry(0.225, 0.225, 0.3, 32), silver(), [-0.45, -0.62, 0]),
      mesh(new THREE.CylinderGeometry(0.225, 0.225, 0.3, 32), silver(), [0.45, -0.62, 0]),
    ];
    const g = group(...parts);
    g.rotation.z = -0.6;
    return { object: g, yaw: 16, pitch: 12, fill: 0.84 };
  },
  async shield() {
    const parts = [
      mesh(extrude(shield(1.7, 2.0), 0.16, 0.08), gold(), [0, 0, -0.06]),
      mesh(extrude(shield(1.38, 1.66), 0.2, 0.06), plastic(0x2f6dff), [0, 0.02, 0.06]),
      mesh(extrude(star(5, 0.4, 0.19), 0.06, 0.03), plastic(0xffcc1f), [0, 0.08, 0.22]),
    ];
    return { object: group(...parts), yaw: 14, pitch: 8, fill: 0.84 };
  },
  async pets() {
    const pink = plastic(0xff6fb5);
    const parts = [mesh(new THREE.SphereGeometry(0.42, 36, 24), pink, [0, -0.3, 0], [0, 0, 0], [1.2, 1, 0.5])];
    for (const [x, y, s] of [[-0.6, 0.2, 0.22], [-0.22, 0.48, 0.24], [0.22, 0.48, 0.24], [0.6, 0.2, 0.22]]) {
      parts.push(mesh(new THREE.SphereGeometry(s, 28, 18), pink, [x, y, 0], [0, 0, 0], [1, 1.15, 0.6]));
    }
    return { object: group(...parts), yaw: 10, pitch: 10, fill: 0.82 };
  },
  async fishing() {
    const parts = [
      mesh(extrude(fishShape(), 0.3, 0.08), plastic(0xff8a1c), [0, 0, 0]),
      mesh(new THREE.SphereGeometry(0.12, 20, 14), plastic(0xffffff), [0.6, 0.12, 0.2]),
      mesh(new THREE.SphereGeometry(0.06, 16, 12), plastic(0x1a1426), [0.63, 0.12, 0.28]),
      mesh(extrude(polygon([[-0.2, 0], [0.2, 0], [0, 0.3]]), 0.06, 0.02), plastic(0xff5a1c), [0.0, 0.42, 0]),
    ];
    return { object: group(...parts), yaw: 18, pitch: 8, fill: 0.84 };
  },
  async battle() {
    const blade = polygon([[-0.11, -0.25], [0.11, -0.25], [0.11, 0.95], [0, 1.2], [-0.11, 0.95]]);
    const parts = [
      mesh(extrude(blade, 0.08, 0.04), silver()),
      mesh(rbox(0.7, 0.14, 0.18, 0.05), gold(), [0, -0.3, 0]),
      mesh(new THREE.CylinderGeometry(0.08, 0.08, 0.42, 20), plastic(0x7a3f1a), [0, -0.58, 0]),
      mesh(new THREE.SphereGeometry(0.12, 20, 14), gold(), [0, -0.84, 0]),
    ];
    const g = group(...parts);
    g.rotation.z = -0.78;
    return { object: g, yaw: 12, pitch: 8, fill: 0.84 };
  },
  async search() {
    const parts = [
      mesh(new THREE.TorusGeometry(0.5, 0.11, 18, 48), gold(), [-0.18, 0.18, 0]),
      mesh(new THREE.CircleGeometry(0.46, 48), light(0xa8e8ff, 0.35), [-0.18, 0.18, 0]),
      mesh(new THREE.CylinderGeometry(0.11, 0.13, 0.7, 20), plastic(0x8a4a1c), [0.42, -0.42, 0], [0, 0, Math.PI / 4]),
    ];
    parts[1].userData.noOutline = true;
    return { object: group(...parts), yaw: 10, pitch: 8, fill: 0.84 };
  },
  async notifications() {
    const bell = lathe([[0, -0.46], [0.72, -0.46], [0.6, -0.36], [0.46, 0.0], [0.38, 0.4], [0.16, 0.6], [0, 0.62]], 64);
    const parts = [
      mesh(bell, gold()),
      mesh(new THREE.SphereGeometry(0.14, 20, 14), gold(), [0, -0.56, 0]),
      mesh(new THREE.TorusGeometry(0.1, 0.04, 10, 20), gold(), [0, 0.7, 0]),
      mesh(new THREE.SphereGeometry(0.18, 20, 14), plastic(0xff3b3b), [0.5, 0.42, 0.3]),
    ];
    return { object: group(...parts), yaw: 10, pitch: 10, fill: 0.84 };
  },
  async map() {
    const mat = painted(mapTexture(), { clearcoat: 0.3, roughness: 0.7 });
    const parts = [];
    for (let i = 0; i < 3; i++) {
      const panel = new THREE.PlaneGeometry(0.62, 1.3);
      const uv = panel.attributes.uv;
      for (let j = 0; j < uv.count; j++) uv.setX(j, (uv.getX(j) + i) / 3);
      parts.push(mesh(panel, mat, [-0.6 + i * 0.6, 0, i % 2 ? -0.12 : 0.04], [0, i % 2 ? 0.38 : -0.38, 0]));
      parts[i].material.side = THREE.DoubleSide;
    }
    return { object: group(...parts), yaw: 6, pitch: 10, fill: 0.84 };
  },
  async base() {
    const roof = polygon([[-0.95, 0], [0.95, 0], [0, 0.72]]);
    const parts = [
      mesh(rbox(1.3, 0.9, 1.0, 0.06), plastic(0xfff1d6, { roughness: 0.5 }), [0, -0.3, 0]),
      mesh(extrude(roof, 1.14, 0.05), plastic(0xff4b4b), [0, 0.4, 0]),
      mesh(rbox(0.32, 0.5, 0.1, 0.04), plastic(0x8a4a1c), [0, -0.5, 0.5]),
      mesh(rbox(0.26, 0.26, 0.08, 0.03), plastic(0x7fd6ff), [-0.4, -0.2, 0.5]),
      mesh(rbox(0.26, 0.26, 0.08, 0.03), plastic(0x7fd6ff), [0.4, -0.2, 0.5]),
    ];
    return { object: group(...parts), yaw: 26, pitch: 14, fill: 0.84 };
  },
  async plus() { return { object: badge(0x2fcf4a, plus(1, 0.36), [0, 0, 0], 1.4), yaw: 10, pitch: 8, fill: 0.8 }; },
  async check() { return { object: badge(0x2fcf4a, check(), [0, 0, 0], 1.4), yaw: 10, pitch: 8, fill: 0.8 }; },
  async close() { return { object: badge(0xff3b4f, cross(1, 0.36), [0, 0, 0], 1.4), yaw: 10, pitch: 8, fill: 0.8 }; },
};
