#!/usr/bin/env node
// Проверяет собранный ОДИН файл neirogh.story.rbxl и раскладку game/world.json:
// крыло из комнат на месте, персонажи скопированы, вывески с текстом, порталы
// ведут дальше, интерфейса нет, скрипты не отстали от roblox/src.
//
//   node tools/test-place-file.mjs           проверка
//   node tools/test-place-file.mjs --build   пересобрать и проверить
//
// Без rbx-dom (необязательный нативный модуль) проверка .rbxl мягко пропускается.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execFileSync } from 'node:child_process';

const ROOT = path.resolve(import.meta.dirname, '..');
const PLACE = path.join(ROOT, 'neirogh.story.rbxl');
const MAP = path.join(ROOT, 'neirogh.rbxl');
const WORLD = path.join(ROOT, 'game/world.json');
const BUILD = path.join(ROOT, 'tools/build-place.mjs');
const shouldBuild = process.argv.includes('--build');

let passed = 0;
const failures = [];

function check(name, ok, detail = '') {
	if (ok) {
		passed++;
		console.log(`  ok   ${name}`);
	} else {
		failures.push(detail ? `${name} — ${detail}` : name);
		console.log(`  FAIL ${name}${detail ? ` — ${detail}` : ''}`);
	}
}

function source(rel) {
	const file = path.join(ROOT, 'roblox/src', rel);
	return fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
}

function childByName(dom, parentRef, name) {
	for (const ref of dom.children(parentRef)) {
		if (dom.instance(ref).name === name) return ref;
	}
	return null;
}

function walk(dom, names) {
	let ref = dom.rootRef;
	for (const name of names) {
		ref = childByName(dom, ref, name);
		if (!ref) return null;
	}
	return ref;
}

const distance = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);

let readBinary;
try {
	({ readBinary } = await import('rbx-dom'));
} catch {
	readBinary = null;
}

if (shouldBuild && readBinary) {
	execFileSync(process.execPath, [BUILD], { stdio: 'ignore' });
}

// ── 1. Раскладка (game/world.json) ──────────────────────────────────────────
console.log('— раскладка крыла (game/world.json)');
check('world.json собран', fs.existsSync(WORLD), 'запустите npm run place');
const world = fs.existsSync(WORLD) ? JSON.parse(fs.readFileSync(WORLD, 'utf8')) : null;
const scenes = world?.scenes ?? [];
const portals = world?.portals ?? [];

check('сцен в крыле столько же, сколько в сюжете', scenes.length === 95, `${scenes.length}`);
check('у каждой сцены есть комната', scenes.every((s) => s.room === `Scene_${s.id}`));
check('у каждой сцены есть персонаж и вывеска', scenes.every((s) => s.character && s.sign?.length === 3));
check('координаты сцен конечные', scenes.every((s) => s.sign.every((v) => Number.isFinite(v))));
check('комнаты не наезжают друг на друга', (() => {
	const step = world?.base?.step ?? 0;
	return step > (world?.base?.roomWidth ?? 0);
})(), `шаг ${world?.base?.step}, ширина ${world?.base?.roomWidth}`);

check('порталов столько же, сколько сцен', portals.length === scenes.length, `${portals.length}`);
check('каждый портал ведёт в следующую комнату', portals.slice(0, -1).every((p, i) =>
	distance(p.to, scenes[i + 1].arrival) < 1, ));
check('последний портал — после финальной главы', portals.at(-1)?.next === null && portals.at(-1)?.id === 'Portal_Final');
check('последний портал ведёт в следующую локацию', (() => {
	const target = world?.nextLocation;
	const fire = [  -201.6, 6.1 ];
	if (!target) return false;
	return Math.abs(target[0] - fire[0]) < 1 && Math.abs(target[2] - fire[1]) < 1;
})(), JSON.stringify(world?.nextLocation));

const characters = new Set(scenes.map((s) => s.character));
check('в комнатах больше пяти разных моделей', characters.size > 5, [...characters].join(', '));
check('есть копии главных героев', ['Артём', 'Демид', 'Ваня'].every((n) => characters.has(n)), [...characters].join(', '));

// ── 2. Собранный .rbxl ──────────────────────────────────────────────────────
console.log(`— ${path.basename(PLACE)}`);
check('файл собран', fs.existsSync(PLACE), 'запустите npm run place');
if (!fs.existsSync(PLACE)) {
	console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
	process.exit(1);
}
const bytes = fs.readFileSync(PLACE);
check('это бинарный .rbxl', bytes.subarray(0, 8).toString('latin1') === '<roblox!');

if (!readBinary) {
	console.log('  skip rbx-dom не установлен — разбор файла пропущен (npm i --no-save rbx-dom)');
	console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
	process.exit(failures.length ? 1 : 0);
}

let dom;
try {
	dom = readBinary(bytes);
	check('файл читается как place', true);
} catch (err) {
	check('файл читается как place', false, String(err.message ?? err));
	console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
	process.exit(1);
}

check('корень — DataModel', dom.instance(dom.rootRef).className === 'DataModel');

