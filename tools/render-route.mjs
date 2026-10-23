#!/usr/bin/env node
// Рисует маршрут сюжета по карте: docs/карта-маршрут.svg
//
//   node tools/render-route.mjs
//
// Вид сверху (X → влево, Z → вниз, как на плане). Точки сцен окрашены по актам,
// серые круги — кластеры вывесок, крестики — живые НПС, звезда — арена.

import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const story = JSON.parse(fs.readFileSync(path.join(ROOT, 'story/story.json'), 'utf8'));
const layout = JSON.parse(fs.readFileSync(path.join(ROOT, 'game/layout.json'), 'utf8'));
const OUT = path.join(ROOT, 'docs/карта-маршрут.svg');

const ACT_COLORS = { 1: '#7dd3fc', 2: '#a3e635', 3: '#fbbf24', 4: '#f97316' };
const ACT_NAMES = { 1: 'I. Тишина', 2: 'II. Первого сентября', 3: 'III. Сплав', 4: 'IV. Жестокий сплав' };

// ── маршрут сцен — та же математика, что в WorldKit.lua ──────────────────────
const world = {
  spawn: layout.spawn,
  clusters: Object.fromEntries(layout.clusters.map((c) => [c.id, c])),
};

const route = (story.meta.map.route ?? []).map((step) => {
  const pos = step.zone === 'spawn' ? world.spawn : world.clusters[step.zone]?.center;
  return pos ? { act: step.act, zone: step.zone, pos } : null;
}).filter(Boolean);

const len = (a, b) => Math.hypot(a[0] - b[0], a[2] - b[2]);
const lerp = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];

function along(points, t) {
  if (points.length < 2) return points[0];
  const total = points.slice(1).reduce((s, p, i) => s + len(points[i], p), 0);
  if (!total) return points[0];
  let want = t * total;
  for (let i = 1; i < points.length; i++) {
    const seg = len(points[i - 1], points[i]);
    if (want <= seg) return lerp(points[i - 1], points[i], want / seg);
    want -= seg;
  }
  return points[points.length - 1];
}

const byAct = {};
for (const step of route) (byAct[step.act] ??= []).push(step);
const counts = {};
for (const node of story.nodes) counts[node.act] = (counts[node.act] ?? 0) + 1;

const seen = {};
const scenePoints = [];
for (const node of story.nodes) {
  const points = (byAct[node.act] ?? route).map((s) => s.pos);
  const total = counts[node.act] ?? 1;
  seen[node.act] = (seen[node.act] ?? 0) + 1;
  const t = total <= 1 ? 0 : (seen[node.act] - 1) / (total - 1);
  const pos = along(points, t);
  scenePoints.push({ id: node.id, act: node.act, pos, scene: node.scene });
}

// ── проекция ────────────────────────────────────────────────────────────────
const all = [
  ...scenePoints.map((p) => p.pos),
  ...(layout.cast ?? []).map((c) => c.pos),
  ...layout.clusters.map((c) => c.center),
  layout.spawn,
];
const xs = all.map((p) => p[0]);
const zs = all.map((p) => p[2]);
const pad = 90;
const W = 1400;
const scale = (W - pad * 2) / Math.max(Math.max(...xs) - Math.min(...xs), 1);
const H = Math.round((Math.max(...zs) - Math.min(...zs)) * scale + pad * 2);
const px = (x) => pad + (Math.max(...xs) - x) * scale; // X растёт влево, как на плане
const pz = (z) => pad + (z - Math.min(...zs)) * scale;

const svg = [];
svg.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="ui-sans-serif, system-ui, sans-serif">`);
svg.push(`<rect width="${W}" height="${H}" fill="#0b0e16"/>`);
svg.push(`<text x="${pad}" y="44" fill="#e8ecf6" font-size="26" font-weight="600">Маршрут сюжета по карте neirogh.rbxl</text>`);
svg.push(`<text x="${pad}" y="68" fill="#8b93a7" font-size="14">${story.nodes.length} сцен · 4 акта · ${layout.clusters.length} кластеров · ${(layout.cast ?? []).length} живых НПС · вид сверху, X влево</text>`);

// кластеры
for (const c of layout.clusters) {
  svg.push(`<circle cx="${px(c.center[0]).toFixed(1)}" cy="${pz(c.center[2]).toFixed(1)}" r="46" fill="#151b29" stroke="#232c40"/>`);
  svg.push(`<text x="${px(c.center[0]).toFixed(1)}" y="${(pz(c.center[2]) + 4).toFixed(1)}" fill="#5d6884" font-size="11" text-anchor="middle">${c.id}</text>`);
}

// НПС
for (const npc of layout.cast ?? []) {
  svg.push(`<path d="M${(px(npc.pos[0]) - 3).toFixed(1)} ${pz(npc.pos[2]).toFixed(1)}h6M${px(npc.pos[0]).toFixed(1)} ${(pz(npc.pos[2]) - 3).toFixed(1)}v6" stroke="#38425a" stroke-width="1"/>`);
}

// маршрут
for (let i = 1; i < route.length; i++) {
  const a = route[i - 1];
  const b = route[i];
  svg.push(
    `<line x1="${px(a.pos[0]).toFixed(1)}" y1="${pz(a.pos[2]).toFixed(1)}" x2="${px(b.pos[0]).toFixed(1)}" y2="${pz(b.pos[2]).toFixed(1)}" stroke="#2b3446" stroke-width="2"/>`,
  );
}

// сцены
for (const point of scenePoints) {
  const color = ACT_COLORS[point.act] ?? '#8b93a7';
  svg.push(
    `<circle cx="${px(point.pos[0]).toFixed(1)}" cy="${pz(point.pos[2]).toFixed(1)}" r="5" fill="${color}" fill-opacity="0.9"><title>${point.id} — ${point.scene ?? ''}</title></circle>`,
  );
}

// спавн и арена
svg.push(`<circle cx="${px(layout.spawn[0]).toFixed(1)}" cy="${pz(layout.spawn[2]).toFixed(1)}" r="9" fill="none" stroke="#7dd3fc" stroke-width="2"/>`);
svg.push(`<text x="${(px(layout.spawn[0]) + 14).toFixed(1)}" y="${(pz(layout.spawn[2]) + 4).toFixed(1)}" fill="#7dd3fc" font-size="12">спавн</text>`);
if (layout.finale?.center) {
  const ax = px(layout.finale.center[0]);
  const az = pz(layout.finale.center[2]);
  svg.push(`<path d="M${ax} ${az - 11}l3 7 7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z" fill="#f97316"/>`);
  svg.push(`<text x="${(ax + 16).toFixed(1)}" y="${(az + 4).toFixed(1)}" fill="#f97316" font-size="12">арена · 50 огней</text>`);
}

// легенда
let lx = pad;
for (const act of [1, 2, 3, 4]) {
  svg.push(`<circle cx="${lx}" cy="${H - 34}" r="5" fill="${ACT_COLORS[act]}"/>`);
  svg.push(`<text x="${lx + 12}" y="${H - 30}" fill="#8b93a7" font-size="13">${ACT_NAMES[act]}</text>`);
  lx += 250;
}

svg.push('</svg>');

fs.writeFileSync(OUT, svg.join('\n'), 'utf8');
console.log(`  → ${path.relative(ROOT, OUT)} (${W}×${H}, сцен: ${scenePoints.length})`);
