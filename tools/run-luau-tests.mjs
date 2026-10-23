#!/usr/bin/env node
/**
 * run-luau-tests.mjs — прогон tests/engine_spec.luau.
 *
 * Ищет интерпретатор в таком порядке:
 *   1. `luau` в PATH (официальный CLI);
 *   2. пакет @luau-rs/luau (WASM) — если установлен.
 *
 *   node tools/run-luau-tests.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');

const storyData = read('roblox/src/ReplicatedStorage/Shared/StoryData.lua');
const engine = read('roblox/src/ReplicatedStorage/Shared/StoryEngine.lua');
const spec = read('tests/engine_spec.luau');

// Модули Roblox возвращают таблицу через `return` — оборачиваем каждый в функцию.
const wrapped = `-- сгенерировано tools/run-luau-tests.mjs
local StoryData = (function()
${storyData}
end)()

local StoryEngine = (function()
${engine}
end)()

${spec}
`;

const tmpDir = path.join(ROOT, '.tmp');
fs.mkdirSync(tmpDir, { recursive: true });
const tmpFile = path.join(tmpDir, 'engine_spec.generated.luau');
fs.writeFileSync(tmpFile, wrapped, 'utf8');

function runNative() {
	const which = spawnSync('luau', ['--version'], { encoding: 'utf8' });
	if (which.error) return null;
	const result = spawnSync('luau', [tmpFile], { encoding: 'utf8' });
	return result;
}

async function runWasm() {
	try {
		const mod = await import('@luau-rs/luau/worker');
		return mod.LuaWorker ?? null;
	} catch {
		return null;
	}
}

const nativeResult = runNative();
if (nativeResult) {
	process.stdout.write(nativeResult.stdout ?? '');
	process.stderr.write(nativeResult.stderr ?? '');
	process.exit(nativeResult.status ?? 1);
}

const LuaWorker = await runWasm();
if (!LuaWorker) {
	console.error(
		'\n  Не найден интерпретатор Luau.\n' +
			'  Вариант A: установить CLI — https://github.com/luau-lang/luau/releases\n' +
			'  Вариант B: npm i -D @luau-rs/luau\n'
	);
	process.exit(2);
}

const lua = new LuaWorker();
lua.addEventListener('print', (event) => console.log(event.text));
const source = fs.readFileSync(tmpFile, 'utf8');
const result = await lua.execute(source);
if (!result.ok) {
	console.error('Luau error:', result.error?.message ?? result.error);
	process.exit(1);
}
const failures = Number(result.values?.[0] ?? 1);
process.exit(failures > 0 ? 1 : 0);
