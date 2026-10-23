#!/usr/bin/env node
/**
 * test-story-player.mjs — проверки story/player.js (превью в браузере)
 * и заодно исчерпывающий обход сюжета: все достижимые состояния, все концовки.
 *
 *   node tools/test-story-player.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { StoryPlayer } from '../story/player.js';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const story = JSON.parse(fs.readFileSync(path.join(ROOT, 'story', 'story.json'), 'utf8'));

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

const fresh = () => {
	const player = new StoryPlayer(story);
	player.enter(player.state.nodeId);
	return player;
};

function pick(player, text) {
	const node = player.node();
	const index = (node.choices ?? []).findIndex((choice) => choice.text === text);
	if (index < 0) return [false, `нет выбора «${text}» в «${node.id}»`];
	return player.choose(index + 1);
}

console.log('— базовая механика');
{
	const player = fresh();
	const view = player.current();
	check('старт', view.id === 'start');
	check('текст сцены', view.text.length > 40);
	check('выборов два', view.choices.length === 2);
	check('после входа сцена посещена', player.state.visited.start === true);
}

console.log('— условные выборы и подстановки');
{
	const player = fresh();
	pick(player, 'Сразу пройти в шлюз');
	pick(player, 'Молчать и идти дальше');
	pick(player, 'Идти в центральный узел');

	const hub = player.current(true);
	const relay = hub.choices.find((choice) => choice.text === 'К сигнальному реле');
	check('реле закрыто без осмотра', relay && relay.available === false);
	check('причина отказа видна игроку', relay.reason && relay.reason.length > 0, relay?.reason);

	const [ok, reason] = player.choose(relay.index);
	check('закрытый выбор не проходит', ok === false, reason);

	pick(player, 'Жилой блок');
	pick(player, 'Вернуться в узел');
	pick(player, 'Техтоннель');
	pick(player, 'Отступить в темноту');
	pick(player, 'Вернуться в узел');
	pick(player, 'Рубка');
	pick(player, 'Вернуться в узел');
	const openHub = player.current(true);
	check('после обхода реле открыто', openHub.choices.find((c) => c.text === 'К сигнальному реле')?.available === true);

	pick(player, 'К сигнальному реле');
	const view = player.current();
	check('вариант текста узнаёт МАМУ', view.text.includes('МАМА'), view.text.slice(0, 60));
}

console.log('— истинная концовка');
{
	const player = fresh();
	pick(player, 'Обойти обшивку снаружи');
	pick(player, 'Запомнить и войти внутрь');
	pick(player, 'Ответить');
	pick(player, '«Что за сигнал?»');
	pick(player, '«Понял. Иду внутрь»');
	pick(player, 'Идти в центральный узел');
	pick(player, 'Жилой блок');
	pick(player, 'Прослушать дневник');
	check('дневник в инвентаре', player.hasItem('diary'));
	pick(player, 'Забрать дневник');
	pick(player, 'Вскрыть шкафчик');
	check('ключ-карта в инвентаре', player.hasItem('keycard'));
	pick(player, 'Вернуться в узел');
	pick(player, 'Техтоннель');
	pick(player, 'Спросить про сигнал');
	check('Лира доверяет', player.hasFlag('lira_trust'));
	pick(player, '«Расскажи всё»');
	pick(player, '«Я не пойду. Обещаю»');
	pick(player, 'Рубка');
	pick(player, '«Что случилось с экипажем?»');
	check('правда известна', player.hasFlag('knows_truth'));
	pick(player, '«Я это сделаю»');
	pick(player, 'Вернуться в узел');
	pick(player, 'К сигнальному реле');
	pick(player, 'Обесточить через аварийный кабель у пробоины');
	pick(player, '«Кто ты на самом деле?»');
	pick(player, 'Показать ему дневник');
	check('Кай союзник', player.hasFlag('kai_ally'));
	pick(player, 'Идти к финалу');
	const finalView = player.current();
	check('финальный вариант знает про союзников', finalView.text.includes('Кай') && finalView.text.includes('ключ'), finalView.text.slice(0, 80));
	const [ok] = pick(player, 'Разорвать цикл: обесточить реле через пробоину и уйти втроём');
	check('истинный финал доступен', ok === true);
	check('концовка echo', player.current().ending?.id === 'echo', player.current().ending?.id);
	check('текст концовки подставлен', !player.current().ending.text.includes('$'));
	check('прогресс сохранён в state', player.state.ending === 'echo');
}

console.log('— все концовки достижимы (обход состояний)');
{
	// Флаги и предметы только накапливаются, поэтому пространство конечно.
	// Идём в ширину по (сцена + множество флагов + предметов), собираем концовки.
	const seen = new Set();
	const endings = new Set();
	const queue = [fresh()];
	let states = 0;
	const limit = 20000;

	while (queue.length && states < limit) {
		const player = queue.pop();
		states += 1;
		const node = player.node();
		const key = [
			node.id,
			Object.keys(player.state.flags).filter((f) => player.state.flags[f]).sort().join(','),
			Object.keys(player.state.items).filter((i) => player.state.items[i]).sort().join(','),
		].join('|');
		if (seen.has(key)) continue;
		seen.add(key);

		if (node.ending) {
			endings.add(node.ending);
			continue;
		}

		for (const [index, choice] of (node.choices ?? []).entries()) {
			if (!player.check(choice.requires)[0]) continue;
			const copy = new StoryPlayer(story, player.serialize());
			if (copy.choose(index + 1)[0]) queue.push(copy);
		}
	}

	check('обход завершён (не упёрлись в лимит)', states < limit, states);
	for (const id of Object.keys(story.endings)) {
		check(`концовка «${story.endings[id].title}» достижима`, endings.has(id));
	}
	check('лишних концовок нет', endings.size === Object.keys(story.endings).length, [...endings].join(','));

	// Из каждого достижимого состояния должен быть выход: либо выборы, либо концовка.
	let deadEnds = 0;
	for (const key of seen) {
		const [nodeId] = key.split('|');
		const node = story.nodes.find((item) => item.id === nodeId);
		if (!node.ending && !(node.choices ?? []).length) deadEnds += 1;
	}
	check('тупиков нет', deadEnds === 0, deadEnds);
	check('состояний обойдено больше сотни', states > 100, states);
}

console.log('— сохранение и рестарт');
{
	const player = fresh();
	pick(player, 'Обойти обшивку снаружи');
	const saved = player.serialize();
	const restored = new StoryPlayer(story, saved);
	check('флаг перенесён', restored.hasFlag('hull_scar'));
	check('сцена перенесена', restored.state.nodeId === player.state.nodeId);
	check('история не влияет на состояние', restored.state.nodeId === 'hull');

	restored.restart();
	check('рестарт в начало', restored.state.nodeId === 'start');
	check('рестарт чистит флаги', Object.keys(restored.state.flags).length === 0);

	const broken = new StoryPlayer(story, { nodeId: 'удалённая_сцена', flags: {}, items: {} });
	check('несуществующая сцена откатывается на старт', broken.state.nodeId === 'start');
}

console.log(`\nПроверок: ${checks}, провалено: ${failures}\n`);
process.exit(failures ? 1 : 0);
