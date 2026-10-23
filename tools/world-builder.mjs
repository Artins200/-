#!/usr/bin/env node
// world-builder.mjs — собирает «крыло сюжета» из настоящих моделей карты.
//
// Как это делалось в самом плейсе: комната (модель Room) = одна сцена, внутри
// стоят модели персонажей, между комнатами — папка "Teleport One Way"
// (TeleportPart1 → TeleportPart2, скрипт Ignore). Здесь то же самое, только
// комнаты выстроены по порядку сцен, а персонаж сцены скопирован из карты.
//
// Модуль работает с dom rbx-dom и ничего не пишет на диск.

const FLOOR = 0.2;

/** Габариты модели по частям с CFrame и Size. */
export function measure(dom, ref) {
	const box = { x: [Infinity, -Infinity], y: [Infinity, -Infinity], z: [Infinity, -Infinity] };
	const all = [dom.instance(ref), ...dom.descendants(ref)].filter(Boolean);
	for (const inst of all) {
		const cf = inst.properties?.CFrame?.CFrame;
		const size = inst.properties?.Size?.Vector3;
		if (!cf || !size) continue;
		for (let i = 0; i < 3; i++) {
			const key = ['x', 'y', 'z'][i];
			box[key][0] = Math.min(box[key][0], cf.position[i] - size[i] / 2);
			box[key][1] = Math.max(box[key][1], cf.position[i] + size[i] / 2);
		}
	}
	return box;
}

const rad = (deg) => (deg * Math.PI) / 180;

/** Поворот вокруг Y: R_y = [[cos,0,sin],[0,1,0],[-sin,0,cos]]. */
function rotateY(p, pivot, angle) {
	const c = Math.cos(angle);
	const s = Math.sin(angle);
	const dx = p[0] - pivot[0];
	const dz = p[2] - pivot[2];
	return [pivot[0] + dx * c + dz * s, p[1], pivot[2] - dx * s + dz * c];
}

function mulY(orientation, angle) {
	const c = Math.cos(angle);
	const s = Math.sin(angle);
	const R = [
		[c, 0, s],
		[0, 1, 0],
		[-s, 0, c],
	];
	return R.map((row, i) => row.map((_, j) => row[0] * orientation[0][j] + row[1] * orientation[1][j] + row[2] * orientation[2][j]));
}

/** Сдвиг + поворот всей модели вокруг точки pivot. */
export function place(dom, ref, { pivot, delta = [0, 0, 0], rotY = 0 }) {
	const all = [dom.instance(ref), ...dom.descendants(ref)].filter(Boolean);
	const angle = rad(rotY);
	let moved = 0;
	for (const inst of all) {
		const cf = inst.properties?.CFrame?.CFrame;
		if (!cf) continue;
		const p = rotateY(cf.position, pivot, angle);
		const orientation = rotY ? mulY(cf.orientation, angle) : cf.orientation;
		dom.setProperty(inst.referent, 'CFrame', {
			CFrame: {
				orientation,
				position: [p[0] + delta[0], p[1] + delta[1], p[2] + delta[2]],
			},
		});
		moved++;
	}
	return moved;
}

/** Ставит одиночную часть в точку с поворотом. */
export function placePart(dom, ref, position, rotY = 0) {
	const inst = dom.instance(ref);
	const cf = inst.properties?.CFrame?.CFrame;
	const orientation = cf?.orientation ?? [
		[1, 0, 0],
		[0, 1, 0],
		[0, 0, 1],
	];
	dom.setProperty(ref, 'CFrame', {
		CFrame: { orientation: rotY ? mulY(orientation, rad(rotY)) : orientation, position },
	});
}

function childrenOf(dom, ref) {
	return dom.children(ref).map((r) => dom.instance(r));
}

function hasHumanoid(dom, ref) {
	return dom.descendants(ref).some((d) => d.className === 'Humanoid');
}

/** Первая часть с SurfaceGui внутри — образец вывески этого плейса. */
function findSignPrototype(dom, wsRef) {
	const parts = dom.descendants(wsRef).filter((d) => d.className === 'Part');
	for (const part of parts) {
		const gui = childrenOf(dom, part.referent).find((c) => c.className === 'SurfaceGui');
		if (!gui) continue;
		const label = dom.descendants(gui.referent).find((d) => d.className === 'TextLabel');
		if (label) return part.referent;
	}
	return null;
}

function findTeleportPrototype(dom, wsRef) {
	const folders = childrenOf(dom, wsRef).filter((i) => i.className === 'Folder' && /teleport/i.test(i.name));
	for (const folder of folders) {
		const kids = childrenOf(dom, folder.referent);
		const p1 = kids.find((k) => k.name === 'TeleportPart1');
		const p2 = kids.find((k) => k.name === 'TeleportPart2');
		if (p1 && p2) return folder.referent;
	}
	return null;
}

