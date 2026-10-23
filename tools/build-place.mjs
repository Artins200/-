#!/usr/bin/env node
// Собирает ОДИН .rbxl: карта neirogh.rbxl + крыло сюжета + серверный скрипт.
//
//   node tools/build-place.mjs            → neirogh.story.rbxl
//   node tools/build-place.mjs --out x.rbxl
//
// Что внутри:
//   Workspace.StoryWing      95 комнат (копии модели Room) с персонажами и вывесками,
//                            между комнатами — порталы «Teleport One Way» из этого плейса;
//   ReplicatedStorage/Shared StoryData, StoryEngine;
//   ServerScriptService      StoryWorld — единственный скрипт, ни одного ScreenGui.
//
// Повторный запуск не плодит дубликаты: старое крыло и скрипты удаляются.

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
const OUT = outArg >= 0 ? args[outArg + 1] : path.join(ROOT, 'neirogh.story.rbxl');

const MODULES = [
	['StoryData', 'ReplicatedStorage/Shared/StoryData.lua'],
	['StoryEngine', 'ReplicatedStorage/Shared/StoryEngine.lua'],
];
const SERVER_SCRIPT = ['StoryWorld', 'ServerScriptService/StoryWorld.server.lua'];

function fail(message) {
	console.error(`\n✗ ${message}`);
	process.exit(1);
}

function readSource(rel) {
	const file = path.join(ROOT, 'roblox/src', rel);
	if (!fs.existsSync(file)) fail(`нет файла ${rel}`);
	const text = fs.readFileSync(file, 'utf8');
	if (!text.trim()) fail(`пустой скрипт ${rel}`);
	return text;
}

function childByName(dom, parentRef, name) {
	for (const ref of dom.children(parentRef)) {
		if (dom.instance(ref).name === name) return ref;
	}
	return null;
}

function dropOld(dom, parentRef, name) {
	const old = childByName(dom, parentRef, name);
	if (old) dom.destroy(old);
}

function insertScript(dom, parentRef, className, name, source) {
	return dom.insert(parentRef, { className, name, properties: { Source: { String: source } } });
}

function walk(dom, names) {
	let ref = dom.rootRef;
	for (const name of names) {
		ref = childByName(dom, ref, name);
		if (!ref) return null;
	}
	return ref;
}

const { readBinary } = await import('rbx-dom').catch(() => {
	fail('не найден rbx-dom. Установите: npm i --no-save rbx-dom');
});

if (!fs.existsSync(SOURCE)) fail(`нет исходной карты ${path.relative(ROOT, SOURCE)}`);

const story = JSON.parse(fs.readFileSync(STORY, 'utf8'));
const t0 = Date.now();
const dom = readBinary(fs.readFileSync(SOURCE));
const before = dom.instanceCount;

const services = new Map(dom.children(dom.rootRef).map((ref) => [dom.instance(ref).name, ref]));
const replicated = services.get('ReplicatedStorage');
const serverScripts = services.get('ServerScriptService');
const workspace = services.get('Workspace');
if (!replicated || !serverScripts || !workspace) {
	fail('в карте нет ReplicatedStorage / ServerScriptService / Workspace');
}

// ── крыло сюжета ────────────────────────────────────────────────────────────
for (const ref of dom.children(workspace)) {
	const inst = dom.instance(ref);
	if (inst.className === 'Folder' && inst.name === 'StoryWing') dom.destroy(ref);
}
const wing = buildWing(dom, story);

// ── скрипты ─────────────────────────────────────────────────────────────────
let sharedRef = childByName(dom, replicated, 'Shared');
if (!sharedRef) sharedRef = dom.insert(replicated, { className: 'Folder', name: 'Shared' });

const placed = [];
for (const [name, rel] of MODULES) {
	dropOld(dom, sharedRef, name);
	placed.push({
		name,
		rel,
		className: 'ModuleScript',
		at: ['ReplicatedStorage', 'Shared', name],
		ref: insertScript(dom, sharedRef, 'ModuleScript', name, readSource(rel)),
	});
}

dropOld(dom, serverScripts, SERVER_SCRIPT[0]);
placed.push({
	name: SERVER_SCRIPT[0],
	rel: SERVER_SCRIPT[1],
	className: 'Script',
	at: ['ServerScriptService', SERVER_SCRIPT[0]],
	ref: insertScript(dom, serverScripts, 'Script', SERVER_SCRIPT[0], readSource(SERVER_SCRIPT[1])),
});

