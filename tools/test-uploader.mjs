#!/usr/bin/env node
/**
 * test-uploader.mjs — тесты uploader/index.html без браузера.
 *
 * Берём код между маркерами /* CORE START *\/ и /* CORE END *\/ прямо из страницы
 * (то есть тестируем ровно то, что выполняется у пользователя) и подставляем
 * в Node: DOMParser берём из @xmldom/xmldom, Blob/Response/DecompressionStream уже есть.
 *
 *   node tools/test-uploader.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { DOMParser } from '@xmldom/xmldom';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const html = fs.readFileSync(path.join(ROOT, 'uploader', 'index.html'), 'utf8');

const startMarker = '/* === CORE START === */';
const endMarker = '/* === CORE END === */';
const start = html.indexOf(startMarker);
const end = html.indexOf(endMarker);
if (start < 0 || end < 0) {
	console.error('Не нашёл маркеры CORE в uploader/index.html');
	process.exit(2);
}

const coreSource = html.slice(start + startMarker.length, end);
const modDir = path.join(ROOT, '.tmp');
fs.mkdirSync(modDir, { recursive: true });
const coreModulePath = path.join(modDir, 'uploader-core.generated.mjs');
fs.writeFileSync(
	coreModulePath,
	[
		"import { DOMParser } from '@xmldom/xmldom';",
		'globalThis.DOMParser = DOMParser;',
		coreSource,
		'export { parseRbxlx, rbxlxToFiles, unzip, makeZip, planFile, sanitizeSegment, ghPutFile, bytesToBase64, crc32 };',
	].join('\n'),
	'utf8',
);
const core = await import(new URL(`file://${coreModulePath}`).href);

let checks = 0;
let failures = 0;
function check(name, condition, detail) {
	checks += 1;
	if (condition) console.log(`  ok   ${name}`);
	else {
		failures += 1;
		console.log(`  FAIL ${name}${detail !== undefined ? ` — ${detail}` : ''}`);
	}
}

const decode = (bytes) => new TextDecoder().decode(bytes);

/* ---------- фикстура .rbxlx ---------- */

const rbxlx = `<?xml version="1.0" encoding="UTF-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">
  <Item class="Workspace" referent="RBX0">
    <Properties>
      <string name="Name">Workspace</string>
    </Properties>
    <Item class="Model" referent="RBX1">
      <Properties>
        <string name="Name">Station &amp; Dome</string>
      </Properties>
      <Item class="ModuleScript" referent="RBX2">
        <Properties>
          <string name="Name">StoryData</string>
          <ProtectedString name="Source"><![CDATA[local Story = {
  title = "Станция «Тишина»",
}
return Story]]></ProtectedString>
        </Properties>
      </Item>
      <Item class="Script" referent="RBX3">
        <Properties>
          <string name="Name">StoryServer</string>
          <ProtectedString name="Source">local x = 1
if x &lt; 2 then
  print("ok")
end</ProtectedString>
        </Properties>
      </Item>
    </Item>
  </Item>
  <Item class="StarterPlayer" referent="RBX4">
    <Properties><string name="Name">StarterPlayer</string></Properties>
    <Item class="LocalScript" referent="RBX5">
      <Properties>
        <string name="Name">VN Client</string>
        <ProtectedString name="Source">print("ui")</ProtectedString>
      </Properties>
    </Item>
  </Item>
</roblox>`;

console.log('— .rbxlx → скрипты');

const parsed = core.parseRbxlx(rbxlx);
check('найдено 3 скрипта', parsed.items.length === 3, parsed.items.length);
check(
	'ModuleScript распознан',
	parsed.items.some((item) => item.className === 'ModuleScript' && item.name === 'StoryData'),
);
check(
	'CDATA-исходник прочитан',
	parsed.items.find((item) => item.name === 'StoryData').source.includes('Станция «Тишина»'),
);
check(
	'XML-экранирование раскрыто',
	parsed.items.find((item) => item.name === 'StoryServer').source.includes('if x < 2 then'),
);
check('LocalScript распознан', parsed.items.some((item) => item.className === 'LocalScript'));

