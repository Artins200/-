--!nonstrict
-- TeleportDirector — телепорт последней главы, собранный по координатам карты.
--
-- story.json хранит у сцены:
--   teleport = {
--     id = "fusion_last",
--     label = "Шагнуть в огонь",
--     zone = "fire_arena",
--     target = { -201.6, 3.2, 6.1 },  -- Vector3-компоненты, снятые с neirogh.rbxl
--     placeId = "114216327847140",    -- плейс, куда ведёт авторский гейт
--     requires = { items = { "plate" } },
--     animation = "warp",
--   }
--
-- Модуль ничего не двигает сам: он проверяет данные и говорит, что делать.
-- Двигать будет сервер (StoryServer), чтобы телепорт нельзя было подделать клиентом.

local TeleportDirector = {}

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

--- Проверить описание телепорта. Возвращает ok, reason.
function TeleportDirector.validate(definition)
	if type(definition) ~= "table" then
		return false, "нет описания телепорта"
	end
	local target = definition.target
	if type(target) ~= "table" or #target < 3 then
		return false, "не заданы координаты"
	end
	for i = 1, 3 do
		if not isFiniteNumber(target[i]) then
			return false, "координата " .. i .. " — не число"
		end
	end
	if math.abs(target[1]) > 100000 or math.abs(target[2]) > 100000 or math.abs(target[3]) > 100000 then
		return false, "координаты вне карты"
	end
	if definition.placeId ~= nil then
		if type(definition.placeId) ~= "string" or not definition.placeId:match("^%d+$") then
			return false, "placeId должен быть строкой из цифр"
		end
	end
	return true, nil
end

--- Доступен ли телепорт в текущем состоянии сюжета.
--- state — таблица вида { items = {...}, flags = {...} }.
function TeleportDirector.availability(definition, state)
	local ok, reason = TeleportDirector.validate(definition)
	if not ok then
		return false, reason
	end
	local requires = definition.requires or {}
	for _, item in ipairs(requires.items or {}) do
		if not (state and state.items and state.items[item]) then
			return false, definition.lockedText or ("нужно: " .. tostring(item))
		end
	end
	for _, flag in ipairs(requires.flags or {}) do
		if not (state and state.flags and state.flags[flag]) then
			return false, definition.lockedText or ("нужно: " .. tostring(flag))
		end
	end
	for _, flag in ipairs(requires.notFlags or {}) do
		if state and state.flags and state.flags[flag] then
			return false, definition.lockedText or "уже сделано"
		end
	end
	return true, nil
end

--- Координаты арены в виде таблицы + дистанция от точки появления.
--- Используется в отчётах и тестах: телепорт должен вести в реальную точку карты.
function TeleportDirector.describe(definition, spawn)
	local ok, reason = TeleportDirector.validate(definition)
	if not ok then
		return nil, reason
	end
	local t = definition.target
	local distance = nil
	if type(spawn) == "table" and #spawn >= 3 then
		local dx, dy, dz = t[1] - spawn[1], t[2] - spawn[2], t[3] - spawn[3]
		distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	end
	return {
		id = definition.id,
		zone = definition.zone,
		label = definition.label,
		target = { x = t[1], y = t[2], z = t[3] },
		placeId = definition.placeId,
		animation = definition.animation,
		distanceFromSpawn = distance,
	}, nil
end

--- Найти телепорт в сцене и проверить его против состояния движка.
function TeleportDirector.plan(scene, state)
	if type(scene) ~= "table" or scene.teleport == nil then
		return nil
	end
	local available, reason = TeleportDirector.availability(scene.teleport, state)
	return {
		definition = scene.teleport,
		available = available,
		reason = reason,
	}
end

return TeleportDirector
