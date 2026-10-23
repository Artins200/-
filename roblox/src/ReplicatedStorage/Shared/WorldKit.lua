--!nonstrict
-- WorldKit — раскладка сюжета по настоящей карте.
--
-- Сцены в story.json идут в порядке прохождения. Акты привязаны к кластерам
-- из game/layout.json (координаты сняты с neirogh.rbxl). WorldKit превращает
-- порядок сцен в маршрут по миру: у каждой сцены появляется точка, куда игрок
-- должен дойти, и, если повезло, живой НПС, который эту сцену отыгрывает.
--
-- Модуль чистый: ни Workspace, ни Players. Поэтому его гоняют тесты.

local WorldKit = {}
WorldKit.__index = WorldKit

-- Радиусы подобраны по карте: коридор вывесок шириной ~10 юнитов.
WorldKit.REACH = 14 -- насколько близко нужно подойти, чтобы сцена «случилась»
WorldKit.TALK = 20 -- радиус разговора с НПС
WorldKit.NPC_PULL = 600 -- насколько далеко можно подвинуть точку сцены к НПС
WorldKit.LIFT = 3.2 -- на сколько поднять маркер над полом

-- Если в story.meta.map.route ничего нет, маршрут строится по этим зонам.
WorldKit.DEFAULT_ROUTE = {
	{ act = 1, zone = "spawn" },
	{ act = 1, zone = "z3_c6" },
	{ act = 2, zone = "z1_c4" },
	{ act = 2, zone = "z0_c0" },
	{ act = 3, zone = "z0_c2" },
	{ act = 3, zone = "z0_c3" },
	{ act = 4, zone = "z4_c8" },
	{ act = 4, zone = "z4_c7" },
}

local function len(a, b)
	local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function lerp(a, b, t)
	return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