/** Модели персонажей карты: имя → referent первой подходящей модели. */
function collectCharacters(dom, wsRef) {
	const byName = new Map();
	for (const inst of dom.descendants(wsRef)) {
		if (inst.className !== 'Model') continue;
		if (!hasHumanoid(dom, inst.referent)) continue;
		const name = (inst.name ?? '').trim();
		if (!name || name === 'Room') continue;
		if (!byName.has(name)) byName.set(name, inst.referent);
	}
	return byName;
}

function setSignText(dom, signRef, text, width) {
	// Подпись и текст на самой вывеске: так же, как на 225 вывесках карты.
	if (width) {
		const size = dom.instance(signRef).properties?.Size?.Vector3;
		if (size) dom.setProperty(signRef, 'Size', { Vector3: [width, width * 0.52, 0.35] });
	}
	const gui = childrenOf(dom, signRef).find((c) => c.className === 'SurfaceGui');
	if (!gui) return false;
	dom.setProperty(gui.referent, 'Enabled', { Bool: true });
	dom.setProperty(gui.referent, 'LightInfluence', { Float32: 0 });
	dom.setProperty(gui.referent, 'Brightness', { Float32: 2 });
	const label = dom.descendants(gui.referent).find((d) => d.className === 'TextLabel');
	if (!label) return false;
	const props = label.properties ?? {};
	if (props.TextScaled) dom.setProperty(label.referent, 'TextScaled', { Bool: true });
	if (props.TextWrapped) dom.setProperty(label.referent, 'TextWrapped', { Bool: true });
	dom.setProperty(label.referent, 'TextColor3', { Color3: [1, 1, 1] });
	dom.setProperty(label.referent, 'BackgroundTransparency', { Float32: 0.35 });
	dom.setProperty(label.referent, 'BackgroundColor3', { Color3: [0.03, 0.04, 0.06] });
	dom.setProperty(label.referent, 'Text', { String: text });
	return true;
}

/** Угол поворота (градусы), при котором модель смотрит из from в to.
 *  В Roblox при rotY = 0 взгляд направлен в −Z, а поворот считается вокруг Y. */
export function yawTowards(from, to) {
	const dx = to[0] - from[0];
	const dz = to[1] - from[1];
	if (dx === 0 && dz === 0) return 0;
	return (Math.atan2(-dx, -dz) * 180) / Math.PI;
}

/** Портал из плейса, но открывается только когда сцена доиграна. */
const GATED_PORTAL = `local a = script.Parent.TeleportPart1
local b = script.Parent.TeleportPart2
local open = script.Parent:FindFirstChild("Open")

a.Touched:Connect(function(hit)
	local w = hit.Parent and hit.Parent:FindFirstChild("HumanoidRootPart")
	if not w then
		return
	end
	if open and not open.Value then
		return
	end
	w.CFrame = b.CFrame + Vector3.new(0, 5, 0)
end)
`;

function gatePortal(dom, folderRef, open) {
	const kids = childrenOf(dom, folderRef);
	const script = kids.find((k) => k.className === 'Script');
	if (script) dom.setProperty(script.referent, 'Source', { String: GATED_PORTAL });
	let flag = kids.find((k) => k.className === 'BoolValue');
	if (!flag) {
		const ref = dom.insert(folderRef, { className: 'BoolValue', name: 'Open' });
		dom.setProperty(ref, 'Value', { Bool: open });
		flag = dom.instance(ref);
	}
	dom.setProperty(flag.referent, 'Value', { Bool: open });
}

/** Красит все части модели в цвет персонажа, чтобы копии не были близнецами. */
function tint(dom, ref, color) {
	if (!color) return 0;
	const PARTS = new Set(['Part', 'MeshPart', 'UnionOperation', 'WedgePart', 'TrussPart', 'CornerWedgePart', 'Seat', 'SpawnLocation']);
	let n = 0;
	for (const inst of [dom.instance(ref), ...dom.descendants(ref)]) {
		if (!inst || !PARTS.has(inst.className)) continue;
		if (!inst.properties?.Color) continue;
		dom.setProperty(inst.referent, 'Color', { Color3: color });
		n++;
	}
	return n;
}

