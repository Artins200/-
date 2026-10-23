#!/usr/bin/env node
/**
 * analyze-place.mjs — разобрать карту по координатам и понять, что с чем связано.
 *
 *   node tools/analyze-place.mjs            # читает game/place-map.json
 *   node tools/analyze-place.mjs --check    # только проверки (для npm test)
 *
 * Логика:
 *   1. вывески группируются в «коридоры» по Z, внутри коридора — в кластеры
 *      по разрывам вдоль X (разрыв > GAP значит между сценами пусто);
 *   2. персонажи (модели с Humanoid) привязываются к ближайшему кластеру;
 *   3. телепорты превращаются в рёбра графа «вход → выход», пешие соседи —
 *      в рёбра «рядом»;
 *   4. кластер, рядом с которым горит огонь и который дальше всех от спавна,
 *      объявляется ареной финала.
 *
 * Пишет game/layout.json и docs/КАРТА.md.
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const MAP_PATH = path.join(ROOT, 'game', 'place-map.json');
const OUT_JSON = path.join(ROOT, 'game', 'layout.json');
const OUT_DOC = path.join(ROOT, 'docs', 'КАРТА.md');
const CHECK_ONLY = process.argv.includes('--check');

const GAP = 170;         // разрыв вдоль X, после которого начинается новая сцена
const BAND = 25;         // вывески ближе этого по Z — один коридор
const NEAR = 160;        // «пешая» связь между соседними кластерами
const FIRE_RADIUS = 30;  // насколько близко огонь должен быть к кластеру

const map = JSON.parse(fs.readFileSync(MAP_PATH, 'utf8'));
const errors = [];

const round = (v, p = 0) => +Number(v).toFixed(p);
const dist2 = (a, b) => Math.hypot(a[0] - b[0], a[2] - b[2]);
const centroid = (points) => [0, 1, 2].map((i) => points.reduce((s, p) => s + p[i], 0) / points.length);

/* ---------- 1. кластеры вывесок ---------- */
// Коридоры: сортируем по Z и режем, когда соседние ряды расходятся больше BAND.
const byZ = [...map.signs].sort((a, b) => a.z - b.z);
const bands = new Map();
let bandIndex = -1;
let prevZ = null;
for (const s of byZ) {
  if (prevZ === null || Math.abs(s.z - prevZ) > BAND) bandIndex += 1;
  if (!bands.has(bandIndex)) bands.set(bandIndex, []);
  bands.get(bandIndex).push(s);
  prevZ = s.z;
}

const clusters = [];
for (const [bandKey, list] of [...bands.entries()].sort((a, b) => a[0] - b[0])) {
  const sorted = [...list].sort((a, b) => b.x - a.x); // от правого края к левому
  let group = [];
  const flush = () => {
    if (!group.length) return;
    const xs = group.map((s) => s.x);
    const zs = group.map((s) => s.z);
    const ys = group.map((s) => s.y);
    clusters.push({
      id: `z${bandKey}_c${clusters.length}`,
      band: bandKey,
      signCount: group.length,
      minX: round(Math.min(...xs), 1),
      maxX: round(Math.max(...xs), 1),
      z: round(centroid(group.map((s) => [s.x, s.y, s.z]))[2], 1),
      y: round(centroid(group.map((s) => [s.x, s.y, s.z]))[1], 1),
      center: [round(centroid(group.map((s) => [s.x, s.y, s.z]))[0], 1), round(centroid(group.map((s) => [s.x, s.y, s.z]))[1], 1), round(centroid(group.map((s) => [s.x, s.y, s.z]))[2], 1)],
      length: round(Math.max(...xs) - Math.min(...xs), 1),
      firstLine: sorted[0]?.text,
      lastLine: sorted[sorted.length - 1]?.text,
    });
    group = [];
  };
  for (const s of sorted) {
    if (group.length && Math.abs(group[group.length - 1].x - s.x) > GAP) flush();
    group.push(s);
  }
  flush();
}
clusters.sort((a, b) => a.band - b.band || b.maxX - a.maxX);