-- Точка на ломаной по параметру 0..1 (по длине, а не по числу отрезков).
local function along(points, t)
	if #points == 0 then
		return nil
	end
	if #points == 1 then
		return points[1]
	end
	local total = 0
	for i = 2, #points do
		total += len(points[i - 1], points[i])
	end
	if total == 0 then
		return points[1]
	end
	local want = math.clamp(t, 0, 1) * total
	local walked = 0
	for i = 2, #points do
		local seg = len(points[i - 1], points[i])
		if walked + seg >= want then
			return lerp(points[i - 1], points[i], (want - walked) / seg)
		end
		walked += seg
	end
	return points[#points]
end

function WorldKit.new(story)
	assert(story and story.nodes, "WorldKit: нужен StoryData")

	local self = setmetatable({}, WorldKit)
	self.story = story
	self.world = story.world or {}
	self.nodes = {}
	for _, node in ipairs(story.nodes) do
		self.nodes[node.id] = node
	end

	self.byId = {}
	for _, cluster in ipairs(self.world.clusters or {}) do
		self.byId[cluster.id] = cluster
	end

	self.plan = self:_buildPlan()
	return self
end

-- Маршрут: какие зоны проходит каждый акт.
function WorldKit:route()
	if self._route then
		return self._route
	end
	local spec = self.story.meta and self.story.meta.map and self.story.meta.map.route
	if type(spec) ~= "table" or #spec == 0 then
		spec = WorldKit.DEFAULT_ROUTE
	end
	local out = {}
	for _, step in ipairs(spec) do
		local pos
		if step.zone == "spawn" or step.zone == "start" then
			pos = self.world.spawn
		else
			local cluster = self.byId[step.zone]
			pos = cluster and cluster.center
		end
		if pos then
			table.insert(out, { act = step.act or 1, zone = step.zone, pos = { pos[1], pos[2], pos[3] } })
		end
	end
	self._route = out
	return out
end

-- Имя персонажа для поиска на карте: ключ спикера → русское имя из characters.
function WorldKit:speakerName(key)
	local cast = self.story.characters and self.story.characters[key]
	if cast and cast.name and cast.name ~= "" then
		return cast.name
	end
	return key
end

-- Ближайший живой НПС с таким именем к точке (или nil).
function WorldKit:findNpc(name, near)
	if not name or name == "" then
		return nil
	end
	name = self:speakerName(name)
	local best, bestDist = nil, WorldKit.NPC_PULL
	for _, npc in ipairs(self.world.cast or {}) do
		if npc.name == name and npc.pos then
			local d = len(npc.pos, near)
			if d < bestDist then
				best, bestDist = npc, d
			end
		end
	end
	return best
end

-- Раскладка всех сцен по точкам мира.
function WorldKit:_buildPlan()
	local route = self:route()
	local byAct = {}
	for _, step in ipairs(route) do
		byAct[step.act] = byAct[step.act] or {}
		table.insert(byAct[step.act], step)
	end

	-- Сначала считаем, сколько сцен в каждом акте.
	local perAct, seenAct = {}, {}
	local order = self.story.order or {}
	for _, id in ipairs(order) do
		local node = self.nodes[id]
		if node then
			local act = node.act or 1
			perAct[act] = (perAct[act] or 0) + 1
		end
	end

	local plan = {}
	for _, id in ipairs(order) do
		local node = self.nodes[id]
		if node then
			local act = node.act or 1
			seenAct[act] = (seenAct[act] or 0) + 1
			local points = {}
			for _, step in ipairs(byAct[act] or route) do
				table.insert(points, step.pos)
			end
			local count = perAct[act] or 1
			local t = if count <= 1 then 0 else (seenAct[act] - 1) / (count - 1)
			local pos = along(points, t) or self.world.spawn or { 0, 0, 0 }

			local entry = {
				id = id,
				act = act,
				zone = (byAct[act] or route)[1] and (byAct[act] or route)[1].zone or "spawn",
				pos = { pos[1], pos[2] + WorldKit.LIFT, pos[3] },
				base = pos,
			}

			-- Если в сцене говорит живой персонаж с карты — ставим сцену у него.
			local npc = self:findNpc(node.speaker, pos)
			if npc then
				entry.npc = npc.name
				entry.npcPos = npc.pos
				entry.pos = { npc.pos[1], npc.pos[2] + 2.5, npc.pos[3] }
			end
			plan[id] = entry
		end
	end
	return plan
end

-- Точка сцены (или nil, если сцены нет в плане).
function WorldKit:point(sceneId)
	return self.plan[sceneId]
end

-- Сколько идти от позиции игрока до точки сцены.
function WorldKit:distanceTo(sceneId, position)
	local entry = self.plan[sceneId]
	if not entry or not position then
		return nil
	end
	return len(entry.pos, { position.X or position[1], position.Y or position[2], position.Z or position[3] })
end

-- Автопереход: сцена с единственным выбором без условий проходится сама,
-- как только игрок дошёл. Возвращает номер выбора или nil.
function WorldKit:autoChoice(sceneId)
	local node = self.nodes[sceneId]
	if not node or type(node.choices) ~= "table" or #node.choices ~= 1 then
		return nil
	end
	local choice = node.choices[1]
	if choice.requires then
		return nil
	end
	return 1
end

-- Куда идти дальше: точка следующей сцены по текущему выбору.
function WorldKit:nextPoint(sceneId, choiceIndex)
	local node = self.nodes[sceneId]
	if not node or type(node.choices) ~= "table" then
		return nil
	end
	local choice = node.choices[choiceIndex or 1]
	if not choice or not choice.goto then
		return nil
	end
	return self.plan[choice.goto]
end

-- Группы маршрута по актам — для интерфейса и проверок.
function WorldKit:stages()
	local stages = {}
	for _, step in ipairs(self:route()) do
		local last = stages[#stages]
		if not last or last.act ~= step.act then
			table.insert(stages, { act = step.act, from = step.zone, to = step.zone, pos = step.pos })
		else
			last.to = step.zone
		end
	end
	return stages
end

-- Все НПС, которых сюжет действительно задействовал.
function WorldKit:usedCast()
	local used, list = {}, {}
	for _, id in ipairs(self.story.order or {}) do
		local node = self.nodes[id]
		local name = node and node.speaker
		if name and not used[name] then
			used[name] = true
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

return WorldKit
