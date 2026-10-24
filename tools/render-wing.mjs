#!/usr/bin/env node
// Рисует схему крыла: docs/схема-крыла.svg
//
//   node tools/render-wing.mjs
//
// Две панели: вся линия комнат (95 штук, цвет — акт) и крупный план одной
// комнаты: вход, персонаж, вывеска, выход и портал в следующую.

import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const world = JSON.parse(fs.readFileSync(path.join(ROOT, 'game/world.json'), 'utf8'));
const OUT = path.join(ROOT, 'docs/схема-крыла.svg');

const ACT = {
	1: { color: '#7dd3fc', name: 'I. Тишина' },
	2: { color: '#a3e635', name: 'II. Первого сентября' },
	3: { color: '#fbbf24', name: 'III. Сплав' },
	4: { color: '#f97316', name: 'IV. Жестокий сплав' },
};

const W = 1400;
const pad = 70;
const scenes = world.scenes;
const step = world.base.step;

const svg = [];
const push = (s) => svg.push(s);

// ── панель 1: вся линия комнат ──────────────────────────────────────────────
const stripY = 150;
const cellW = (W - pad * 2) / scenes.length;

push(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="720" viewBox="0 0 ${W} 720" font-family="ui-sans-serif, system-ui, sans-serif">`);
push(`<rect width="${W}" height="720" fill="#0b0e16"/>`);
push(`<text x="${pad}" y="52" fill="#e8ecf6" font-size="27" font-weight="600">Крыло сюжета: 95 комнат из моделей neirogh.rbxl</text>`);
push(`<text x="${pad}" y="78" fill="#8b93a7" font-size="14">сцена = комната из моделей плейса · в комнате двое актёров · реплики короткие, действия — позами (шаг, удар, захват) · интерфейса нет</text>`);

for (const scene of scenes) {
	const x = pad + scene.index * cellW;
	const act = ACT[scene.act] ?? ACT[1];
	const h = 26 + (scene.act - 1) * 6;
	const lines = (scene.lines ?? []).map((l) => `${l.s}: ${l.t}`).join(' / ');
	push(`<rect x="${x.toFixed(1)}" y="${(stripY + 40 - h / 2).toFixed(1)}" width="${(cellW - 1.5).toFixed(1)}" height="${h}" rx="2" fill="${act.color}" fill-opacity="0.85"><title>${scene.index + 1}. ${scene.id} — ${scene.scene}\n${lines}</title></rect>`);
}

// подписи актов и порталы
let lastAct = null;
for (const scene of scenes) {
	const act = ACT[scene.act];
	if (!act || act === lastAct) continue;
	lastAct = act;
	const x = pad + scene.index * cellW;
	push(`<line x1="${x.toFixed(1)}" y1="${stripY - 40}" x2="${x.toFixed(1)}" y2="${stripY + 80}" stroke="#2b3446" stroke-dasharray="3 4"/>`);
	push(`<text x="${(x + 4).toFixed(1)}" y="${stripY - 48}" fill="${act.color}" font-size="13" font-weight="600">${act.name}</text>`);
}
push(`<text x="${pad}" y="${stripY + 96}" fill="#5d6884" font-size="12">комната 1 · спавн игрока</text>`);
push(`<text x="${W - pad}" y="${stripY + 96}" fill="#5d6884" font-size="12" text-anchor="end">комната 95 · финальная глава</text>`);

// последний портал
push(`<path d="M${W - pad + 6} ${stripY + 40} l26 0" stroke="#f97316" stroke-width="3"/>`);
push(`<path d="M${W - pad + 32} ${stripY + 32} l14 8 -14 8z" fill="#f97316"/>`);
push(`<text x="${W - pad + 4}" y="${stripY + 18}" fill="#f97316" font-size="12">портал в следующую локацию</text>`);

// ── панель 2: план комнаты ─────────────────────────────────────────────────
const planTop = 330;
const planH = 250;
push(`<text x="${pad}" y="${planTop - 24}" fill="#e8ecf6" font-size="19" font-weight="600">Как устроена одна комната</text>`);
const plan = scenes.find((s) => s.id === 'vanya_fight') ?? scenes[18] ?? scenes[0];
push(`<text x="${pad}" y="${planTop}" fill="#8b93a7" font-size="13">вид сверху: ${plan.id} · ${plan.scene} · реплики: ${(plan.lines ?? []).map((l) => l.t).join(' / ')}</text>`);

const sample = plan;
const roomW = world.base.roomWidth;
const sx = (v) => pad + 40 + ((v - (sample.center[0] - roomW / 2)) / roomW) * (W - pad * 2 - 80);
const sz = (v) => planTop + 120 + (v - sample.center[2]) * 4;

push(`<rect x="${sx(sample.center[0] - roomW / 2).toFixed(1)}" y="${(planTop + 20).toFixed(1)}" width="${(sx(sample.center[0] + roomW / 2) - sx(sample.center[0] - roomW / 2)).toFixed(1)}" height="${planH}" rx="8" fill="#111726" stroke="#25304a"/>`);

const dot = (p, color, label, r = 9) => {
	push(`<circle cx="${sx(p[0]).toFixed(1)}" cy="${sz(p[2]).toFixed(1)}" r="${r}" fill="${color}" fill-opacity="0.9"/>`);
	push(`<text x="${sx(p[0]).toFixed(1)}" y="${(sz(p[2]) - r - 8).toFixed(1)}" fill="${color}" font-size="12" text-anchor="middle">${label}</text>`);
};

dot(sample.arrival, '#7dd3fc', 'вход · сюда выбрасывает портал');
(sample.actors ?? []).forEach((actor, i) => {
	dot(actor.at, '#a3e635', `${actor.name}${actor.stance && actor.stance !== 'idle' ? ' · ' + actor.stance : ''}`, 11);
});
const signW = 12 * ((W - pad * 2 - 80) / roomW);
push(`<rect x="${(sx(sample.sign[0]) - signW / 2).toFixed(1)}" y="${(sz(sample.sign[2]) - 4).toFixed(1)}" width="${signW.toFixed(1)}" height="8" rx="2" fill="#e2e8f0" fill-opacity="0.9"/>`);
push(`<text x="${(sx(sample.sign[0]) + 150).toFixed(1)}" y="${(sz(sample.sign[2]) - 10).toFixed(1)}" fill="#e2e8f0" font-size="12">вывеска с текстом сцены</text>`);
dot(sample.exit, '#f97316', 'выход · портал дальше', 8);

// ось «вперёд»
push(`<line x1="${sx(sample.arrival[0]).toFixed(1)}" y1="${(planTop + planH + 30).toFixed(1)}" x2="${sx(sample.exit[0]).toFixed(1)}" y2="${(planTop + planH + 30).toFixed(1)}" stroke="#2b3446" stroke-width="2" marker-end="url(#arrow)"/>`);
push(`<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#2b3446"/></marker></defs>`);
push(`<text x="${((sx(sample.arrival[0]) + sx(sample.exit[0])) / 2).toFixed(1)}" y="${(planTop + planH + 52).toFixed(1)}" fill="#5d6884" font-size="12" text-anchor="middle">игрок идёт вперёд</text>`);

// панель поз: что видит игрок вместо описания драки
const poseY = 470;
push(`<text x="${pad}" y="${poseY - 16}" fill="#e8ecf6" font-size="17" font-weight="600">Действия — позами, а не текстом</text>`);
const poses = [
	['step', 'шагнул вперёд'],
	['punch', 'ударил'],
	['throw', 'замахнулся'],
	['choke', 'взял за горло'],
	['block', 'закрылся'],
	['kneel', 'опустился на колено'],
];
poses.forEach(([pose, label], i) => {
	const x = pad + i * 210;
	push(`<rect x="${x}" y="${poseY}" width="150" height="34" rx="6" fill="#151b29" stroke="#25304a"/>`);
	push(`<text x="${x + 10}" y="${poseY + 22}" fill="#a3e635" font-size="13" font-family="ui-monospace, monospace">${pose}</text>`);
	push(`<text x="${x + 78}" y="${poseY + 22}" fill="#8b93a7" font-size="12">${label}</text>`);
});

// легенда снизу
let lx = pad;
const legendY = 690;
for (const act of [1, 2, 3, 4]) {
	push(`<circle cx="${lx}" cy="${legendY - 4}" r="5" fill="${ACT[act].color}"/>`);
	push(`<text x="${lx + 12}" y="${legendY}" fill="#8b93a7" font-size="13">${ACT[act].name}</text>`);
	lx += 250;
}
push(`<text x="${W - pad}" y="${legendY}" fill="#5d6884" font-size="12" text-anchor="end">шаг между комнатами: ${step} юнитов · ширина комнаты: ${roomW}</text>`);

push('</svg>');
fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, svg.join('\n'), 'utf8');
console.log(`  → ${path.relative(ROOT, OUT)} (комнат: ${scenes.length})`);
