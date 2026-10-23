#!/usr/bin/env node
/**
 * place-import.mjs — вытащить карту из бинарного place-файла Roblox.
 *
 *   npm i --no-save rbx-dom          # нужен нативный биндинг rbx-dom
 *   node tools/place-import.mjs neirogh.rbxl game/place-map.json
 *
 * Что достаём:
 *   spawn     — точка появления игрока (SpawnLocation);
 *   zones     — модели-зоны, вокруг которых крутится лобби (2 Player, LeaveRoomPart);
 *   teleports — пары «вход → выход» из папок Teleport One Way;
 *   fires     — все Part с именем Fire (по ним видно, где горит свет);
 *   signs     — вывески с текстом: это и есть сюжет, записанный в геометрии.
 *
 * Результат — game/place-map.json. Его читает tools/analyze-place.mjs (уже без
 * rbx-dom), поэтому анализ координат воспроизводится на чистом Node.
 */
import fs from 'node:fs';
import path from 'node:path';

const [, , file = 'neirogh.rbxl', out = 'game/place-map.json'] = process.argv;

let readBinary;
try {
  ({ readBinary } = await import('rbx-dom'));
} catch {
  console.error(
    'Нужен пакет rbx-dom: npm i --no-save rbx-dom\n' +
      'Он тянет нативный биндинг, поэтому не входит в devDependencies.',
  );
  process.exit(1);
}

const buf = fs.readFileSync(file);
const dom = readBinary(new Uint8Array(buf));

const find = (ref, cls) => dom.descendants(ref).find((d) => d.className === cls);
const posOf = (ref) => {
  const d = find(ref, 'Part') ?? find(ref, 'SpawnLocation') ?? dom.instance(ref);
  const cf = d?.properties?.CFrame?.CFrame?.position ?? d?.properties?.CFrame?.position;
  return cf ? cf.map((v) => +v.toFixed(2)) : null;
};
const textsOf = (ref) =>
  [...new Set(dom.descendants(ref).map((d) => d.properties?.Text?.String).filter((s) => s && s.trim()))];

const root = dom.instance(dom.rootRef);
const workspaceRef = root.children.find((r) => dom.instance(r).className === 'Workspace');
if (!workspaceRef) throw new Error('В файле нет Workspace');

const wsChildren = dom.children(workspaceRef).map((r) => dom.instance(r));
const map = {
  source: path.basename(file),
  bytes: buf.length,
  generated: new Date().toISOString().slice(0, 10),
  spawn: null,
  zones: [],
  actors: [],
  cast: [],
  teleports: [],
  fires: [],
  signs: [],
};

for (const inst of wsChildren) {
  const name = (inst.name ?? '').trim();
  if (inst.className === 'SpawnLocation') map.spawn = posOf(inst.referent);

  if (inst.className === 'Model' || inst.className === 'Folder' || inst.className === 'Part') {
    if (name === '2 Player' || name === 'LeaveRoomPart') {
      map.zones.push({ name, class: inst.className, pos: posOf(inst.referent) });
    }
  }

  if (name === 'Teleport One Way' || name === 'Лобби телепорт') {
    const parts = dom
      .children(inst.referent)
      .map((r) => dom.instance(r))
      .filter((i) => i.className === 'Part');
    const spots = parts.map((p) => ({ name: p.name, pos: posOf(p.referent) })).filter((p) => p.pos);
    map.teleports.push({ name, folder: posOf(inst.referent), parts: spots });
  }
}

// Персонажи: модели, внутри которых есть Humanoid.
for (const inst of wsChildren) {
  if (inst.className !== 'Model') continue;
  const hum = find(inst.referent, 'Humanoid');
  if (!hum) continue;
  const parts = dom.descendants(inst.referent).length;
  map.actors.push({ name: (inst.name ?? '').trim(), pos: posOf(inst.referent), parts });
}

// Живые персонажи: каждая модель, в которой есть Humanoid, — это НПС на карте.
// Имя берём у модели-родителя Humanoid'а, позицию — у HumanoidRootPart.
const partPos = (ref) => {
  const cf = dom.instance(ref)?.properties?.CFrame?.CFrame?.position;
  return cf ? cf.map((v) => +v.toFixed(2)) : null;
};
const castSeen = new Map();
for (const inst of dom.descendants(workspaceRef)) {
  if (inst.className !== 'Humanoid') continue;
  const modelRef = dom.instance(inst.referent)?.parent;
  if (!modelRef) continue;
  const model = dom.instance(modelRef);
  if (!model) continue;
  const kids = dom.children(modelRef).map((r) => dom.instance(r));
  const root = kids.find((k) => k.name === 'HumanoidRootPart') ?? kids.find((k) => k.className === 'Part');
  const pos = root ? partPos(root.referent) : null;
  if (!pos) continue;
  const name = (model.name ?? '').trim();
  if (!name || name === 'Room') continue;
  const key = `${name}@${pos.join(',')}`;
  if (castSeen.has(key)) continue;
  castSeen.set(key, { name, pos, health: 100 });
}
map.cast = [...castSeen.values()].sort((a, b) => a.name.localeCompare(b.name, 'ru'));

// Огонь: Part с именем Fire — их ровно 50 и все в одной полосе.
for (const d of dom.descendants(workspaceRef)) {
  if (d.className === 'Part' && d.name === 'Fire') {
    const p = d.properties.CFrame?.CFrame?.position;
    if (p) map.fires.push(p.map((v) => +v.toFixed(2)));
  }
}

// Вывески: Part, внутри которого есть SurfaceGui с TextLabel.
for (const inst of wsChildren) {
  const t = textsOf(inst.referent);
  if (!t.length) continue;
  const p = posOf(inst.referent);
  if (!p) continue;
  map.signs.push({ x: p[0], y: p[1], z: p[2], text: t.join(' / ') });
}
map.signs.sort((a, b) => a.z - b.z || b.x - a.x);

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(map, null, 1), 'utf8');

console.log(`  ${map.source}: ${buf.length} Б`);
console.log(`  спавн: ${JSON.stringify(map.spawn)}`);
console.log(`  зоны: ${map.zones.length}, модели с Humanoid: ${map.actors.length}, живые НПС: ${map.cast.length}, телепорты: ${map.teleports.length}, огни: ${map.fires.length}, вывески: ${map.signs.length}`);
console.log(`  → ${out}`);
