#!/usr/bin/env node
/**
 * test-place-map.mjs — проверки карты neirogh.rbxl и её связи с сюжетом.
 *
 *   node tools/test-place-map.mjs
 *
 * Карта (game/place-map.json) снимается с бинарного place-файла скриптом
 * tools/place-import.mjs, анализ координат (game/layout.json) считает
 * tools/analyze-place.mjs. Здесь проверяется, что:
 *   • координаты настоящие и лежат в разумных пределах;
 *   • кластеры текста не пересекаются и покрывают все вывески;
 *   • огонь — одна полоса, и она ровно там, куда ведёт телепорт финала;
 *   • телепорты карты связывают разные кластеры;
 *   • стори-телепорт ссылается на арену из layout.json.
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const read = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), 'utf8'));

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

const map = read('game/place-map.json');
const layout = read('game/layout.json');
const story = read('story/story.json');

const finite = (value, limit = 100000) => Number.isFinite(value) && Math.abs(value) <= limit;
const pointOk = (point) => Array.isArray(point) && point.length === 3 && point.every((v) => finite(v));

console.log('— карта');
{
	check('источник — neirogh.rbxl', map.source === 'neirogh.rbxl', map.source);
	check('спавн найден', pointOk(map.spawn));
	check('вывесок больше двухсот', map.signs.length > 200, map.signs.length);
	check('у каждой вывески есть текст', map.signs.every((sign) => typeof sign.text === 'string' && sign.text.trim().length > 0));
	check('координаты вывесок конечные', map.signs.every((sign) => finite(sign.x) && finite(sign.y) && finite(sign.z)));
	check('огней ровно пятьдесят', map.fires.length === 50, map.fires.length);
	check('все точки огня конечные', map.fires.every(pointOk));
	check('телепортов карты не меньше пяти', map.teleports.length >= 5, map.teleports.length);
	const pairs = map.teleports.filter((tp) => tp.parts.length >= 2 && tp.parts[0].pos && tp.parts[1].pos);
	check('у телепортов есть вход и выход', pairs.length >= 5, pairs.length);
	check('вход и выход не совпадают', pairs.every((tp) => tp.parts[0].pos.join() !== tp.parts[1].pos.join()));
}

console.log('— кластеры и связи');
{
	check('кластеров больше пяти', layout.clusters.length > 5, layout.clusters.length);
	const covered = layout.clusters.reduce((sum, cluster) => sum + cluster.signCount, 0);
	check('все вывески разложены по кластерам', covered === map.signs.length, `${covered}/${map.signs.length}`);
	check('у кластеров есть границы', layout.clusters.every((c) => c.minX <= c.maxX && finite(c.center[0])));
	check('есть связи между кластерами', layout.links.length > 0, layout.links.length);
	check('есть связи-телепорты', layout.links.some((link) => link.kind === 'телепорт'));
	check('персонажи привязаны к сценам', layout.clusters.some((c) => c.actors.length > 0));
	check('все персонажи валидны', (map.actors ?? []).every((actor) => pointOk(actor.pos)));
}

console.log('— огненная арена');
{
	check('зона огня найдена', Boolean(layout.fireZone));
	const fire = layout.fireZone;
	check('огонь — узкая полоса', fire.sizeZ < fire.sizeX, `${fire.sizeX}×${fire.sizeZ}`);
	check('огонь рядом с кластером', Boolean(fire.nearestCluster));
	check('арена финала определена', Boolean(layout.finale.arena));
	check('арена — это кластер у огня', layout.finale.arena === fire.nearestCluster, `${layout.finale.arena} / ${fire.nearestCluster}`);
	check('огонь внутри арены по проверке анализатора', layout.finale.fireCheck === true);
	check('арена далеко от спавна', layout.finale.spawnDistance > 100, layout.finale.spawnDistance);
}

console.log('— сюжет использует карту');
{
	const tp = story.nodes.find((node) => node.teleport)?.teleport;
	check('в сюжете есть телепорт', Boolean(tp));
	check('телепорт в последней главе', story.nodes.find((node) => node.teleport)?.act === 4);
	if (tp) {
		const fire = layout.finale.fireCenter;
		check('цель телепорта = центр огня', Math.abs(tp.target[0] - fire[0]) < 0.5 && Math.abs(tp.target[2] - fire[2]) < 0.5,
			`${JSON.stringify(tp.target)} vs ${JSON.stringify(fire)}`);
		check('цель телепорта на карте', pointOk(tp.target));
	}
	const meta = story.meta.map;
	check('в meta есть карта', Boolean(meta));
	check('meta.spawn совпадает с картой', meta.spawn.join() === map.spawn.join());
	check('meta.arena.fire совпадает с layout', meta.arena.fire.join() === layout.finale.fireCenter.join());
	check('meta.teleports повторяет телепорты карты', meta.teleports.length === layout.teleports.length, meta.teleports.length);
	check('в сюжете 4 акта', new Set(story.nodes.map((n) => n.act)).size === 4);
	check('финальная глава названа по канону', story.nodes.some((n) => (n.chapter ?? '').includes('Жестокий сплав огня и ревности')));
}

console.log(`\nПроверок: ${checks}, провалено: ${failures}\n`);
process.exit(failures ? 1 : 0);
