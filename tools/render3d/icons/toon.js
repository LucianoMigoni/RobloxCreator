// Sombreado de dibujo animado para los íconos, como los de los hits (Anime Dice, Steal An Egg, Throw Food
// For Animals): tres tonos planos por color (luz, base y sombra más saturada), un brillo blanco duro y
// nada de reflejos de ambiente. Los colores se escriben tal cual se ven (sin gestión de color).
import * as THREE from 'three';

THREE.ColorManagement.enabled = false;

// Dirección de la luz en el mundo (arriba a la izquierda, un poco al frente). La página la pasa a la
// vista de la cámara antes de dibujar.
export const LIGHT = new THREE.Vector3(-0.55, 0.8, 0.6).normalize();
const lightView = { value: new THREE.Vector3() };
export function updateLight(camera) {
  lightView.value.copy(LIGHT).transformDirection(camera.matrixWorldInverse);
}

const vertex = `
  varying vec3 vN;
  varying vec3 vV;
  varying vec3 vPos;
  varying vec2 vUv;
  void main() {
    vec4 mv = modelViewMatrix * vec4(position, 1.0);
    vN = normalize(normalMatrix * normal);
    vV = normalize(-mv.xyz);
    vPos = mv.xyz;
    vUv = uv;
    gl_Position = projectionMatrix * mv;
  }`;

const fragment = `
  uniform vec3 color;
  uniform sampler2D map;
  uniform float useMap;
  uniform vec3 lightDir;
  uniform float glow;
  uniform float opacity;
  uniform float spec;
  uniform float shininess;
  uniform float flatShade;
  uniform float lift;
  uniform vec3 shadeTint;
  varying vec3 vN;
  varying vec3 vV;
  varying vec3 vPos;
  varying vec2 vUv;
  void main() {
    vec3 base = color;
    if (useMap > 0.5) base *= texture2D(map, vUv).rgb;
    vec3 N = normalize(vN);
    if (flatShade > 0.5) N = normalize(cross(dFdx(vPos), dFdy(vPos)));
    if (!gl_FrontFacing) N = -N;
    vec3 L = normalize(lightDir);
    float ndl = dot(N, L);
    vec3 lightTone = mix(base, vec3(1.0), 0.2 + lift);
    vec3 shadeTone = base * shadeTint;
    vec3 col = mix(shadeTone, base, smoothstep(-0.12, -0.04, ndl));
    col = mix(col, lightTone, smoothstep(0.4, 0.48, ndl));
    vec3 H = normalize(L + normalize(vV));
    float s = pow(max(dot(N, H), 0.0), shininess);
    col = mix(col, vec3(1.0), smoothstep(0.5, 0.58, s) * spec);
    col += base * glow;
    gl_FragColor = vec4(min(col, vec3(1.0)), opacity);
  }`;

// o: { map, glow, opacity, spec, shininess, flat, lift, shade }
export function toon(color, o = {}) {
  const m = new THREE.ShaderMaterial({
    uniforms: {
      color: { value: new THREE.Color(color) },
      map: { value: o.map ?? null },
      useMap: { value: o.map ? 1 : 0 },
      lightDir: lightView,
      glow: { value: o.glow ?? 0 },
      opacity: { value: o.opacity ?? 1 },
      spec: { value: o.spec ?? 0.85 },
      shininess: { value: o.shininess ?? 70 },
      flatShade: { value: o.flat ? 1 : 0 },
      lift: { value: o.lift ?? 0 },
      shadeTint: { value: new THREE.Color(...(o.shade ?? [0.7, 0.64, 0.82])) },
    },
    vertexShader: vertex,
    fragmentShader: fragment,
    transparent: (o.opacity ?? 1) < 1,
    depthWrite: (o.opacity ?? 1) >= 1,
  });
  m.userData.toonColor = color;
  return m;
}
