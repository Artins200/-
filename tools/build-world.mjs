#!/usr/bin/env node
// build-world.mjs — карта + крыло сюжета: комнаты, персонажи, вывески, порталы.
//
//   node tools/build-world.mjs                  → neirogh.world.rbxl + game/world.json
//   node tools/build-world.mjs --out x.rbxl
//
// Крыло собирается из настоящих моделей плейса (Room, вывеска с SurfaceGui,
// папка "Teleport One Way") — ничего своего не рисуем.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { buildWing } from './world-builder.mjs';

const ROOT = path.resolve(import.meta.dirname, '..');
const SOURCE = path.join(ROOT, 'neirogh.rbxl');
const STORY = path.join(ROOT, 'story/story.json');
const OUT_JSON = path.join(ROOT, 'game/world.json');

const args = process.argv.slice(2);
const outArg = args.indexOf('--out');
const OUT = outArg >= 0 ? args[outArg + 1] : path.join(ROOT, 'neirogh.world.rbxl');

let readBinary;
try {
	({ readBinary } = await import('rbx-dom'));
} catch {
	console.error('  ✗ нужен rbx-dom: npm i --no-save rbx-dom');
	process.exit(1);
}

if (!fs.existsSync(SOURCE)) {
	console.error(`  ✗ нет исходной карты ${path.relative(ROOT, SOURCE)}`);
	process.exit(1);
}

const story = JSON.parse(fs.readFileSync(STORY, 'utf8'));
const t0 = Date.now();

const dom = readBinary(fs.readFileSync(SOURCE));
const before = dom.instanceCount;

// Повторная сборка не должна плодить крылья.
const wsRef = dom.children(dom.rootRef).map((r) => dom.instance(r)).find((i) => i.className === 'Workspace').referent;
for (const ref of dom.children(wsRef)) {
	const inst = dom.instance(ref);
	if (inst.className === 'Folder' && inst.name === 'StoryWing') dom.destroy(ref);
}

const wing = buildWing(dom, story);
const bytes = dom.toBinary({ compression: 'zstd' });
fs.writeFileSync(OUT, bytes);

const world = {
	source: path.basename(SOURCE),
	out: path.basename(OUT),
	generated: new Date().toISOString().slice(0, 10),
	wing: wing.folderName,
	base: wing.base,
	floor: wing.floor,
	nextLocation: wing.nextLocation,
	scenes: wing.scenes,
	portals: wing.portals,
};

fs.mkdirSync(path.dirname(OUT_JSON), { recursive: true });
fs.writeFileSync(OUT_JSON, JSON.stringify(world, null, 1), 'utf8');

const acts = {};
for (const scene of wing.scenes) acts[scene.act] = (acts[scene.act] ?? 0) + 1;

console.log('Крыло сюжета собрано из моделей плейса');
console.log(`  комнат-сцен:  ${wing.scenes.length} (${Object.entries(acts).map(([a, n]) => `акт ${a}: ${n}`).join(', ')})`);
console.log(`  персонажей:   ${wing.scenes.filter((s) => s.character).length} копий, образцов на карте: ${wing.characterCount}`);
console.log(`  порталов:     ${wing.portals.length} (последний — в следующую локацию ${JSON.stringify(wing.nextLocation)})`);
console.log(`  вывесок:      ${wing.scenes.length}`);
console.log(`  инстансов:    ${before} → ${dom.instanceCount}`);
console.log(`  файл:         ${path.relative(ROOT, OUT)} (${(bytes.length / 1024 / 1024).toFixed(2)} МБ)`);
console.log(`  раскладка:    ${path.relative(ROOT, OUT_JSON)}`);
console.log(`  время:        ${Date.now() - t0} мс`);
