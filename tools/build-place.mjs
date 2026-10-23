#!/usr/bin/env node
// Собирает ОДИН .rbxl: карта из neirogh.rbxl + скрипты новеллы из roblox/src.
//
//   node tools/build-place.mjs            → neirogh.story.rbxl
//   node tools/build-place.mjs --out x.rbxl
//
// Скрипты кладутся туда же, куда их положил бы Rojo:
//   ReplicatedStorage/Shared/{StoryData,StoryEngine,Cinema,TeleportDirector,WorldKit}
//   ServerScriptService/StoryServer
//   StarterPlayer/StarterPlayerScripts/StoryClient
//
// Повторный запуск не плодит дубликаты: одноимённые узлы удаляются перед вставкой.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = path.resolve(import.meta.dirname, '..');
const SOURCE = path.join(ROOT, 'neirogh.rbxl');

const args = process.argv.slice(2);
const outArg = args.indexOf('--out');
const OUT = outArg >= 0 ? args[outArg + 1] : path.join(ROOT, 'neirogh.story.rbxl');

const MODULES = [
	['StoryData', 'ReplicatedStorage/Shared/StoryData.lua'],
	['StoryEngine', 'ReplicatedStorage/Shared/StoryEngine.lua'],
	['Cinema', 'ReplicatedStorage/Shared/Cinema.lua'],
	['TeleportDirector', 'ReplicatedStorage/Shared/TeleportDirector.lua'],
	['WorldKit', 'ReplicatedStorage/Shared/WorldKit.lua'],
];
const SERVER_SCRIPT = ['StoryServer', 'ServerScriptService/StoryServer.server.lua'];
const CLIENT_SCRIPT = ['StoryClient', 'StarterPlayer/StarterPlayerScripts/StoryClient.client.lua'];

function fail(message) {
	console.error(`\n✗ ${message}`);
	process.exit(1);
}

/** Читает исходник скрипта и падает, если файла нет или он пустой. */
function readSource(rel) {
	const file = path.join(ROOT, 'roblox/src', rel);
	if (!fs.existsSync(file)) fail(`нет файла ${rel}`);
	const text = fs.readFileSync(file, 'utf8');
	if (!text.trim()) fail(`пустой скрипт ${rel}`);
	return text;
}

/** Ищет ребёнка по имени среди детей узла; возвращает referent или null. */
function childByName(dom, parentRef, name) {
	for (const ref of dom.children(parentRef)) {
		if (dom.instance(ref).name === name) return ref;
	}
	return null;
}

/** Убирает старую копию узла, чтобы сборка была идемпотентной. */
function dropOld(dom, parentRef, name) {
	const old = childByName(dom, parentRef, name);
	if (old) dom.destroy(old);
	return Boolean(old);
}

/** Вставляет скрипт с исходником; возвращает referent. */
function insertScript(dom, parentRef, className, name, source) {
	return dom.insert(parentRef, {
		className,
		name,
		properties: { Source: { String: source } },
	});
}

const { readBinary } = await import('rbx-dom').catch(() => {
	fail('не найден rbx-dom. Установите: npm i --no-save rbx-dom');
});

if (!fs.existsSync(SOURCE)) fail(`нет исходной карты ${path.relative(ROOT, SOURCE)}`);

const t0 = Date.now();
const dom = readBinary(fs.readFileSync(SOURCE));
const before = dom.instanceCount;

const rootRef = dom.rootRef;
const serviceByName = new Map(
	dom.children(rootRef).map((ref) => [dom.instance(ref).name, ref]),
);

const replicated = serviceByName.get('ReplicatedStorage');
const serverScripts = serviceByName.get('ServerScriptService');
const starterPlayer = serviceByName.get('StarterPlayer');
const workspace = serviceByName.get('Workspace');
if (!replicated || !serverScripts || !starterPlayer) {
	fail('в карте нет ReplicatedStorage / ServerScriptService / StarterPlayer');
}

// ReplicatedStorage/Shared
let sharedRef = childByName(dom, replicated, 'Shared');
const createdShared = !sharedRef;
if (!sharedRef) {
	sharedRef = dom.insert(replicated, { className: 'Folder', name: 'Shared' });
}

