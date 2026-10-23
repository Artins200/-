#!/usr/bin/env node
/**
 * test-builder.mjs — проверяет, что сборщик сюжета действительно ловит ошибки.
 * Каждый кейс: порченый story.json → запуск tools/build-story.mjs → ожидаемый код
 * возврата и подстрока в выводе.
 *
 *   node tools/test-builder.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const WORK = path.join(ROOT, '.tmp', 'builder');
fs.rmSync(WORK, { recursive: true, force: true });
fs.mkdirSync(WORK, { recursive: true });

const baseStory = () => ({
	meta: { title: 'Тест', start: 'a', version: 1 },
	characters: { narrator: { name: '', color: '#ffffff' } },
	flags: { found: { label: 'Найдено' } },
	items: { key: { name: 'Ключ' } },
	endings: { good: { title: 'Хорошая', type: 'true', summary: 's', text: 'Финал.' } },
	nodes: [
		{
			id: 'a', act: 1, scene: 'A', speaker: 'narrator', text: 'Начало.',
			choices: [{ text: 'Дальше', goto: 'b' }],
		},
		{
			id: 'b', act: 1, scene: 'B', speaker: 'narrator', text: 'Середина.',
			onEnter: { set: { found: true }, give: ['key'] },
			choices: [{ text: 'Финал', goto: 'c', requires: { flags: ['found'], items: ['key'] } }],
		},
		{ id: 'c', act: 1, scene: 'C', speaker: 'narrator', text: 'Конец.', ending: 'good' },
	],
});

function runCase(name, mutate, { code = 0, expect = '' } = {}) {
	const story = baseStory();
	mutate?.(story);

	const storyFile = path.join(WORK, `${name}.json`);
	fs.writeFileSync(storyFile, JSON.stringify(story, null, 2), 'utf8');

	const result = spawnSync(process.execPath, [path.join(ROOT, 'tools', 'build-story.mjs')], {
		cwd: ROOT,
		encoding: 'utf8',
		env: {
			...process.env,
			STORY_FILE: storyFile,
			LUAU_OUT: path.join(WORK, `${name}.lua`),
			DOC_OUT: path.join(WORK, `${name}.md`),
		},
	});

	const output = `${result.stdout}\n${result.stderr}`;
	const okCode = result.status === code;
	const okText = !expect || output.includes(expect);
	checks += 1;
	if (okCode && okText) {
		console.log(`  ok   ${name}`);
	} else {
		failures += 1;
		console.log(`  FAIL ${name}\n       код: ${result.status} (ждали ${code}), вывод: ${output.trim().split('\n').slice(-4).join(' / ')}`);
	}
	return { storyFile, output, result };
}

let checks = 0;
let failures = 0;

console.log('— валидный сюжет');
{
	const { output } = runCase('valid', null, { code: 0, expect: 'Связность: OK' });
	if (!output.includes('Связность: OK')) process.exitCode = 1;
	const lua = fs.readFileSync(path.join(WORK, 'valid.lua'), 'utf8');
	checks += 1;
	if (lua.includes('return StoryData') && lua.includes('СГЕНЕРИРОВАНО')) console.log('  ok   Luau-модуль собран');
	else {
		failures += 1;
		console.log('  FAIL Luau-модуль собран');
	}
}

console.log('— ошибки (код 1)');
runCase('dangling-goto', (s) => { s.nodes[0].choices[0].goto = 'нет_такой_сцены'; }, { code: 1, expect: 'Висячая ссылка' });
runCase('dead-end', (s) => { delete s.nodes[2].ending; }, { code: 1, expect: 'Тупик' });
runCase('unknown-ending', (s) => { s.nodes[2].ending = 'missing'; }, { code: 1, expect: 'не объявлена' });
runCase('unknown-flag', (s) => { s.nodes[1].choices[0].requires.flags.push('ghost'); }, { code: 1, expect: 'несуществующий флаг' });
runCase('unknown-item', (s) => { s.nodes[1].choices[0].requires.items.push('ghost'); }, { code: 1, expect: 'несуществующий предмет' });
runCase('flag-never-set', (s) => { s.flags.unused = { label: 'Н' }; }, { code: 1, expect: 'нигде не ставится' });
runCase('item-never-given', (s) => { s.items.spare = { name: 'Запас' }; }, { code: 1, expect: 'нигде не выдаётся' });
runCase('bad-start', (s) => { s.meta.start = 'nowhere'; }, { code: 1, expect: 'такой сцены нет' });
runCase('duplicate-id', (s) => { s.nodes[1].id = 'a'; }, { code: 1, expect: 'Дубль id' });
runCase('no-choices', (s) => { s.nodes[0].choices = []; }, { code: 1, expect: 'Тупик' });

console.log('— предупреждения (код 0, но есть текст)');
runCase('unfired-flag', (s) => {
	s.flags.decor = { label: 'Декор' };
	s.nodes[0].onEnter = { set: { decor: true } };
}, { code: 0, expect: 'ружьё не выстрелило' });

runCase('unused-item', (s) => {
	s.items.prop = { name: 'Реквизит' };
	s.nodes[0].onEnter = { set: {}, give: ['prop'] };
}, { code: 0, expect: 'ни для чего не нужен' });

runCase('unreachable-scene', (s) => {
	s.nodes.push({ id: 'orphan', act: 2, scene: 'O', speaker: 'narrator', text: 'Т.', ending: 'good' });
}, { code: 0, expect: 'Недостижима сцена' });

runCase('shadowed-variant', (s) => {
	s.nodes[0].variants = [
		{ requires: { flags: [] }, text: 'Общий текст.' },
		{ requires: { flags: ['found'] }, text: 'Текст для нашедших.' },
	];
}, { code: 0, expect: 'недостижим' });

runCase('contradictory-variant', (s) => {
	s.nodes[0].variants = [
		{ requires: { flags: ['found'], notFlags: ['found'] }, text: 'Невозможно.' },
	];
}, { code: 1, expect: 'одновременно требует и запрещает' });

console.log('— Luau-ключи');
{
	// Ключ-ключевое слово должно попасть в скобки, иначе Luau не разберёт файл.
	const { storyFile } = { storyFile: path.join(WORK, 'keywords.json') };
	const story = baseStory();
	story.flags = { true: { label: 'Истина' }, found: { label: 'Найдено' } };
	story.nodes[1].onEnter.set.true = true;
	story.nodes[1].choices[0].requires.flags.push('true');
	fs.writeFileSync(storyFile, JSON.stringify(story, null, 2), 'utf8');

	const result = spawnSync(process.execPath, [path.join(ROOT, 'tools', 'build-story.mjs')], {
		cwd: ROOT,
		encoding: 'utf8',
		env: {
			...process.env,
			STORY_FILE: storyFile,
			LUAU_OUT: path.join(WORK, 'keywords.lua'),
			DOC_OUT: path.join(WORK, 'keywords.md'),
		},
	});

	const lua = fs.readFileSync(path.join(WORK, 'keywords.lua'), 'utf8');
	checks += 1;
	if (result.status === 0 && lua.includes('["true"]')) console.log('  ok   ключ-ключевое слово в скобках');
	else {
		failures += 1;
		console.log(`  FAIL ключ-ключевое слово в скобках (код ${result.status})`);
	}
}

console.log(`\nПроверок: ${checks}, провалено: ${failures}\n`);
process.exit(failures ? 1 : 0);