// карта не потеряна
if (fs.existsSync(MAP)) {
	const mapCount = readBinary(fs.readFileSync(MAP)).instanceCount;
	check('карта не потеряна', dom.instanceCount > mapCount, `${dom.instanceCount} против ${mapCount}`);
}

// крыло
const wing = walk(dom, ['Workspace', 'StoryWing']);
check('Workspace.StoryWing на месте', Boolean(wing));
let rooms = 0;
let signs = 0;
let npcs = 0;
let emptySigns = 0;
let portalsInFile = 0;
if (wing) {
	for (const ref of dom.children(wing)) {
		const inst = dom.instance(ref);
		if (inst.className === 'Model' && inst.name.startsWith('Scene_')) {
			rooms++;
			const sign = childByName(dom, ref, 'Sign');
			if (sign) signs++;
			const gui = sign && dom.children(sign).map((r) => dom.instance(r)).find((c) => c.className === 'SurfaceGui');
			const label = gui && dom.descendants(gui.referent).find((d) => d.className === 'TextLabel');
			const text = label?.properties?.Text?.String ?? '';
			if (!text.trim()) emptySigns++;
			for (const child of dom.children(ref)) {
				const c = dom.instance(child);
				if (c.className === 'Model' && dom.descendants(child).some((d) => d.className === 'Humanoid')) npcs++;
			}
		}
		if (inst.className === 'Folder' && inst.name.startsWith('Portal_')) portalsInFile++;
	}
}
check('комнат столько же, сколько сцен', rooms === scenes.length, `${rooms}`);
check('в каждой комнате вывеска', signs === scenes.length, `${signs}`);
check('на каждой вывеске есть текст', emptySigns === 0, `${emptySigns} пустых`);
check('в каждой комнате стоит персонаж', npcs === scenes.length, `${npcs}`);
check('порталов столько же, сколько сцен', portalsInFile === scenes.length, `${portalsInFile}`);

// порталы — папки «Teleport One Way» с площадками и скриптом, как в плейсе
const firstPortal = wing && dom.children(wing).map((r) => dom.instance(r)).find((i) => i.name === 'Portal_start');
if (firstPortal) {
	const kids = dom.children(firstPortal.referent).map((r) => dom.instance(r));
	check('портал — папка из плейса', kids.some((k) => k.name === 'TeleportPart1') && kids.some((k) => k.name === 'TeleportPart2'));
	check('у портала работает скрипт из плейса', kids.some((k) => k.className === 'Script' && k.name === 'Ignore'));
	const script = kids.find((k) => k.className === 'Script');
	check('скрипт портала телепортирует', (script?.properties?.Source?.String ?? '').includes('TeleportPart2'));
} else {
	check('портал сцены start найден', false);
}

// скрипты
const shared = walk(dom, ['ReplicatedStorage', 'Shared']);
for (const [name, rel] of [
	['StoryData', 'ReplicatedStorage/Shared/StoryData.lua'],
	['StoryEngine', 'ReplicatedStorage/Shared/StoryEngine.lua'],
]) {
	const ref = shared ? childByName(dom, shared, name) : null;
	const view = ref ? dom.instance(ref) : null;
	check(`${name} — ModuleScript`, view?.className === 'ModuleScript');
	check(`${name} не отстал от roblox/src`, (view?.properties?.Source?.String ?? '') === source(rel), 'пересоберите: npm run place');
}

const server = walk(dom, ['ServerScriptService', 'StoryWorld']);
check('ServerScriptService/StoryWorld — Script', dom.instance(server)?.className === 'Script');
check(
	'серверный скрипт не отстал от roblox/src',
	(dom.instance(server)?.properties?.Source?.String ?? '') === source('ServerScriptService/StoryWorld.server.lua'),
);

// интерфейса не добавили
let guiCount = 0;
let localScripts = 0;
for (const inst of dom.descendants()) {
	if (['ScreenGui', 'BillboardGui'].includes(inst.className)) guiCount++;
	if (inst.className === 'LocalScript' && /^Story/.test(inst.name)) localScripts++;
}
let mapGui = 0;
if (fs.existsSync(MAP)) {
	const mapDom = readBinary(fs.readFileSync(MAP));
	for (const inst of mapDom.descendants()) {
		if (['ScreenGui', 'BillboardGui'].includes(inst.className)) mapGui++;
	}
}
check('своих экранов и табличек над головой нет', guiCount === mapGui, `в файле ${guiCount}, в карте ${mapGui}`);
check('клиентских скриптов новеллы нет', localScripts === 0, `${localScripts}`);

// сюжет внутри
const storyInside = dom.instance(shared ? childByName(dom, shared, 'StoryData') : '')?.properties?.Source?.String ?? '';
check('сюжет внутри StoryData', storyInside.includes('Четыре месяца станция'));
check('финальная глава внутри StoryData', storyInside.includes('Жестокий сплав огня и ревности'));
check('порядок сцен внутри StoryData', storyInside.includes('StoryData.order'));

console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
if (failures.length) {
	for (const f of failures) console.error(`  · ${f}`);
	process.exit(1);
}