/** Плоская часть-метка: так игрок видит, куда идти, без всякого интерфейса. */
function makePart(dom, parent, name, position, size, color, transparency = 0) {
	const ref = dom.insert(parent, {
		className: 'Part',
		name,
		properties: {
			Anchored: { Bool: true },
			CanCollide: { Bool: false },
			CanQuery: { Bool: false },
			CastShadow: { Bool: false },
			Material: { Enum: 288 }, // Neon, как у телепортов в этом плейсе
			Color: { Color3: color },
			Transparency: { Float32: transparency },
			Size: { Vector3: size },
		},
	});
	placePart(dom, ref, position);
	return ref;
}

/**
 * Строит крыло сюжета: по комнате на сцену, персонаж вперёд, вывеска с текстом,
 * портал в следующую комнату. Последний портал уводит в следующую локацию.
 */
export function buildWing(dom, story, options = {}) {
	const wsRef = dom.children(dom.rootRef).map((r) => dom.instance(r)).find((i) => i.className === 'Workspace')?.referent;
	if (!wsRef) throw new Error('в файле нет Workspace');

	const roomProto = dom.descendants(wsRef).find((d) => d.className === 'Model' && d.name === 'Room');
	if (!roomProto) throw new Error('в файле нет модели Room');
	const signProto = findSignPrototype(dom, wsRef);
	if (!signProto) throw new Error('в файле нет вывески с SurfaceGui');
	const teleportProto = findTeleportPrototype(dom, wsRef);
	if (!teleportProto) throw new Error('в файле нет папки «Teleport One Way»');
	const characters = collectCharacters(dom, wsRef);
	if (!characters.size) throw new Error('в файле нет моделей персонажей с Humanoid');

	const box = measure(dom, roomProto.referent);
	const roomCenter = [(box.x[0] + box.x[1]) / 2, (box.z[0] + box.z[1]) / 2];
	const roomWidth = box.x[1] - box.x[0];

	const wing = dom.insert(wsRef, { className: 'Folder', name: 'StoryWing' });

	const STEP = options.step ?? roomWidth + 14; // между комнатами щель: пешком не перейти
	const BASE_X = options.baseX ?? 620;
	const BASE_Z = options.baseZ ?? -1500;
	const SIGN_W = 12;

	const order = (story.nodes ?? []).map((n) => n.id);
	const byId = Object.fromEntries((story.nodes ?? []).map((n) => [n.id, n]));
	const characterName = (key) => story.characters?.[key]?.name ?? '';

	// Кого ставить в сцену: говорившего, иначе героя.
	const fallback = characters.get('Артём') ?? [...characters.values()][0];
	function characterFor(node) {
		const name = characterName(node.speaker);
		if (name && characters.has(name)) return { ref: characters.get(name), name };
		if (name && characters.has(name.toLowerCase())) return { ref: characters.get(name.toLowerCase()), name };
		return { ref: fallback, name: name || 'Артём' };
	}

	const scenes = [];
	const removed = { characters: 0, parts: 0 };
	const poseName = (line) => line.pose || 'say';

	const SPEAKABLE = ['Артём', 'Артинс', 'Лира', 'Демид', 'Ваня', 'МАМА', 'Кай Вэрн', 'Некит', 'Богдан', 'Карина', 'Ярик'];

	/** Второй участник сцены: следующий, кто заговорит дальше по сюжету. */
	function partnerFor(id, exclude) {
		const start = orderOf(id);
		for (let step = 1; step <= 6; step++) {
			const node = (story.nodes ?? [])[start + step];
			if (!node) break;
			for (const line of node.lines ?? []) {
				const name = characterName(line.s);
				if (name && name !== exclude && SPEAKABLE.includes(name)) return name;
			}
		}
		return exclude === 'Артём' ? 'Артинс' : 'Артём';
	}

	const orderOf = (id) => (story.nodes ?? []).findIndex((n) => n.id === id);

	// Кто играет сцену: все, кто говорит в репликах, без повторов.
	function actorsOf(node) {
		const names = [];
		for (const line of node.lines ?? []) {
			const name = characterName(line.s);
			const key = name && characters.has(name) ? name : name;
			if (!key) continue;
			if (key === 'Артём' || key === 'Артинс' || key === 'Лира' || key === 'Демид' || key === 'Ваня'
				|| key === 'МАМА' || key === 'Кай Вэрн' || key === 'Некит' || key === 'Богдан' || key === 'Карина' || key === 'Ярик') {
				if (!names.includes(key)) names.push(key);
			}
		}
		if (!names.length) names.push('Артём');
		// В комнате всегда двое: если говорит один, второй стоит рядом и слушает.
		if (names.length === 1) {
			const partner = partnerFor(node.id, names[0]);
			if (partner) names.push(partner);
		}
		return names.slice(0, 3);
	}

	order.forEach((id, index) => {
		const node = byId[id];
		const cx = BASE_X - index * STEP;
		const cz = BASE_Z;
		const delta = [cx - roomCenter[0], 0, cz - roomCenter[1]];

		// 1. Копия комнаты — ровно как в плейсе.
		const roomRef = dom.cloneWithin(roomProto.referent);
		dom.transferWithin(roomRef, wing);
		place(dom, roomRef, { pivot: [0, 0, 0], delta });
		dom.setName(roomRef, `Scene_${id}`);

		// 2. Убираем фигурки, которые были в комнате-образце: в сцене будет свой состав.
		for (const child of childrenOf(dom, roomRef)) {
			if (child.className === 'Model' && hasHumanoid(dom, child.referent)) {
				dom.destroy(child.referent);
				removed.characters++;
			}
		}

		const floor = box.y[0] + FLOOR;

		// 3. Актёры сцены: копии моделей с карты, лицом друг к другу.
		const actors = [];
		const names = actorsOf(node);
		// Сцена как на подмостках: актёры по краям, между ними вывеска,
		// все трое развёрнуты к игроку, который входит слева по −X.
		const spots = [
			[4.5, -6.6, 110],
			[4.5, 6.6, 70],
			[9.5, -10.4, 100],
		];
		names.forEach((name, seat) => {
			const pick = characterFor({ speaker: Object.keys(story.characters ?? {}).find((k) => characterName(k) === name) ?? node.speaker });
			const charRef = dom.cloneWithin(pick.ref);
			dom.transferWithin(charRef, roomRef);
			dom.setName(charRef, name);
			const charBox = measure(dom, charRef);
			const center = [(charBox.x[0] + charBox.x[1]) / 2, (charBox.z[0] + charBox.z[1]) / 2];
			const [offset, offsetZ, facing] = spots[seat] ?? [4.5, 0, 90];
			// Модели персонажей на карте уже стоят повёрнутыми на −90°, компенсируем.
			const MODEL_BASE_YAW = 90;
			place(dom, charRef, {
				pivot: [center[0], charBox.y[0], center[1]],
				delta: [cx + offset - center[0], floor - charBox.y[0], cz + offsetZ - center[1]],
				rotY: facing + MODEL_BASE_YAW,
			});
			const palette = {
				'Артём': [0.55, 0.72, 0.95],
				'Артинс': [0.98, 0.55, 0.15],
				'Лира': [0.95, 0.55, 0.75],
				'МАМА': [0.72, 0.9, 0.35],
				'Кай Вэрн': [0.98, 0.8, 0.3],
				'Демид': [0.3, 0.7, 0.95],
				'Ваня': [0.95, 0.35, 0.35],
				'Некит': [0.95, 0.3, 0.45],
				'Богдан': [0.92, 0.7, 0.2],
				'Карина': [0.9, 0.4, 0.7],
				'Ярик': [0.2, 0.85, 0.85],
			};
			tint(dom, charRef, palette[name]);
			actors.push({ name, at: [cx + offset, floor, cz + offsetZ], facing: Math.round(facing * 10) / 10 });
		});
		const pick = { name: names[0] };

		// 4. Вывеска с текстом сцены — копия вывески этого плейса.
		const signRef = dom.cloneWithin(signProto);
		dom.transferWithin(signRef, roomRef);
		dom.setName(signRef, 'Sign');
		const speaker = characterName(node.speaker);
		const firstLine = (node.lines ?? [])[0];
		const label = firstLine ? firstLine.t : node.text ?? '';
		setSignText(dom, signRef, label, SIGN_W);
		dom.setProperty(signRef, 'CanCollide', { Bool: false });
		dom.setProperty(signRef, 'CanTouch', { Bool: false });
		// Вывеска — экран на дальней стороне комнаты, лицом к входящему игроку.
		// У вывески текст на передней грани (−Z), поэтому поворот 180° к игроку.
		placePart(dom, signRef, [cx + 8, floor + 3.4, cz], 180);

		// 5. Метка входа и метка портала — части в стиле телепортов.
		const arrival = makePart(dom, roomRef, 'Arrival', [cx - 15, floor + 1.2, cz], [6, 0.6, 6], [0.49, 0.83, 0.99], 0.35);
		void arrival;
		makePart(dom, roomRef, 'Exit', [cx + 16, floor + 0.4, cz], [6, 0.6, 6], [0.98, 0.45, 0.09], 0.4);

		scenes.push({
			id,
			index,
			act: node.act ?? 1,
			scene: node.scene ?? '',
			speaker: speaker || pick.name,
			room: `Scene_${id}`,
			character: names[0],
			actors,
			lines: (node.lines ?? []).map((line) => ({
				s: characterName(line.s),
				t: line.t,
				pose: poseName(line),
			})),
			sign: [cx + 8, floor + 3.3, cz],
			arrival: [cx - 15, floor + 3.2, cz],
			exit: [cx + 16, floor + 0.4, cz],
			center: [cx, floor, cz],
		});
	});

	// 5.1 Пол под всей линией: комнаты стоят вплотную по X, между ними щель,
	// поэтому под крылом идёт сплошная плита — с неё нельзя провалиться.
	const firstX = scenes[0].center[0];
	const lastX = scenes[scenes.length - 1].center[0];
	const floorWidth = Math.abs(firstX - lastX) + roomWidth * 2;
	const floorY = box.y[0] + FLOOR;
	const platform = makePart(dom, wing, 'Floor', [(firstX + lastX) / 2, floorY - 0.5, BASE_Z], [floorWidth, 1, 46], [0.22, 0.24, 0.28]);
	dom.setProperty(platform, 'Material', { Enum: 816 }); // Concrete
	dom.setProperty(platform, 'CanCollide', { Bool: true });
	dom.setProperty(platform, 'CanTouch', { Bool: true });
	dom.setProperty(platform, 'Transparency', { Float32: 0 });

	// Точка появления в первой комнате: респавн не выбрасывает на карту.
	const spawnPart = dom.insert(wing, {
		className: 'SpawnLocation',
		name: 'StorySpawn',
		properties: {
			Anchored: { Bool: true },
			CanCollide: { Bool: true },
			Neutral: { Bool: true },
			Duration: { Int32: 0 },
			Transparency: { Float32: 0.4 },
			Color: { Color3: [0.49, 0.83, 0.99] },
			Size: { Vector3: [6, 0.6, 6] },
		},
	});
	// Появление — чуть раньше входа в первую комнату и лицом к вывеске (+X).
	const entry = scenes[0].arrival;
	placePart(dom, spawnPart, [entry[0] - 6, entry[1], entry[2]], -90);

	// 6. Портал из каждой комнаты в следующую — папка "Teleport One Way" как в плейсе.
	const portals = [];
	for (let i = 0; i < scenes.length - 1; i++) {
		const from = scenes[i];
		const to = scenes[i + 1];
		const folderRef = dom.cloneWithin(teleportProto);
		dom.transferWithin(folderRef, wing);
		dom.setName(folderRef, `Portal_${from.id}`);
		const kids = childrenOf(dom, folderRef);
		const p1 = kids.find((k) => k.name === 'TeleportPart1');
		const p2 = kids.find((k) => k.name === 'TeleportPart2');
		placePart(dom, p1.referent, from.exit);
		placePart(dom, p2.referent, [to.arrival[0], to.arrival[1] - 3.2, to.arrival[2]]);
		gatePortal(dom, folderRef, false);
		portals.push({ id: `Portal_${from.id}`, from: from.exit, to: to.arrival, next: to.id });
	}

	// 7. Портал после финальной главы — в следующую локацию.
	const last = scenes[scenes.length - 1];
	const nextLocation = options.nextLocation ?? reportNextLocation(story);
	const finalRef = dom.cloneWithin(teleportProto);
	dom.transferWithin(finalRef, wing);
	dom.setName(finalRef, 'Portal_Final');
	{
		const kids = childrenOf(dom, finalRef);
		const p1 = kids.find((k) => k.name === 'TeleportPart1');
		const p2 = kids.find((k) => k.name === 'TeleportPart2');
		placePart(dom, p1.referent, [last.exit[0] + 10, last.exit[1], last.exit[2]]);
		placePart(dom, p2.referent, nextLocation);
		gatePortal(dom, finalRef, false);
		portals.push({ id: 'Portal_Final', from: [last.exit[0] + 10, last.exit[1], last.exit[2]], to: nextLocation, next: null });
	}

	return {
		wing,
		folderName: 'StoryWing',
		base: { x: BASE_X, z: BASE_Z, step: STEP, roomWidth },
		floor: box.y[0] + FLOOR,
		scenes,
		portals,
		nextLocation,
		removed,
		spawn: scenes[0].arrival,
		characterCount: characters.size,
	};
}

/** Следующая локация: огненная арена финала из meta.map. */
function reportNextLocation(story) {
	const arena = story.meta?.map?.arena;
	if (arena?.fire) return [arena.fire[0], arena.fire[1] + 4, arena.fire[2]];
	if (arena?.center) return [arena.center[0], arena.center[1] + 4, arena.center[2]];
	return [0, 10, 0];
}
