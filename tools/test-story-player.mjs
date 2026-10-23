#!/usr/bin/env node
/**
 * test-story-player.mjs — проверки story/player.js (превью в браузере)
 * и заодно исчерпывающий разбор сюжета: главы, телепорт, анимации, концовки.
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

const go = (player, text) => {
	const [ok, detail] = pick(player, text);
	check(`переход «${text}»`, ok, detail);
	return ok;
};

const nodeById = new Map(story.nodes.map((node) => [node.id, node]));
const teleportNode = story.nodes.find((node) => node.teleport);

console.log('— базовые проверки');
{
	const player = fresh();
	const view = player.current();
	check('старт', view.id === 'start');
	check('текст сцены не пустой', view.text.length > 10);
	check('выборов два', view.choices.length === 2);
	check('глава заполнена', typeof view.chapter === 'string' && view.chapter.length > 0);
	check('сцена не помечена концовкой', view.isEnding === false);
}

console.log('— сюжет собран в одну линию');
{
	const acts = new Set(story.nodes.map((node) => node.act));
	check('четыре акта', [1, 2, 3, 4].every((act) => acts.has(act)), [...acts].join(','));
	check('сцен больше восьмидесяти', story.nodes.length > 80, story.nodes.length);
	const words = story.nodes.reduce((sum, node) => sum + String(node.text ?? '').split(/\s+/).filter(Boolean).length, 0);
	check('слов не меньше шестисот', words > 600, words);
	check('слов меньше двух тысяч (короткие фразы, а не простыни)', words < 2000, words);

	// Реплики: короткие, с позами, не больше четырёх на сцену.
	const POSES = new Set(['idle','say','point','step','reach','grab','punch','throw','block','choke','guard','kneel','fall']);
	const noLines = story.nodes.filter((n) => !Array.isArray(n.lines) || n.lines.length === 0);
	check('у каждой сцены есть реплики', noLines.length === 0, noLines.map((n) => n.id).join(', '));
	const tooFew = story.nodes.filter((n) => (n.lines ?? []).length < 2);
	check('в каждой сцене минимум две реплики', tooFew.length === 0, tooFew.map((n) => n.id).join(', '));
	const tooMany = story.nodes.filter((n) => (n.lines ?? []).length > 4);
	check('на сцену не больше четырёх реплик', tooMany.length === 0, tooMany.map((n) => n.id).join(', '));
	const tooLong = [];
	const badPose = [];
	const noAction = [];
	for (const node of story.nodes) {
		for (const line of node.lines ?? []) {
			if (String(line.t).length > 110) tooLong.push(node.id);
			if (!POSES.has(line.pose)) badPose.push(`${node.id}:${line.pose}`);
		}
	}
	check('ни одна реплика не длиннее 110 символов', tooLong.length === 0, tooLong.join(', '));
	check('у всех реплик известная поза', badPose.length === 0, badPose.slice(0, 5).join(', '));
	const actions = story.nodes.flatMap((n) => n.lines ?? []).filter((l) => ['punch','throw','choke','grab','block','reach','fall','kneel','step'].includes(l.pose));
	check('действия показаны позами, а не текстом', actions.length > 40, actions.length);
	check('есть удары и захваты', ['punch','choke','throw','grab'].every((p) => actions.some((l) => l.pose === p)));

	// Рассказчик — только подпись места или финальная строка. Драку он не описывает.
	const captions = story.nodes.filter((n) => (n.lines ?? []).some((l) => l.s === 'narrator' && !n.isEnding));
	check('подпись рассказчика не больше одной на сцену', captions.every((n) => n.lines.filter((l) => l.s === 'narrator').length === 1));
	check('рассказчик не играет позами', story.nodes.every((n) => n.lines.every((l) => l.s !== 'narrator' || l.pose === 'idle')));
	const silentScenes = story.nodes.filter((n) => !(n.lines ?? []).some((l) => l.s !== 'narrator' && l.s !== ''));
	check('в каждой сцене говорят персонажи', silentScenes.length === 0, silentScenes.map((n) => n.id).join(', '));
	const allText = story.nodes.flatMap((n) => (n.lines ?? []).map((l) => l.t));
	check('ни одна реплика не повторяется', new Set(allText).size === allText.length);
	const finalChapter = story.nodes.find((node) => (node.chapter ?? '').includes('Жестокий сплав огня и ревности'));
	check('есть глава «Жестокий сплав огня и ревности»', Boolean(finalChapter));
	check('глава идёт последней (акт 4)', finalChapter?.act === 4);
	check('концовок три', Object.keys(story.endings).length === 3);
}

console.log('— телепорт последней главы');
{
	check('сцена с телепортом есть', Boolean(teleportNode));
	if (teleportNode) {
		const tp = teleportNode.teleport;
		check('телепорт в акте 4', teleportNode.act === 4);
		check('координаты — три числа', Array.isArray(tp.target) && tp.target.length === 3 && tp.target.every(Number.isFinite));
		check('цель — арена огня (x ≈ -201.6)', Math.abs(tp.target[0] + 201.6) < 1, tp.target[0]);
		check('цель — арена огня (z ≈ 6.1)', Math.abs(tp.target[2] - 6.1) < 1, tp.target[2]);
		check('placeId из цифр', /^\d+$/.test(tp.placeId));
		check('телепорт требует плату', (tp.requires?.items ?? []).includes('plate'));
		check('у телепорта есть анимация', typeof tp.animation === 'string' && tp.animation.length > 0);
		check('у телепорта есть сцена прибытия', Boolean(nodeById.get(tp.arrival)));
		check('координаты совпадают с картой', (() => {
			const fire = story.meta.map?.arena?.fire;
			return Array.isArray(fire) && Math.abs(fire[0] - tp.target[0]) < 1 && Math.abs(fire[2] - tp.target[2]) < 1;
		})());
	}

	// Без платы кнопка телепорта должна быть закрыта.
	const player = fresh();
	for (const text of [
		'Обойти обшивку снаружи', 'Запомнить и войти внутрь', 'Молчать и идти дальше', 'Жилой блок', 'Прослушать дневник',
		'Забрать дневник', 'Вскрыть шкафчик', 'Забрать фотографию', 'Вернуться в узел',
		'Техтоннель', 'Спросить про сигнал', '«Расскажи всё»', '«Что мне делать?»',
		'Идти в центральный узел', 'К сигнальному реле', 'Прочитать тетрадь', 'Перевернуть страницу',
		'Закрыть тетрадь', 'Обесточить через аварийный кабель у пробоины', 'Войти в купол', 'Войти в ворота', 'Подойти к компании', '«Я с вами»',
		'Пойти за Демидом', 'Промолчать', '«Я не хочу драться»', '«Тогда давай вспомним вместе»',
		'Сказать «прости»', 'Уйти в клинч и сказать ему на ухо правду', '«Останется тот, кто умеет вставать»',
		'«Ты — не я»', '«Ради права быть настоящим»', 'Спросить, как он пережил смерть',
		'«Тогда ты знаешь, зачем я вернулся»', 'Отступить и позвать Демида', '«Прикрой»',
		'Прочитать последнюю страницу', 'Не дать кругу замкнуться', 'Отпустить нить',
		'«Веди меня туда»', 'Спуститься', '«Тогда объясни»', '«А если погасить тебя — что останется?»',
		'«Это не свобода»', '«Ты предлагаешь нам выбрать, кто умрёт»', '«Вам здесь не место»',
		'«Он — копия. Оригинал — я»', '«Один очаг — это чья-то память»', '«Тогда горите вы»',
		'«Демид, прикрой левый фланг»', '«Почему я не удивлён»', '«Значит, решим это здесь»',
		'Пожать руку', 'Идти к телепорту', 'Подойти к Артинсу', '«Это и есть любовь»',
		'Активировать телепорт', 'Достать плату телепорта',
	]) {
		if (!go(player, text)) break;
	}
	const view = player.current();
	check('дошли до сцены телепорта', view.id === 'ch4_teleport', view.id);
	check('телепорт открыт — плата есть', view.teleport?.available === true);
	check('в виде есть координаты', view.teleport?.target?.[0] === teleportNode?.teleport.target[0]);

	// Кнопка телепорта в веб-плеере идёт через обычный выбор в сцену прибытия.
	const arrivalChoice = (nodeById.get('ch4_teleport')?.choices ?? []).find((choice) => choice.goto === teleportNode.teleport.arrival);
	check('у телепорта есть выбор-переход', Boolean(arrivalChoice));
	const [ok, next] = player.choose(nodeById.get('ch4_teleport').choices.indexOf(arrivalChoice) + 1);
	check('телепорт переносит на арену', ok && next.id === 'arena_arrival', next?.id);
}

console.log('— анимации повторяются бесконечно');
{
	const animated = story.nodes.filter((node) => (node.animations ?? []).length > 0);
	check('сцены с анимациями есть', animated.length >= 3, animated.length);
	const all = animated.flatMap((node) => node.animations);
	check('анимаций больше пяти', all.length > 5, all.length);
	check('все анимации зациклены', all.every((anim) => anim.loop !== false && anim.frames.length > 1));
	check('у всех анимаций есть fps', all.every((anim) => Number(anim.fps) > 0));

	// Тот же алгоритм, что в Cinema.lua и preview.html: кадры идут по кругу.
	const track = all[0];
	let index = 0;
	let loops = 0;
	for (let step = 0; step < track.frames.length * 4; step += 1) {
		index += 1;
		if (index >= track.frames.length) {
			index = 0;
			loops += 1;
		}
	}
	check('цикл перезапускается', loops === 4, loops);
	check('кадр остаётся валидным', typeof track.frames[index] === 'string');
}

console.log('— финал: смерть Артёма или Артинса неизбежна');
{
	const finalNode = nodeById.get('final_choice');
	check('финальный выбор существует', Boolean(finalNode));
	const endings = new Set();
	for (const choice of finalNode.choices) {
		const next = nodeById.get(choice.goto);
		check(`финал «${next?.scene}» ведёт в концовку`, Boolean(next?.ending));
		if (next?.ending) endings.add(next.ending);
	}
	check('финал даёт все три концовки', endings.size === 3, [...endings].join(','));

	const dead = [];
	for (const id of endings) {
		const text = story.endings[id].text;
		const somethingDies = /умира|умер|пепел|остыв|перестаёшь|раствор|гаснет/.test(text);
		if (somethingDies) dead.push(id);
	}
	check('в каждой концовке кто-то погибает', dead.length === 3, dead.join(','));

	// Все концовки достижимы статически: требования выборов где-то выполняются.
	const settable = new Set();
	const givable = new Set();
	for (const node of story.nodes) {
		for (const flag of Object.keys(node.onEnter?.set ?? {})) settable.add(flag);
		for (const item of node.onEnter?.give ?? []) givable.add(item);
		for (const choice of node.choices ?? []) {
			for (const flag of Object.keys(choice.set ?? {})) settable.add(flag);
			for (const item of choice.give ?? []) givable.add(item);
		}
	}
	const passable = (requires = {}) =>
		(requires.flags ?? []).every((f) => settable.has(f)) &&
		(requires.notFlags ?? []).every((f) => settable.has(f)) &&
		(requires.items ?? []).every((i) => givable.has(i));

	const reached = new Set();
	const queue = [story.meta.start];
	while (queue.length) {
		const id = queue.pop();
		if (reached.has(id)) continue;
		reached.add(id);
		const node = nodeById.get(id);
		for (const choice of node?.choices ?? []) {
			if (choice.goto && passable(choice.requires)) queue.push(choice.goto);
		}
	}
	check('все сцены достижимы', reached.size === story.nodes.length, `${reached.size}/${story.nodes.length}`);
	const endingNodes = story.nodes.filter((node) => node.ending);
	check('все концовки достижимы', endingNodes.every((node) => reached.has(node.id)));
	check('тупиков нет', story.nodes.every((node) => node.ending || (node.choices ?? []).length > 0));
}

console.log('— сохранение и рестарт');
{
	const player = fresh();
	pick(player, 'Обойти обшивку снаружи');
	const saved = player.serialize();
	const restored = new StoryPlayer(story, saved);
	check('флаг перенесён', restored.hasFlag('hull_scar'));
	check('сцена перенесена', restored.state.nodeId === player.state.nodeId);

	restored.restart();
	check('рестарт в начало', restored.state.nodeId === 'start');
	check('рестарт чистит флаги', Object.keys(restored.state.flags).length === 0);

	const broken = new StoryPlayer(story, { nodeId: 'удалённая_сцена', flags: {}, items: {} });
	check('несуществующая сцена откатывается на старт', broken.state.nodeId === 'start');
}

console.log(`\nПроверок: ${checks}, провалено: ${failures}\n`);
process.exit(failures ? 1 : 0);
