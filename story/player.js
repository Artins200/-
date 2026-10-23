/**
 * player.js — те же правила сюжета, что в StoryEngine.lua, но на JS.
 * Нужен, чтобы читать и проверять историю без Roblox Studio.
 * Используется story/preview.html и tools/test-story-player.mjs.
 */

export class StoryPlayer {
  constructor(story, savedState) {
    this.data = story;
    this.nodes = new Map(story.nodes.map((node) => [node.id, node]));
    this.state = {
      nodeId: story.meta.start,
      flags: {},
      items: {},
      visited: {},
      history: [],
      ending: null,
    };
    if (savedState) {
      for (const key of ['nodeId', 'flags', 'items', 'visited', 'ending']) {
        if (savedState[key] !== undefined) this.state[key] = structuredClone(savedState[key]);
      }
      if (!this.nodes.has(this.state.nodeId)) this.state.nodeId = story.meta.start;
    }
  }

  node(id) {
    return this.nodes.get(id ?? this.state.nodeId);
  }

  hasFlag(flag) {
    return this.state.flags[flag] === true;
  }

  hasItem(item) {
    return this.state.items[item] != null;
  }

  /** @returns {[boolean, string|null]} */
  check(requires) {
    if (!requires) return [true, null];
    for (const flag of requires.flags ?? []) {
      if (!this.hasFlag(flag)) {
        return [false, 'нужно: ' + (this.data.flags?.[flag]?.label ?? flag)];
      }
    }
    for (const flag of requires.notFlags ?? []) {
      if (this.hasFlag(flag)) return [false, 'уже известно'];
    }
    for (const item of requires.items ?? []) {
      if (!this.hasItem(item)) {
        return [false, 'нужно: ' + (this.data.items?.[item]?.name ?? item)];
      }
    }
    return [true, null];
  }

  resolveText(node) {
    for (const variant of node.variants ?? []) {
      if (this.check(variant.requires)[0]) return variant.text;
    }
    return node.text;
  }

  interpolate(text) {
    return String(text ?? '').replace(/\$(\w+)/g, (whole, key) => this.data.items?.[key]?.name ?? whole);
  }

  applyEffects(effects) {
    if (!effects) return;
    for (const [flag, value] of Object.entries(effects.set ?? {})) {
      this.state.flags[flag] = Boolean(value);
    }
    for (const item of effects.give ?? []) {
      if (this.data.items?.[item]) this.state.items[item] = true;
    }
  }

  enter(nodeId) {
    const node = this.nodes.get(nodeId);
    if (!node) throw new Error(`Нет сцены «${nodeId}»`);
    this.state.nodeId = nodeId;
    this.state.visited[nodeId] = true;
    this.applyEffects(node.onEnter);
    if (node.ending) this.state.ending = node.ending;
  }

  current(showLocked = false) {
    const node = this.node();
    const speaker = this.data.characters?.[node.speaker] ?? { name: '', color: '#ffffff' };
    const view = {
      id: node.id,
      act: node.act ?? 1,
      chapter: node.chapter ?? '',
      scene: node.scene ?? '',
      speaker: speaker.name ?? '',
      color: speaker.color ?? '#ffffff',
      text: this.interpolate(this.resolveText(node)),
      // Короткие реплики сцены: кто говорит и что делает (поза — для игры).
      lines: (node.lines ?? []).map((line) => ({
        name: this.data.characters?.[line.s]?.name ?? '',
        text: this.interpolate(line.t ?? ''),
        pose: line.pose ?? 'say',
      })),
      choices: [],
      isEnding: Boolean(node.ending),
      animations: node.animations ?? [],
    };

    // Телепорт последней главы: координаты сняты с карты neirogh.rbxl.
    if (node.teleport) {
      const [ok, reason] = this.check(node.teleport.requires);
      view.teleport = {
        ...node.teleport,
        available: ok,
        reason: ok ? null : (reason ?? node.teleport.lockedText ?? 'закрыто'),
      };
    }

    if (node.ending) {
      const ending = this.data.endings[node.ending];
      view.ending = { id: node.ending, ...ending, text: this.interpolate(ending.text) };
      return view;
    }

    for (const [index, choice] of (node.choices ?? []).entries()) {
      const [ok, reason] = this.check(choice.requires);
      if (ok || showLocked) {
        view.choices.push({ index: index + 1, text: choice.text, available: ok, reason });
      }
    }
    return view;
  }

  choose(index) {
    const node = this.node();
    const choice = (node.choices ?? [])[index - 1];
    if (!choice) return [false, 'нет такого выбора'];
    const [ok, reason] = this.check(choice.requires);
    if (!ok) return [false, reason];

    this.state.history.push({ from: this.state.nodeId, choice: choice.text });
    this.applyEffects(choice);
    if (choice.goto) this.enter(choice.goto);
    return [true, this.current()];
  }

  serialize() {
    return structuredClone(this.state);
  }

  restart() {
    this.state = { nodeId: this.data.meta.start, flags: {}, items: {}, visited: {}, history: [], ending: null };
    this.enter(this.state.nodeId);
  }

  progress() {
    let visited = 0;
    for (const id of this.nodes.keys()) if (this.state.visited[id]) visited += 1;
    return { visited, total: this.nodes.size, ending: this.state.ending };
  }
}