// Старого клиента с интерфейсом быть не должно.
const starterPlayer = services.get('StarterPlayer');
if (starterPlayer) {
	const playerScripts = childByName(dom, starterPlayer, 'StarterPlayerScripts');
	if (playerScripts) {
		for (const name of ['StoryClient', 'StoryHud']) dropOld(dom, playerScripts, name);
	}
}

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

// ── проверка записанного файла ──────────────────────────────────────────────
const check = readBinary(fs.readFileSync(OUT));
const problems = [];

for (const item of placed) {
	const ref = walk(check, item.at);
	const view = ref ? check.instance(ref) : null;
	if (!view) problems.push(`${item.name}: нет узла`);
	else if (view.className !== item.className) problems.push(`${item.name}: ${view.className}`);
	else if (view.properties.Source?.String !== readSource(item.rel)) problems.push(`${item.name}: исходник не совпал`);
}

const wingRef = walk(check, ['Workspace', 'StoryWing']);
if (!wingRef) problems.push('нет Workspace.StoryWing');
else {
	let rooms = 0;
	let signs = 0;
	let portals = 0;
	for (const ref of check.children(wingRef)) {
		const inst = check.instance(ref);
		if (inst.className === 'Model' && inst.name.startsWith('Scene_')) {
			rooms++;
			if (childByName(check, ref, 'Sign')) signs++;
		}
		if (inst.className === 'Folder' && inst.name.startsWith('Portal_')) portals++;
	}
	if (rooms !== wing.scenes.length) problems.push(`комнат ${rooms}, ожидалось ${wing.scenes.length}`);
	if (signs !== wing.scenes.length) problems.push(`вывесок ${signs}`);
	if (portals !== wing.portals.length) problems.push(`порталов ${portals}`);
}

// Интерфейса мы не добавляем: сколько ScreenGui/BillboardGui было в исходной
// карте, столько и должно остаться (свои вывески — это SurfaceGui на частях).
const countGui = (source) => {
	let n = 0;
	for (const inst of source.descendants()) {
		if (['ScreenGui', 'BillboardGui', 'PlayerGui'].includes(inst.className)) n++;
	}
	return n;
};
const mapGui = countGui(readBinary(fs.readFileSync(SOURCE)));
const fileGui = countGui(check);
if (fileGui !== mapGui) problems.push(`появился интерфейс: было ${mapGui}, стало ${fileGui}`);

let localScripts = 0;
for (const inst of check.descendants()) {
	if (inst.className === 'LocalScript' && inst.name.startsWith('Story')) localScripts++;
}
if (localScripts) problems.push(`остались клиентские скрипты: ${localScripts}`);

if (problems.length) fail(`после записи не сошлось:\n  · ${problems.join('\n  · ')}`);

const acts = {};
for (const scene of wing.scenes) acts[scene.act] = (acts[scene.act] ?? 0) + 1;
console.log('Собрано в один .rbxl — без единого элемента интерфейса');
console.log(`  файл:        ${path.relative(ROOT, OUT)} (${(bytes.length / 1024 / 1024).toFixed(2)} МБ, было ${(fs.statSync(SOURCE).size / 1024 / 1024).toFixed(2)} МБ)`);
console.log(`  комнат:      ${wing.scenes.length} (${Object.entries(acts).map(([a, n]) => `акт ${a}: ${n}`).join(', ')})`);
console.log(`  персонажей:  ${wing.scenes.length} копий с карты`);
console.log(`  порталов:    ${wing.portals.length}, последний → ${JSON.stringify(wing.nextLocation)}`);
console.log(`  вывесок:     ${wing.scenes.length} (SurfaceGui на части, как на карте)`);
console.log(`  скриптов:    ${placed.length} (${placed.map((p) => p.name).join(', ')}) — ни одного LocalScript`);
console.log(`  интерфейс:   ${fileGui} объекта(ов) из исходной карты, своих нет`);
console.log(`  инстансов:   ${before} → ${check.instanceCount}`);
console.log(`  раскладка:   ${path.relative(ROOT, OUT_JSON)}`);
console.log(`  время:       ${Date.now() - t0} мс`);
