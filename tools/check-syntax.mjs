#!/usr/bin/env node
/**
 * check-syntax.mjs — синтаксическая проверка всех .lua/.luau в roblox/ и tests/.
 *
 * Скрипты для Roblox нельзя выполнить вне движка (game, Instance, task…),
 * поэтому берём анализатор Luau в режиме nocheck: остаются только ошибки
 * разбора, а глобалы Roblox объявлены, чтобы не было ложных «Unknown global».
 *
 *   node tools/check-syntax.mjs
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);

let Analysis
try {
	({ Analysis } = await import('@luau-rs/luau/analysis'));
} catch {
	console.error('Нужен пакет @luau-rs/luau: npm i -D @luau-rs/luau');
	process.exit(2);
}

// Глобалы Roblox + стандартная библиотека: нужны только для парсера.
const ROBLOX_GLOBALS = [
	'game', 'workspace', 'script', 'plugin', 'shared', 'Instance', 'Enum', 'typeof', 'task',
	'Color3', 'ColorSequence', 'ColorSequenceKeypoint', 'NumberSequence', 'NumberSequenceKeypoint',
	'NumberRange', 'UDim', 'UDim2', 'Vector2', 'Vector3', 'CFrame', 'Ray', 'Rect', 'Region3',
	'BrickColor', 'TweenInfo', 'Faces', 'PhysicalProperties', 'Random', 'DateTime', 'TimeOfDay',
	'require', 'wait', 'delay', 'spawn', 'tick', 'time', 'warn', 'print', 'settings',
	'Players', 'ReplicatedStorage', 'ReplicatedFirst', 'ServerScriptService', 'ServerStorage',
	'StarterGui', 'StarterPlayer', 'StarterPack', 'RunService', 'TweenService', 'UserInputService',
	'HttpService', 'DataStoreService', 'CollectionService', 'SoundService', 'Lighting', 'MarketplaceService',
	// подставляются раннером тестов перед запуском tests/engine_spec.luau
	'StoryData', 'StoryEngine', 'Cinema', 'TeleportDirector', 'WorldKit',
];

const analysis = await Analysis.create({ mode: 'nocheck', lint: false, globals: ROBLOX_GLOBALS });

function walk(dir, out = []) {
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			if (['node_modules', '.git', '.tmp'].includes(entry.name)) continue;
			walk(full, out);
		} else if (/\.(lua|luau)$/.test(entry.name)) {
			out.push(full);
		}
	}
	return out;
}

const files = [...walk(path.join(ROOT, 'roblox')), ...walk(path.join(ROOT, 'tests'))].sort();
let failed = 0;

for (const file of files) {
	const rel = path.relative(ROOT, file);
	const source = fs.readFileSync(file, 'utf8');
	const name = rel.replaceAll(path.sep, '/');

	analysis.setModule(name, source, 'script');
	const { diagnostics } = analysis.check(name);

	if (!diagnostics.length) {
		console.log(`  ok   ${rel}`);
		continue;
	}

	failed += 1;
	console.log(`  FAIL ${rel}`);
	for (const d of diagnostics) {
		console.log(`       ${d.location.begin.line}:${d.location.begin.column}  ${d.message}`);
	}
}

console.log(`\nПроверено файлов: ${files.length}, с ошибками: ${failed}\n`);
process.exit(failed ? 1 : 0);
