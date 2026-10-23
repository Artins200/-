#!/usr/bin/env node
/**
 * build-story.mjs — сборка и проверка связности сюжета.
 *
 *   node tools/build-story.mjs
 *
 * Что делает:
 *   1. читает story/story.json (единственный источник правды);
 *   2. проверяет граф: висячие ссылки, недостижимые сцены/концовки,
 *      тупики, флаги-«ружья», которые никуда не стреляют;
 *   3. генерирует Luau-модуль  roblox/src/ReplicatedStorage/Shared/StoryData.lua;
 *   4. генерирует  docs/ГРАФ.md  (mermaid + отчёт).
 *
 * Код возврата 1, если есть ошибки (ERROR). Предупреждения не блокируют сборку.
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
// Пути можно переопределить (используется в tools/test-builder.mjs).
const resolveFromCwd = (value) => path.resolve(process.cwd(), value);
const STORY_PATH = process.env.STORY_FILE
  ? resolveFromCwd(process.env.STORY_FILE)
  : path.join(ROOT, 'story', 'story.json');
const LUAU_PATH = process.env.LUAU_OUT
  ? resolveFromCwd(process.env.LUAU_OUT)
  : path.join(ROOT, 'roblox', 'src', 'ReplicatedStorage', 'Shared', 'StoryData.lua');
const DOC_PATH = process.env.DOC_OUT
  ? resolveFromCwd(process.env.DOC_OUT)
  : path.join(ROOT, 'docs', 'ГРАФ.md');

const story = JSON.parse(fs.readFileSync(STORY_PATH, 'utf8'));
const nodes = story.nodes ?? [];
const byId = new Map();
const errors = [];
const warnings = [];

const err = (msg) => errors.push(msg);
const warn = (msg) => warnings.push(msg);

/* ---------- 1. базовая структура ---------- */
for (const n of nodes) {
  if (!n.id) { err(`Сцена без id: ${JSON.stringify(n).slice(0, 60)}…`); continue; }
  if (byId.has(n.id)) err(`Дубль id сцены: «${n.id}»`);
  byId.set(n.id, n);
}
const flagIds = new Set(Object.keys(story.flags ?? {}));
const itemIds = new Set(Object.keys(story.items ?? {}));
const endingIds = new Set(Object.keys(story.endings ?? {}));

if (!byId.has(story.meta?.start)) err(`meta.start = «${story.meta?.start}» — такой сцены нет`);

/* ---------- 2. ссылки ---------- */
const edges = [];               // {from, to, label}
const setsFlag = new Map();     // flag -> [nodeId]
const usesFlag = new Map();     // flag -> [nodeId]
const givesItem = new Map();
const needsItem = new Map();

const mark = (map, key, where) => {
  if (!map.has(key)) map.set(key, []);
  map.get(key).push(where);
};

for (const n of nodes) {
  if (n.ending && !endingIds.has(n.ending)) err(`«${n.id}»: концовка «${n.ending}» не объявлена в endings`);
  if (!n.ending && !(n.choices?.length)) err(`Тупик: у сцены «${n.id}» нет ни выборов, ни концовки`);

  for (const f of Object.keys(n.onEnter?.set ?? {})) mark(setsFlag, f, n.id);
  for (const it of n.onEnter?.give ?? []) mark(givesItem, it, n.id);
  for (const v of n.variants ?? []) {
    for (const f of v.requires?.flags ?? []) mark(usesFlag, f, n.id);
  }

  for (const [i, c] of (n.choices ?? []).entries()) {
    if (!c.text) err(`«${n.id}», выбор #${i + 1}: нет текста`);
    if (c.goto && !byId.has(c.goto)) {
      err(`Висячая ссылка: «${n.id}» → «${c.goto}» (сцены нет)`);
    } else if (c.goto) {
      edges.push({ from: n.id, to: c.goto, label: c.text });
    }
    for (const f of c.requires?.flags ?? []) { mark(usesFlag, f, n.id); if (!flagIds.has(f)) err(`«${n.id}»: требует несуществующий флаг «${f}»`); }
    for (const f of c.requires?.notFlags ?? []) { mark(usesFlag, f, n.id); if (!flagIds.has(f)) err(`«${n.id}»: требует несуществующий флаг «${f}»`); }
    for (const it of c.requires?.items ?? []) { mark(needsItem, it, n.id); if (!itemIds.has(it)) err(`«${n.id}»: требует несуществующий предмет «${it}»`); }
    for (const f of Object.keys(c.set ?? {})) { mark(setsFlag, f, n.id); if (!flagIds.has(f)) err(`«${n.id}»: ставит необъявленный флаг «${f}»`); }
    for (const it of c.give ?? []) { mark(givesItem, it, n.id); if (!itemIds.has(it)) err(`«${n.id}»: выдаёт необъявленный предмет «${it}»`); }
  }
}