/* ---------- 2. персонажи ---------- */
const actors = (map.actors ?? []).filter((a) => a.pos && !/^(Room|Part|Sign|Trash.*)$/i.test(a.name));
const nearestCluster = (pos, filter = () => true) => {
  let best = null;
  for (const c of clusters) {
    if (!filter(c)) continue;
    const d = dist2(pos, c.center);
    if (!best || d < best.dist) best = { cluster: c, dist: d };
  }
  return best;
};
const byCluster = new Map();
for (const a of actors) {
  const near = nearestCluster(a.pos);
  if (!near) continue;
  if (!byCluster.has(near.cluster.id)) byCluster.set(near.cluster.id, new Map());
  const m = byCluster.get(near.cluster.id);
  m.set(a.name, (m.get(a.name) ?? 0) + 1);
}
for (const c of clusters) {
  c.actors = [...(byCluster.get(c.id) ?? new Map())].map(([name, count]) => ({ name, count }));
}

/* ---------- 3. огонь ---------- */
const firePoints = map.fires ?? [];
const fireCenter = firePoints.length ? centroid(firePoints) : null;
const fireZone = fireCenter
  ? {
      center: fireCenter.map((v) => round(v, 1)),
      sizeX: round(Math.max(...firePoints.map((p) => p[0])) - Math.min(...firePoints.map((p) => p[0])), 1),
      sizeZ: round(Math.max(...firePoints.map((p) => p[2])) - Math.min(...firePoints.map((p) => p[2])), 1),
      count: firePoints.length,
      nearestCluster: nearestCluster(fireCenter)?.cluster.id ?? null,
    }
  : null;

/* ---------- 4. телепорты ---------- */
const teleports = [];
for (const [i, t] of (map.teleports ?? []).entries()) {
  const parts = t.parts ?? [];
  if (parts.length < 2) continue;
  const from = parts[0].pos;
  const to = parts[1].pos;
  teleports.push({
    id: `tp${i + 1}`,
    name: t.name,
    from,
    to,
    distance: round(dist2(from, to), 1),
    fromCluster: nearestCluster(from)?.cluster.id ?? null,
    toCluster: nearestCluster(to)?.cluster.id ?? null,
  });
}
const chainOf = (id) => {
  const seen = new Set([id]);
  const queue = [id];
  const order = [];
  while (queue.length) {
    const cur = queue.shift();
    order.push(cur);
    for (const t of teleports) {
      if (t.fromCluster !== cur) continue;
      if (t.toCluster && !seen.has(t.toCluster)) {
        seen.add(t.toCluster);
        queue.push(t.toCluster);
      }
    }
  }
  return order;
};

/* ---------- 5. рёбра ---------- */
const links = [];
for (let i = 0; i < clusters.length; i++) {
  for (let j = i + 1; j < clusters.length; j++) {
    const a = clusters[i];
    const b = clusters[j];
    const gap = Math.abs(a.center[0] - b.center[0]) - (a.length + b.length) / 2;
    const d = dist2(a.center, b.center);
    if (a.band === b.band && gap < NEAR) {
      links.push({ from: a.id, to: b.id, kind: 'рядом', distance: round(d, 1) });
    }
  }
}
for (const t of teleports) {
  if (t.fromCluster && t.toCluster) {
    links.push({ from: t.fromCluster, to: t.toCluster, kind: 'телепорт', distance: t.distance, teleport: t.id });
  }
}

/* ---------- 6. финальная арена ---------- */
const spawn = map.spawn;
const farthest = spawn
  ? clusters.slice().sort((a, b) => dist2(b.center, spawn) - dist2(a.center, spawn))[0]
  : clusters[0];
const fireNextTo = fireZone ? clusters.find((c) => c.id === fireZone.nearestCluster) : null;
const arena = fireNextTo ?? farthest;
const arenaCheck = fireZone
  ? dist2(fireZone.center, arena.center) <= Math.max(arena.length, 1) / 2 + FIRE_RADIUS
  : false;

/* ---------- 7. проверки ---------- */
if (!clusters.length) errors.push('не найдено ни одного кластера вывесок');
if (!spawn) errors.push('не найдена точка спавна');
if (!teleports.length) errors.push('не найдено ни одного телепорта');
if (!fireZone) errors.push('не найдено огня');
if (!arena) errors.push('не определена арена финала');
else if (farthest.id !== arena.id) {
  // не ошибка, но важно для отчёта: арена с огнём не самая дальняя точка карты
}
for (const c of clusters) {
  if (!c.actors.length) continue;
  if (c.signCount < 1) errors.push(`кластер ${c.id} без текста`);
}