const extracted = core.rbxlxToFiles(rbxlx, {
	baseName: 'Station Place',
	destScripts: 'game/scripts',
	cleanNames: true,
});
const paths = extracted.files.map((file) => file.path);
check('путь с иерархией объектов', paths.includes('game/scripts/Station_Place/Workspace/Station_Dome/StoryData.lua'), paths[0]);
check('серверный скрипт с суффиксом', paths.includes('game/scripts/Station_Place/Workspace/Station_Dome/StoryServer.server.lua'));
check('клиентский скрипт с суффиксом', paths.some((p) => p.endsWith('VN_Client.client.lua')), paths.join(' | '));
check('манифест создан', paths.some((p) => p.endsWith('_manifest.json')));
const manifest = JSON.parse(extracted.files.find((f) => f.path.endsWith('_manifest.json')).text);
check('в манифесте 3 записи', manifest.scripts.length === 3);
check('без пробелов в путях', !paths.some((p) => /\s/.test(p)));

const noClean = core.rbxlxToFiles(rbxlx, { baseName: 'place', destScripts: 's', cleanNames: false });
check('без очистки имя сохраняет пробелы', noClean.files.some((f) => f.path.includes('VN Client.client.lua')));

check('не-XML отклонён', (() => {
	try { core.parseRbxlx('PK\u0003\u0004 not xml'); return false; } catch { return true; }
})());

/* ---------- zip ---------- */

console.log('— zip: запись и чтение');

const zip = core.makeZip([
	{ path: 'a/Story.lua', text: 'return 1' },
	{ path: 'a/данные.json', text: '{"ok":true}' },
	{ path: 'empty.txt', text: '' },
]);
check('zip начинается с PK', zip[0] === 0x50 && zip[1] === 0x4b);
check('записей в zip: 3', (() => {
	const view = new DataView(zip.buffer, zip.byteOffset, zip.byteLength);
	return view.getUint16(zip.length - 12, true) === 3;
})());

const entries = await core.unzip(zip);
check('прочитано 3 записи', entries.length === 3, entries.length);
check('содержимое совпало', decode(entries.find((e) => e.name === 'a/Story.lua').bytes) === 'return 1');
check('юникод в имени и данных', decode(entries.find((e) => e.name === 'a/данные.json').bytes) === '{"ok":true}');
check('пустой файл читается', entries.some((e) => e.name === 'empty.txt' && e.bytes.length === 0));

// zip, собранный системным архиватором (deflate), — проверяем DecompressionStream-путь
const { execFileSync } = await import('node:child_process');
const os = await import('node:os');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'vn-zip-'));
fs.writeFileSync(path.join(tmp, 'place.rbxlx'), rbxlx);
fs.mkdirSync(path.join(tmp, 'scripts'));
fs.writeFileSync(path.join(tmp, 'scripts', 'init.lua'), 'print("hello from zip")\n');
execFileSync('zip', ['-qr', path.join(tmp, 'pack.zip'), 'place.rbxlx', 'scripts'], { cwd: tmp });
const systemZip = new Uint8Array(fs.readFileSync(path.join(tmp, 'pack.zip')));
const systemEntries = await core.unzip(systemZip);
check('системный zip (deflate) распакован', systemEntries.length === 2, systemEntries.length);
check(
	'deflate-содержимое верное',
	decode(systemEntries.find((e) => e.name === 'scripts/init.lua').bytes) === 'print("hello from zip")\n',
);

const zipPlan = await core.planFile(
	{ name: 'pack.zip', bytes: systemZip },
	{ dest: 'game', destScripts: 'game/scripts', extractScripts: true, keepPlace: true, cleanNames: true },
);
const zipPaths = zipPlan.repoFiles.map((f) => f.path);
check('zip сохранён как файл', zipPaths.includes('game/pack.zip'));
check('скрипты из вложенного .rbxlx извлечены', zipPaths.some((p) => p.endsWith('StoryServer.server.lua')), zipPaths.join(' | '));
check('обычный .lua из zip попал в unzipped', zipPaths.some((p) => p.includes('unzipped/scripts/init.lua')));

/* ---------- раскладка прочих файлов ---------- */

console.log('— раскладка файлов');