/* ---------- 2б. перекрытые варианты текста ---------- */
// variants перебираются сверху вниз, побеждает первый подходящий.
// Если условие более позднего варианта включает в себя условие более раннего,
// то более поздний не выберется никогда.
// Требования small слабее требований big: любое состояние, подходящее под big,
// подходит и под small. Положительные и отрицательные флаги не смешиваем.
const subset = (small, big) => {
  const bigFlags = new Set(big.flags ?? []);
  const bigNot = new Set(big.notFlags ?? []);
  const flagsOk =
    [...(small.flags ?? [])].every((f) => bigFlags.has(f)) &&
    [...(small.notFlags ?? [])].every((f) => bigNot.has(f));
  const bigItems = new Set(big.items ?? []);
  const itemsOk = [...(small.items ?? [])].every((i) => bigItems.has(i));
  return flagsOk && itemsOk;
};

for (const n of nodes) {
  const list = n.variants ?? [];
  for (const [index, variant] of list.entries()) {
    const both = (variant.requires?.flags ?? []).filter((f) => (variant.requires?.notFlags ?? []).includes(f));
    if (both.length) {
      err(`«${n.id}»: вариант #${index + 1} одновременно требует и запрещает флаг «${both[0]}»`);
    }
  }
  for (let i = 0; i < list.length; i++) {
    for (let j = i + 1; j < list.length; j++) {
      if (subset(list[i].requires ?? {}, list[j].requires ?? {})) {
        warn(
          `«${n.id}»: вариант #${j + 1} недостижим — его условие включает вариант #${i + 1}, ` +
            `который проверяется раньше. Поставь более специфичный вариант выше.`,
        );
      }
    }
  }
}

/* ---------- 3. достижимость ---------- */
const start = story.meta?.start;
const reachable = new Set();
if (byId.has(start)) {
  const stack = [start];
  while (stack.length) {
    const id = stack.pop();
    if (reachable.has(id)) continue;
    reachable.add(id);
    for (const e of edges) if (e.from === id) stack.push(e.to);
  }
}
for (const n of nodes) {
  if (!reachable.has(n.id)) warn(`Недостижима сцена «${n.id}» — на неё ниоткуда нет перехода`);
}
const reachableEndings = new Set(nodes.filter((n) => reachable.has(n.id) && n.ending).map((n) => n.ending));
for (const id of endingIds) {
  if (!reachableEndings.has(id)) warn(`Недостижима концовка «${id}» (${story.endings[id].title})`);
}

/* ---------- 4. «ружья»: флаги и предметы ---------- */
for (const f of flagIds) {
  if (!setsFlag.has(f)) err(`Флаг «${f}» нигде не ставится, но, возможно, требуется`);
  else if (!usesFlag.has(f)) warn(`Флаг «${f}» ставится, но нигде не проверяется — «ружьё не выстрелило»`);
}
for (const it of itemIds) {
  if (!givesItem.has(it)) err(`Предмет «${it}» нигде не выдаётся`);
  else if (!needsItem.has(it)) warn(`Предмет «${it}» можно получить, но он ни для чего не нужен`);
}

/* ---------- 5. отчёт ---------- */
const ok = errors.length === 0;
const stats = {
  nodes: nodes.length,
  edges: edges.length,
  endings: endingIds.size,
  flags: flagIds.size,
  items: itemIds.size,
  words: nodes.reduce((s, n) => s + String(n.text ?? '').split(/\s+/).filter(Boolean).length, 0),
};

console.log(`\n  «${story.meta?.title}» — сцен: ${stats.nodes}, переходов: ${stats.edges}, слов: ${stats.words}`);
console.log(`  Концовки: ${[...endingIds].map((e) => story.endings[e].title).join(' · ')}`);
if (warnings.length) {
  console.log('\n  ПРЕДУПРЕЖДЕНИЯ:');
  for (const w of warnings) console.log(`   ! ${w}`);
}
if (errors.length) {
  console.log('\n  ОШИБКИ:');
  for (const e of errors) console.log(`   x ${e}`);
}
console.log(ok && !warnings.length ? '\n  Связность: OK\n' : `\n  Итог: ${errors.length} ошибок, ${warnings.length} предупреждений\n`);