const layout = {
  source: map.source,
  generated: new Date().toISOString().slice(0, 10),
  spawn,
  constants: { GAP, BAND, NEAR, FIRE_RADIUS },
  clusters,
  actorsTotal: actors.length,
  fireZone,
  teleports,
  links,
  finale: {
    arena: arena?.id ?? null,
    center: arena?.center ?? null,
    fireCenter: fireZone?.center ?? null,
    spawnDistance: arena && spawn ? round(dist2(arena.center, spawn), 1) : null,
    viaTeleport: teleports.filter((t) => t.toCluster === arena?.id).map((t) => t.id),
    chain: arena ? chainOf(arena.id) : [],
    fireCheck: arenaCheck,
  },
};
fs.writeFileSync(OUT_JSON, JSON.stringify(layout, null, 1), 'utf8');

/* ---------- 8. отчёт ---------- */
const table = clusters
  .map(
    (c) =>
      `| \`${c.id}\` | ${c.signCount} | ${c.minX}…${c.maxX} | ${c.z} | ${c.actors.map((a) => a.name).slice(0, 6).join(', ') || '—'} |`,
  )
  .join('\n');

const tpTable = teleports
  .map((t) => `| \`${t.id}\` | ${JSON.stringify(t.from)} | ${JSON.stringify(t.to)} | ${t.distance} | \`${t.fromCluster}\` → \`${t.toCluster}\` |`)
  .join('\n');

const doc = `# Карта и связанность моделей

> Сгенерировано \`node tools/analyze-place.mjs\` из \`game/place-map.json\`.
> Карту достаёт \`node tools/place-import.mjs neirogh.rbxl game/place-map.json\` (нужен \`rbx-dom\`).

**Вывесок:** ${map.signs.length} · **кластеров:** ${clusters.length} · **персонажей:** ${actors.length} ·
**телепортов:** ${teleports.length} · **огней:** ${firePoints.length}

## Как считалась связанность

1. Все вывески с текстом разложены по Z-полосам шириной ${BAND}.
2. Внутри полосы текст идёт вдоль X; разрыв больше ${GAP} юнитов — граница между сценами.
3. Модель персонажа привязывается к ближайшему кластеру по XZ.
4. Кластеры ближе ${NEAR} юнитов друг к другу — «рядом» (можно дойти пешком).
5. Папки \`Teleport One Way\` дают готовые рёбра «вход → выход»: это авторские телепорты карты.
6. Арена финала — кластер, у которого горит огонь; если огня рядом нет, берётся самая дальняя точка.

## Кластеры

| id | вывесок | X | Z | персонажи |
|---|---|---|---|---|
${table}

## Телепорты карты

| id | вход | выход | дистанция | связь |
|---|---|---|---|---|
${tpTable}

## Огонь

${fireZone ? `Полоса огня: центр ${JSON.stringify(fireZone.center)}, ${fireZone.sizeX}×${fireZone.sizeZ}, точек: ${fireZone.count}. Рядом кластер \`${fireZone.nearestCluster}\`.` : 'Огонь не найден.'}

## Финал

- Спавн: ${JSON.stringify(spawn)}
- Арена: \`${layout.finale.arena}\` в ${JSON.stringify(layout.finale.center)}
- Огонь: ${JSON.stringify(layout.finale.fireCenter)}, попадание в кластер: ${layout.finale.fireCheck ? 'да' : 'нет'}
- От спавна: ${layout.finale.spawnDistance} юнитов
- Телепорт в арену: ${layout.finale.viaTeleport.length ? layout.finale.viaTeleport.map((t) => `\`${t}\``).join(', ') : 'нет прямого, идём цепочкой'}
- Цепочка: ${layout.finale.chain.map((c) => `\`${c}\``).join(' → ') || '—'}

## Проверки

${errors.length ? errors.map((e) => `- ❌ ${e}`).join('\n') : '✅ Все проверки пройдены.'}
`;
fs.writeFileSync(OUT_DOC, doc, 'utf8');

if (!CHECK_ONLY) {
  console.log(`  «${map.source}»: ${clusters.length} кластеров, ${teleports.length} телепортов, огонь в ${JSON.stringify(layout.finale.fireCenter)}`);
  console.log(`  арена финала: ${layout.finale.arena} ${JSON.stringify(layout.finale.center)} (${layout.finale.spawnDistance} от спавна)`);
  console.log(`  → ${path.relative(ROOT, OUT_JSON)}`);
  console.log(`  → ${path.relative(ROOT, OUT_DOC)}`);
}
if (errors.length) {
  console.log('\n  ОШИБКИ:');
  for (const e of errors) console.log(`   x ${e}`);
  process.exit(1);
}
if (CHECK_ONLY) console.log(`  карта: ${clusters.length} кластеров, ${teleports.length} телепортов — OK`);
