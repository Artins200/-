--!nonstrict
-- StoryEngine — чистая логика сюжета: флаги, предметы, проверки, концовки.
-- Ничего не знает про UI и Roblox-сервисы, поэтому работает и на сервере, и в тестах.
--
-- local engine = StoryEngine.new(StoryData)
-- local view = engine:current()
-- engine:choose(2)

local StoryEngine = {}
StoryEngine.__index = StoryEngine

local function copy(t)
	local out = {}
	for k, v in pairs(t or {}) do
		out[k] = if type(v) == "table" then copy(v) else v
	end
	return out
end

function StoryEngine.new(storyData, savedState)
	assert(storyData and storyData.meta and storyData.nodes, "StoryEngine: нужен StoryData с meta и nodes")

	local self = setmetatable({}, StoryEngine)
	self.data = storyData
	self.nodes = {}
	for _, node in ipairs(storyData.nodes) do
		self.nodes[node.id] = node
	end

	self.state = {
		nodeId = storyData.meta.start,
		flags = {},
		items = {},
		visited = {},
		history = {},
		ending = nil,
	}

	if savedState then
		for _, key in ipairs({ "nodeId", "flags", "items", "visited", "ending" }) do
			local value = savedState[key]
			if value ~= nil then
				-- nodeId и ending — строки, flags/items/visited — таблицы
				self.state[key] = if type(value) == "table" then copy(value) else value
			end
		end
		if not self.nodes[self.state.nodeId] then
			self.state.nodeId = storyData.meta.start
		end
	end

	return self
end

-- Сцена по id (без аргумента — текущая). Полезно для тестов и редактора.
function StoryEngine:node(id)
	return self.nodes[id or self.state.nodeId]
end

function StoryEngine:hasFlag(flag)
	return self.state.flags[flag] == true
end

function StoryEngine:hasItem(item)
	return self.state.items[item] ~= nil
end

--- Проверяет условие вида { flags = {...}, notFlags = {...}, items = {...} }
function StoryEngine:check(requires)
	if requires == nil then
		return true, nil
	end
	if requires.flags then
		for _, flag in ipairs(requires.flags) do
			if not self:hasFlag(flag) then
				return false, "нужно: " .. (self.data.flags[flag] and self.data.flags[flag].label or flag)
			end
		end
	end
	if requires.notFlags then
		for _, flag in ipairs(requires.notFlags) do
			if self:hasFlag(flag) then
				return false, "уже известно"
			end
		end
	end
	if requires.items then
		for _, item in ipairs(requires.items) do
			if not self:hasItem(item) then
				return false, "нужно: " .. (self.data.items[item] and self.data.items[item].name or item)
			end
		end
	end
	return true, nil
end

--- Первый подходящий вариант текста сцены (по флагам) или базовый текст.
function StoryEngine:resolveText(node)
	for _, variant in ipairs(node.variants or {}) do
		if self:check(variant.requires) then
			return variant.text
		end
	end
	return node.text
end

--- Подставляет названия предметов: "... $keycard ..." -> "Ключ-карта смены 9"
function StoryEngine:interpolate(text)
	if not text then
		return ""
	end
	return (text:gsub("%$(%w+)", function(key)
		local item = self.data.items[key]
		return if item then item.name else "$" .. key
	end))
end

function StoryEngine:applyEffects(effects)
	if not effects then
		return
	end
	for flag, value in pairs(effects.set or {}) do
		self.state.flags[flag] = value and true or false
	end
	for _, item in ipairs(effects.give or {}) do
		if self.data.items[item] then
			self.state.items[item] = true
		end
	end
end

function StoryEngine:enter(nodeId)
	local node = self.nodes[nodeId]
	if not node then
		error("StoryEngine: нет сцены «" .. tostring(nodeId) .. "»")
	end
	self.state.nodeId = nodeId
	self.state.visited[nodeId] = true
	self:applyEffects(node.onEnter)
	if node.ending then
		self.state.ending = node.ending
	end
end

--- Данные для отрисовки текущей сцены.
--- showLocked = true — показывать закрытые выборы серым (по умолчанию false).
function StoryEngine:current(showLocked)
	local node = self.nodes[self.state.nodeId]
	local speaker = self.data.characters[node.speaker] or self.data.characters.narrator or { name = "", color = "#ffffff" }

	local view = {
		id = node.id,
		act = node.act or 1,
		scene = node.scene or "",
		speaker = speaker.name or "",
		color = speaker.color or "#ffffff",
		text = self:interpolate(self:resolveText(node)),
		choices = {},
		isEnding = node.ending ~= nil,
	}

	if node.ending then
		local ending = self.data.endings[node.ending]
		view.ending = {
			id = node.ending,
			title = ending.title,
			type = ending.type,
			summary = ending.summary,
			text = self:interpolate(ending.text),
		}
		return view
	end

	for index, choice in ipairs(node.choices or {}) do
		local ok, reason = self:check(choice.requires)
		if ok or showLocked then
			table.insert(view.choices, {
				index = index,
				text = choice.text,
				available = ok,
				reason = reason,
			})
		end
	end

	return view
end

--- Выбор игрока. index — номер выбора В СЦЕНЕ (как в story.json), а не в отфильтрованном списке.
function StoryEngine:choose(index)
	local node = self.nodes[self.state.nodeId]
	local choice = (node.choices or {})[index]
	if not choice then
		return false, "нет такого выбора"
	end

	local ok, reason = self:check(choice.requires)
	if not ok then
		return false, reason
	end

	table.insert(self.state.history, {
		from = self.state.nodeId,
		choice = choice.text,
	})
	self:applyEffects(choice)

	if choice.goto then
		self:enter(choice.goto)
	end

	return true, self:current()
end

function StoryEngine:serialize()
	return {
		nodeId = self.state.nodeId,
		flags = copy(self.state.flags),
		items = copy(self.state.items),
		visited = copy(self.state.visited),
		ending = self.state.ending,
	}
end

function StoryEngine:restart()
	self.state = {
		nodeId = self.data.meta.start,
		flags = {},
		items = {},
		visited = {},
		history = {},
		ending = nil,
	}
	self:enter(self.data.meta.start)
end

--- Короткая сводка для отладки/DataStore.
function StoryEngine:progress()
	local visited, total = 0, 0
	for _ in pairs(self.nodes) do
		total += 1
		if self.state.visited[_] then
			visited += 1
		end
	end
	return {
		visited = visited,
		total = total,
		ending = self.state.ending,
		flags = self.state.flags,
		items = self.state.items,
	}
end

return StoryEngine
