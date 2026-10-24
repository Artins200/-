#!/usr/bin/env node
/**
 * test-poses.mjs — прогон tests/pose_spec.luau.
 *
 * Pose.lua трогает только CFrame и части модели, поэтому его можно проверить
 * вне Roblox: tests/roblox_shim.luau подменяет CFrame, Vector3 и Instance.
 * Проверяем главное для игрока — что позы реально двигают модель.
 *
 *   node tools/test-poses.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const read = (p) => fs.readFileSync(path.join(ROOT, p), 'utf8');

const shim = read('tests/roblox_shim.luau');
const pose = read('roblox/src/ReplicatedStorage/Shared/Pose.lua');
const spec = read('tests/pose_spec.luau');

const wrapped = `-- сгенерировано tools/test-poses.mjs
local Shim = (function()
${shim}
return { CFrame = CFrame, Vector3 = Vector3, r6 = r6, r15 = r15 }
end)()

CFrame = Shim.CFrame
Vector3 = Shim.Vector3
local r6, r15 = Shim.r6, Shim.r15

local Pose = (function()
${pose}
end)()

${spec}
`;

const tmpDir = path.join(ROOT, '.tmp');
fs.mkdirSync(tmpDir, { recursive: true });
const tmpFile = path.join(tmpDir, 'pose_spec.generated.luau');
fs.writeFileSync(tmpFile, wrapped, 'utf8');

const native = spawnSync('luau', ['--version'], { encoding: 'utf8' });
if (!native.error) {
	const result = spawnSync('luau', [tmpFile], { encoding: 'utf8' });
	process.stdout.write(result.stdout ?? '');
	process.stderr.write(result.stderr ?? '');
	process.exit(result.status ?? 1);
}

const { LuaWorker } = await import('@luau-rs/luau/worker').catch(() => ({}));
if (!LuaWorker) {
	console.error('Нужен интерпретатор Luau: luau в PATH или npm i -D @luau-rs/luau');
	process.exit(2);
}

// Pose.lua берёт CFrame и Vector3 как глобалы — их выставляет обёртка выше.
const lua = new LuaWorker();
lua.addEventListener('print', (event) => console.log(event.text));
const result = await lua.execute(wrapped);
if (!result.ok) {
	console.error('Luau error:', result.error?.message ?? result.error);
	process.exit(1);
}
const failures = Number(result.values?.[0] ?? 1);
process.exit(failures > 0 ? 1 : 0);