const placed = [];
for (const [name, rel] of MODULES) {
	dropOld(dom, sharedRef, name);
	const ref = insertScript(dom, sharedRef, 'ModuleScript', name, readSource(rel));
	placed.push({ name, rel, className: 'ModuleScript', ref, at: ['ReplicatedStorage', 'Shared', name] });
}

// ServerScriptService/StoryServer
dropOld(dom, serverScripts, SERVER_SCRIPT[0]);
placed.push({
	name: SERVER_SCRIPT[0],
	rel: SERVER_SCRIPT[1],
	className: 'Script',
	ref: insertScript(dom, serverScripts, 'Script', SERVER_SCRIPT[0], readSource(SERVER_SCRIPT[1])),
	at: ['ServerScriptService', SERVER_SCRIPT[0]],
});

// StarterPlayer/StarterPlayerScripts/StoryClient
let playerScripts = childByName(dom, starterPlayer, 'StarterPlayerScripts');
if (!playerScripts) {
	playerScripts = dom.insert(starterPlayer, { className: 'StarterPlayerScripts', name: 'StarterPlayerScripts' });
}
dropOld(dom, playerScripts, CLIENT_SCRIPT[0]);
placed.push({
	name: CLIENT_SCRIPT[0],
	rel: CLIENT_SCRIPT[1],
	className: 'LocalScript',
	ref: insertScript(dom, playerScripts, 'LocalScript', CLIENT_SCRIPT[0], readSource(CLIENT_SCRIPT[1])),
	at: ['StarterPlayer', 'StarterPlayerScripts', CLIENT_SCRIPT[0]],
});

// Телепорт финала должен вести в реально существующую точку карты.
const story = JSON.parse(fs.readFileSync(path.join(ROOT, 'story/story.json'), 'utf8'));
const teleportScene = Object.values(story.nodes).find((node) => node.teleport);
if (!teleportScene) fail('в сюжете нет сцены с телепортом');
const target = teleportScene.teleport.target;
if (!Array.isArray(target) || target.length !== 3) fail('у телепорта нет координат target');

const bytes = dom.toBinary({ compression: 'zstd' });
fs.writeFileSync(OUT, bytes);

// ── проверка записанного файла ───────────────────────────────────────────────
const check = readBinary(fs.readFileSync(OUT));
/** Идёт по именам от корня и возвращает referent (или null). */
function walk(dom2, names) {
	let ref = dom2.rootRef;
	for (const name of names) {
		ref = childByName(dom2, ref, name);
		if (!ref) return null;
	}
	return ref;
}

const missing = [];
for (const item of placed) {
	const ref = walk(check, item.at);
	const view = ref ? check.instance(ref) : null;
	if (!view) missing.push(`${item.name} (нет узла)`);
	else if (view.className !== item.className) missing.push(`${item.name} (${view.className})`);
	else if (view.properties.Source?.String !== readSource(item.rel)) {
		missing.push(`${item.name} (исходник не совпал)`);
	}
}
if (missing.length) fail(`после записи не сошлось: ${missing.join(', ')}`);

const spawn = story.meta?.map?.spawn;
console.log('Собрано в один .rbxl');
console.log(`  файл:        ${path.relative(ROOT, OUT)}`);
console.log(`  размер:      ${(bytes.length / 1024).toFixed(0)} КБ (было ${(fs.statSync(SOURCE).size / 1024).toFixed(0)} КБ)`);
console.log(`  инстансов:   ${before} → ${check.instanceCount}`);
console.log(`  скриптов:    ${placed.length} (${placed.map((p) => p.name).join(', ')})`);
console.log(`  Services:    ReplicatedStorage${createdShared ? ' (+Shared)' : '/Shared'}, ServerScriptService, StarterPlayerScripts`);
console.log(`  телепорт:    ${teleportScene.teleport.id} → [${target.join(', ')}] · ${teleportScene.teleport.placeId}`);
if (spawn) console.log(`  спавн:       [${spawn.join(', ')}]`);
console.log(`  время:       ${Date.now() - t0} мс`);