/* ---------- 6. mermaid + отчёт ---------- */
const esc = (s) => String(s).replace(/"/g, "'").replace(/\n/g, ' ');
const actColor = ['#3b82f6', '#a855f7', '#f59e0b'];
const mermaidLines = ['```mermaid', 'flowchart TD'];
for (const n of nodes) {
  const ending = n.ending ? ` ⟶ «${story.endings[n.ending].title}»` : '';
  mermaidLines.push(`  ${n.id}["${esc(n.scene ?? n.id)}${ending}"]`);
}
for (const e of edges) mermaidLines.push(`  ${e.from} --> ${e.to}`);
for (let i = 0; i < 3; i++) {
  mermaidLines.push(`  classDef act${i + 1} fill:${actColor[i]}22,stroke:${actColor[i]},stroke-width:2px,color:#e5e7eb`);
}
for (const n of nodes) mermaidLines.push(`  class ${n.id} act${n.act ?? 1}`);
mermaidLines.push('```');

const doc = `# Граф сюжета «${story.meta?.title}»

> Файл сгенерирован \`node tools/build-story.mjs\`. Руками не правим — правим \`story/story.json\`.

**Сцен:** ${stats.nodes} · **переходов:** ${stats.edges} · **слов:** ${stats.words} · **концовок:** ${stats.endings}

${ok ? '✅ Связность в порядке.' : `❌ Ошибок: ${errors.length}.`} ${warnings.length ? `Предупреждений: ${warnings.length}.` : ''}

${mermaidLines.join('\n')}

## Концовки

| id | Название | Тип | Как получить |
|---|---|---|---|
${[...endingIds].map((id) => {
  const e = story.endings[id];
  const src = nodes.filter((n) => n.ending === id).map((n) => `\`${n.id}\``).join(', ');
  return `| \`${id}\` | ${e.title} | ${e.type} | ${src || '—'} |`;
}).join('\n')}

## Проверки

${errors.length ? `### Ошибки\n\n${errors.map((e) => `- ${e}`).join('\n')}\n` : ''}
${warnings.length ? `### Предупреждения\n\n${warnings.map((w) => `- ${w}`).join('\n')}\n` : ''}
${!errors.length && !warnings.length ? 'Все проверки пройдены: нет висячих ссылок, тупиков, недостижимых сцен и «нестреляющих ружей».\n' : ''}
`;
fs.mkdirSync(path.dirname(DOC_PATH), { recursive: true });
fs.writeFileSync(DOC_PATH, doc, 'utf8');

/* ---------- 7. Luau-модуль ---------- */
const LUA_KEYWORDS = new Set([
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'goto', 'if',
  'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while',
  'continue', 'type', 'export',
]);
// `{ true = ... }` — синтаксическая ошибка Luau, поэтому ключ-ключевое слово идёт в скобки.
const luaKey = (k) =>
  /^[A-Za-z_]\w*$/.test(k) && !LUA_KEYWORDS.has(k) ? k : `["${String(k).replace(/"/g, '\\"')}"]`;
function toLua(v, depth = 0) {
  const pad = '\t'.repeat(depth + 1);
  const close = '\t'.repeat(depth);
  if (v === null) return 'nil';
  if (typeof v === 'string') return `"${v.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n')}"`;
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) {
    if (!v.length) return '{}';
    return `{\n${v.map((x) => `${pad}${toLua(x, depth + 1)},`).join('\n')}\n${close}}`;
  }
  const keys = Object.keys(v);
  if (!keys.length) return '{}';
  return `{\n${keys.map((k) => `${pad}${luaKey(k)} = ${toLua(v[k], depth + 1)},`).join('\n')}\n${close}}`;
}

// Порядок сцен: по нему собирается крыло из комнат (tools/world-builder.mjs).
const order = (story.nodes ?? []).map((n) => n.id);

const lua = `--!strict
-- СГЕНЕРИРОВАНО tools/build-story.mjs из story/story.json — не редактировать руками.
-- Сюжет: «${story.meta?.title}» (${stats.nodes} сцен, ${stats.endings} концовки)

local StoryData = ${toLua(story, 0)}

StoryData.order = {${order.map((id) => `"${id}"`).join(', ')}}

return StoryData
`;
fs.mkdirSync(path.dirname(LUAU_PATH), { recursive: true });
fs.writeFileSync(LUAU_PATH, lua, 'utf8');

console.log(`  → ${path.relative(ROOT, LUAU_PATH)}`);
console.log(`  → ${path.relative(ROOT, DOC_PATH)}\n`);

process.exit(ok ? 0 : 1);
