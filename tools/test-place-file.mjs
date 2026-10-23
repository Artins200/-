#!/usr/bin/env node
// Проверяет собранный ОДИН файл neirogh.story.rbxl:
// карта на месте, скрипты новеллы внутри и не отстали от roblox/src.
//
//   node tools/test-place-file.mjs
//
// Если rbx-dom не установлен (он необязательный), проверка мягко пропускается:
// сборка и разбор .rbxl требуют нативного модуля.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execFileSync } from 'node:child_process';

const ROOT = path.resolve(import.meta.dirname, '..');
const PLACE = path.join(ROOT, 'neirogh.story.rbxl');
const BUILD = path.join(ROOT, 'tools/build-place.mjs');
const shouldBuild = process.argv.includes('--build');
const MAP = path.join(ROOT, 'neirogh.rbxl');

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

let readBinary;
try {
	({ readBinary } = await import('rbx-dom'));
} catch {
	readBinary = null;
}

// --build пересобирает файл перед проверкой; без rbx-dom сборка невозможна.
if (shouldBuild && readBinary) {
	execFileSync(process.execPath, [BUILD], { stdio: 'ignore' });
}

console.log(`— ${path.basename(PLACE)}`);

check('файл собран', fs.existsSync(PLACE), 'запустите npm run place');
if (!fs.existsSync(PLACE)) {
	console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
	process.exit(1);
}

const bytes = fs.readFileSync(PLACE);
check('это бинарный .rbxl', bytes.subarray(0, 8).toString('latin1') === '<roblox!');
check('в файле есть карта', fs.existsSync(MAP) && bytes.length > fs.statSync(MAP).size / 2);

if (!readBinary) {
	console.log('  skip rbx-dom не установлен — разбор файла пропущен (npm i --no-save rbx-dom)');
	console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
	process.exit(failures.length ? 1 : 0);
}

let dom;
let domOk = true;
try {
	dom = readBinary(bytes);
} catch (err) {
	domOk = false;
	check('файл читается как place', false, String(err.message ?? err));
}
if (!domOk) {
	console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
	process.exit(1);
}
check('файл читается как place', true);
check('корень — DataModel', dom.instance(dom.rootRef).className === 'DataModel');

const mapCount = fs.existsSync(MAP) ? readBinary(fs.readFileSync(MAP)).instanceCount : 0;
check(
	'карта не потеряна',
	dom.instanceCount > mapCount,
	`${dom.instanceCount} инстансов против ${mapCount} в исходной карте`,
);

const shared = walk(dom, ['ReplicatedStorage', 'Shared']);
check('ReplicatedStorage/Shared на месте', Boolean(shared));

const modules = [
	['StoryData', 'ReplicatedStorage/Shared/StoryData.lua'],
	['StoryEngine', 'ReplicatedStorage/Shared/StoryEngine.lua'],
	['Cinema', 'ReplicatedStorage/Shared/Cinema.lua'],
	['TeleportDirector', 'ReplicatedStorage/Shared/TeleportDirector.lua'],
	['WorldKit', 'ReplicatedStorage/Shared/WorldKit.lua'],
];
for (const [name, rel] of modules) {
	const ref = shared ? childByName(dom, shared, name) : null;
	const view = ref ? dom.instance(ref) : null;
	check(`${name} — ModuleScript`, view?.className === 'ModuleScript');
	const inside = view?.properties?.Source?.String ?? '';
	check(`${name} не отстал от roblox/src`, inside === source(rel), 'пересоберите: npm run place');
}

const server = walk(dom, ['ServerScriptService', 'StoryServer']);
check('ServerScriptService/StoryServer — Script', dom.instance(server)?.className === 'Script');
check(
	'серверный скрипт не отстал от roblox/src',
	(dom.instance(server)?.properties?.Source?.String ?? '') === source('ServerScriptService/StoryServer.server.lua'),
);

const client = walk(dom, ['StarterPlayer', 'StarterPlayerScripts', 'StoryClient']);
check('StarterPlayerScripts/StoryClient — LocalScript', dom.instance(client)?.className === 'LocalScript');
check(
	'клиентский скрипт не отстал от roblox/src',
	(dom.instance(client)?.properties?.Source?.String ?? '') === source('StarterPlayer/StarterPlayerScripts/StoryClient.client.lua'),
);

const storyInside = dom.instance(shared ? childByName(dom, shared, 'StoryData') : '')?.properties?.Source?.String ?? '';
check('сюжет внутри StoryData', storyInside.includes('fusion_last'));
check('финальная глава внутри StoryData', storyInside.includes('Жестокий сплав огня и ревности'));
check('телепорт ведёт на арену', storyInside.includes('-201.6'));
check('координаты мира внутри StoryData', storyInside.includes('StoryData.world'));
check('живые НПС внутри StoryData', storyInside.includes('cast'));
check('маршрут по актам внутри StoryData', storyInside.includes('StoryData.order'));

let parts = 0;
let fires = 0;
let spawns = 0;
const names = new Set();
for (const inst of dom.descendants()) {
	if (['Part', 'MeshPart', 'UnionOperation'].includes(inst.className)) parts++;
	if (inst.className === 'Fire' || inst.name === 'Fire') fires++;
	if (inst.className === 'SpawnLocation') spawns++;
	if (inst.className === 'Script' || inst.className === 'LocalScript') names.add(`${inst.className}:${inst.name}`);
}
check('геометрия карты на месте', parts > 5000, `${parts} частей`);
check('очаги огня на месте', fires >= 40, `${fires} огней`);
check('точка появления на месте', spawns >= 1);
check('один StoryServer, без дублей', [...names].filter((n) => n.endsWith(':StoryServer')).length === 1);

console.log(`\nПроверок: ${passed}, провалено: ${failures.length}`);
if (failures.length) {
	for (const f of failures) console.error(`  · ${f}`);
	process.exit(1);
}