const plan = await core.planFile(
	{ name: 'My Game.rbxlx', bytes: new TextEncoder().encode(rbxlx) },
	{ dest: 'game', destScripts: 'game/scripts', extractScripts: true, keepPlace: true, cleanNames: true },
);
check('само место сохранено', plan.repoFiles.some((f) => f.path === 'game/My_Game.rbxlx'));
check('и скрипты из него извлечены', plan.repoFiles.some((f) => f.path.endsWith('.server.lua')));

const binary = await core.planFile(
	{ name: 'Place.rbxl', bytes: new Uint8Array([0x3c, 0x72, 0x6f, 0x62, 0x6c, 0x6f, 0x78, 0x21]) },
	{ dest: 'game', destScripts: 'game/scripts', extractScripts: true, keepPlace: true, cleanNames: true },
);
check('бинарный .rbxl сохранён', binary.repoFiles.length === 1 && binary.repoFiles[0].path === 'game/Place.rbxl');
check('и предупреждение о бинарнике', binary.notes.join(' ').includes('бинарный'));

const single = await core.planFile(
	{ name: 'StoryEngine.lua', bytes: new TextEncoder().encode('return {}') },
	{ dest: 'game', destScripts: 'game/scripts', extractScripts: true, keepPlace: true, cleanNames: true },
);
check('одиночный lua идёт в scripts', single.repoFiles[0].path === 'game/scripts/StoryEngine.lua');

const dangerous = core.sanitizeSegment('a/b:c*?"<>|', true);
check('опасные символы заменены', !/[\\/:*?"<>|\s]/.test(dangerous), dangerous);
check('нет двойных подчёркиваний', !dangerous.includes('__'), dangerous);
check('транслит кириллицы', core.sanitizeSegment('Станция «Тишина»', true) === 'Stantsiia_Tishina', core.sanitizeSegment('Станция «Тишина»', true));
check('пробелы в имени места', core.sanitizeSegment('Station & Dome', true) === 'Station_Dome', core.sanitizeSegment('Station & Dome', true));
check('пустое имя не ломает путь', core.sanitizeSegment('   ', true) === 'unnamed');

/* ---------- GitHub ---------- */

console.log('— GitHub API (фейковый fetch)');
const calls = [];
const fakeFetch = async (url, init = {}) => {
	calls.push({ url, method: init.method ?? 'GET', body: init.body });
	if (!init.method || init.method === 'GET') {
		return new Response(JSON.stringify({ sha: 'abc123' }), { status: 200 });
	}
	return new Response(JSON.stringify({ content: { sha: 'def456' } }), { status: 200 });
};

const result = await core.ghPutFile(fakeFetch, {
	owner: 'Artins200',
	repo: '-',
	branch: 'arena/d96d8f09-repo',
	token: 'test-token',
	path: 'game/scripts/Story.lua',
	bytes: new TextEncoder().encode('return 1'),
	message: 'test',
});
check('PUT прошёл', result.content.sha === 'def456');
check('GET sha был запрошен', calls[0].method === 'GET' && calls[0].url.includes('contents/game/scripts/Story.lua'));
const putBody = JSON.parse(calls[1].body);
check('sha подставлен при обновлении', putBody.sha === 'abc123');
check('ветка передана', putBody.branch === 'arena/d96d8f09-repo');
check('content — base64 исходника', Buffer.from(putBody.content, 'base64').toString() === 'return 1');
check('экранирование пути', calls[1].url.includes('game/scripts/Story.lua'));

const notFoundFetch = async (url, init = {}) =>
	init.method === 'PUT'
		? new Response(JSON.stringify({ message: 'Bad credentials' }), { status: 401 })
		: new Response(JSON.stringify({ message: 'Not Found' }), { status: 404 });
let threw = '';
try {
	await core.ghPutFile(notFoundFetch, {
		owner: 'a', repo: 'b', branch: 'main', token: 't', path: 'x.lua',
		bytes: new Uint8Array([1]), message: 'm',
	});
} catch (error) {
	threw = error.message;
}
check('ошибка GitHub пробрасывается', threw.includes('401') && threw.includes('Bad credentials'), threw);

console.log(`\nПроверок: ${checks}, провалено: ${failures}\n`);
process.exit(failures ? 1 : 0);
