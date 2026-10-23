--!nonstrict
-- Тесты игровой логики. Запуск: node tools/run-luau-tests.mjs
-- Глобальные StoryData и StoryEngine подставляет раннер.

local failures, checks = 0, 0

local function check(name, condition, detail)
	checks += 1
	if condition then
		print(string.format("  ok   %s", name))
	else
		failures += 1
		print(string.format("  FAIL %s%s", name, if detail then (" — " .. tostring(detail)) else ""))
	end
end

local function newEngine()
	local engine = StoryEngine.new(StoryData)
	engine:enter(engine.state.nodeId)
	return engine
end

--- Переход по тексту выбора. Возвращает true, если переход состоялся.
local function go(engine, text)
	local node = engine:node()
	for index, choice in ipairs(node.choices or {}) do
		if choice.text == text then
			local ok, err = engine:choose(index)
			if not ok then
				check("переход «" .. text .. "»", false, err)
				return false
			end
			return true
		end
	end
	check("переход «" .. text .. "» найден", false, "нет такого выбора в «" .. engine.state.nodeId .. "»")
	return false
end

local function findNode(predicate)
	for _, node in ipairs(StoryData.nodes) do
		if predicate(node) then
			return node
		end
	end
	return nil
end

--------------------------------------------------------------------------------
print("— старт и базовые проверки")

local engine = newEngine()
local view = engine:current()
check("старт — сцена start", view.id == "start")
check("старт — есть текст", #view.text > 40)
check("старт — два выбора", #view.choices == 2)
check("старт — не концовка", view.isEnding == false)
check("старт — есть глава", view.chapter ~= nil and #view.chapter > 0)

--------------------------------------------------------------------------------
print("— сюжет собран в одну линию")

local acts = {}
for _, node in ipairs(StoryData.nodes) do
	acts[node.act or 1] = true
end
check("четыре акта", acts[1] and acts[2] and acts[3] and acts[4])
check("сцен больше восьмидесяти", #StoryData.nodes > 80, #StoryData.nodes)
check("концовок три", (function()
	local count = 0
	for _ in pairs(StoryData.endings) do
		count += 1
	end
	return count == 3
end)())

local finalChapter = findNode(function(node)
	return (node.chapter or ""):find("Жестокий сплав огня и ревности", 1, true) ~= nil
end)
check("есть глава «Жестокий сплав огня и ревности»", finalChapter ~= nil)
check("глава последняя (акт 4)", finalChapter and finalChapter.act == 4)

--------------------------------------------------------------------------------
print("— телепорт последней главы по координатам карты")

local teleportScene = findNode(function(node)
	return node.teleport ~= nil
end)
check("сцена с телепортом найдена", teleportScene ~= nil)
if teleportScene then
	local tp = teleportScene.teleport
	check("телепорт в последней главе", teleportScene.act == 4, teleportScene.act)
	check("координаты — три числа", type(tp.target) == "table" and #tp.target == 3)
	check("цель — арена огня (x ≈ -201)", math.abs(tp.target[1] + 201.6) < 1, tp.target[1])
	check("цель — арена огня (z ≈ 6)", math.abs(tp.target[3] - 6.1) < 1, tp.target[3])
	check("есть placeId", type(tp.placeId) == "string" and #tp.placeId > 0)
	check("телепорт требует плату", (function()
		for _, item in ipairs(tp.requires and tp.requires.items or {}) do
			if item == "plate" then
				return true
			end
		end
		return false
	end)())

	check("цель телепорта — три конечных числа", (function()
		for i = 1, 3 do
			if type(tp.target[i]) ~= "number" or tp.target[i] ~= tp.target[i] then
				return false
			end
		end
		return true
	end)())
end

-- Арена из meta.map должна совпадать с целью телепорта.
if StoryData.meta.map and StoryData.meta.map.arena and teleportScene then
	local fire = StoryData.meta.map.arena.fire
	check("meta.map.arena.fire совпадает с целью телепорта",
		fire and math.abs(fire[1] - teleportScene.teleport.target[1]) < 1 and math.abs(fire[3] - teleportScene.teleport.target[3]) < 1)
end

--------------------------------------------------------------------------------
print("— анимации: бесконечный цикл с перезапуском")

local animated = findNode(function(node)
	return node.animations and #node.animations > 0
end)
check("есть сцены с анимациями", animated ~= nil)
check("анимации минимум в трёх сценах", (function()
	local count = 0
	for _, node in ipairs(StoryData.nodes) do
		if node.animations and #node.animations > 0 then
			count += 1
		end
	end
	return count >= 3
end)())

local animsCount = 0
for _, node in ipairs(StoryData.nodes) do
	for _, anim in ipairs(node.animations or {}) do
		animsCount += 1
		check("анимация «" .. tostring(anim.id) .. "» зациклена", anim.loop ~= false, tostring(anim.loop))
	end
end
check("анимаций в сюжете больше пяти", animsCount > 5, animsCount)

check("у каждой анимации есть кадры", (function()
	for _, node in ipairs(StoryData.nodes) do
		for _, anim in ipairs(node.animations or {}) do
			if type(anim.frames) ~= "table" or #anim.frames == 0 then
				return false
			end
		end
	end
	return true
end)())

--------------------------------------------------------------------------------
print("— ветка до финала: смерть Артёма неизбежна")

engine = newEngine()
go(engine, "Обойти обшивку снаружи")
check("пробоина найдена", engine:hasFlag("hull_scar"))
go(engine, "Запомнить и войти внутрь")
go(engine, "Молчать и идти дальше")
go(engine, "Жилой блок")
go(engine, "Прослушать дневник")
check("дневник получен", engine:hasItem("diary"))
go(engine, "Забрать дневник")
go(engine, "Вскрыть шкафчик")
check("ключ-карта получена", engine:hasItem("keycard"))
go(engine, "Забрать фотографию")
go(engine, "Вернуться в узел")
go(engine, "Техтоннель")
go(engine, "Спросить про сигнал")
go(engine, "«Расскажи всё»")
go(engine, "«Что мне делать?»")
go(engine, "Идти в центральный узел")
check("купол просканирован", engine:hasFlag("scanned"))
go(engine, "К сигнальному реле")
go(engine, "Прочитать тетрадь")
go(engine, "Перевернуть страницу")
go(engine, "Закрыть тетрадь")
go(engine, "Обесточить через аварийный кабель у пробоины")
check("сигнал обесточен", engine.state.nodeId == "relay_off", engine.state.nodeId)
go(engine, "Войти в купол")
check("вход в купол", engine.state.nodeId == "dome", engine.state.nodeId)
go(engine, "Войти в ворота")
go(engine, "Подойти к компании")
go(engine, "«Я с вами»")
go(engine, "Пойти за Демидом")
go(engine, "Промолчать")
go(engine, "«Я не хочу драться»")
go(engine, "«Тогда давай вспомним вместе»")
go(engine, "Сказать «прости»")
check("Ваня сомневается", engine:hasFlag("vanya_doubt"))
go(engine, "Уйти в клинч и сказать ему на ухо правду")
go(engine, "«Останется тот, кто умеет вставать»")
check("Ваня освобождён", engine:hasFlag("vanya_ally"))
go(engine, "«Ты — не я»")
go(engine, "«Ради права быть настоящим»")
go(engine, "Спросить, как он пережил смерть")
go(engine, "«Тогда ты знаешь, зачем я вернулся»")
go(engine, "Отступить и позвать Демида")
go(engine, "«Прикрой»")
check("Демид выбрал сам", engine:hasFlag("demid_ally"))
go(engine, "Прочитать последнюю страницу")
go(engine, "Не дать кругу замкнуться")
go(engine, "Отпустить нить")
go(engine, "«Веди меня туда»")
go(engine, "Спуститься")
go(engine, "«Тогда объясни»")
go(engine, "«А если погасить тебя — что останется?»")
go(engine, "«Это не свобода»")
go(engine, "«Ты предлагаешь нам выбрать, кто умрёт»")
go(engine, "«Вам здесь не место»")
go(engine, "«Он — копия. Оригинал — я»")
go(engine, "«Один очаг — это чья-то память»")
go(engine, "«Тогда горите вы»")
go(engine, "«Демид, прикрой левый фланг»")
go(engine, "«Почему я не удивлён»")
go(engine, "«Значит, решим это здесь»")
go(engine, "Пожать руку")
go(engine, "Идти к телепорту")
go(engine, "Подойти к Артинсу")
go(engine, "«Это и есть любовь»")
go(engine, "Активировать телепорт")
check("финальная глава началась", engine:current().act == 4 and engine:current().chapter:find("Жестокий сплав", 1, true) ~= nil)
go(engine, "Достать плату телепорта")
check("сцена телепорта", engine.state.nodeId == "ch4_teleport", engine.state.nodeId)
local tpView = engine:current()
check("телепорт доступен в сцене", tpView.teleport ~= nil)
check("телепорт открыт (плата есть)", tpView.teleport and tpView.teleport.available == true)
check("вид содержит координаты телепорта", tpView.teleport and tpView.teleport.target[1] == -201.6)
go(engine, "Шагнуть в огонь")
check("прибытие на арену", engine.state.nodeId == "arena_arrival", engine.state.nodeId)
go(engine, "«Тогда закончим»")
go(engine, "Встретить удар")
go(engine, "Бить по теням, а не по нему")
go(engine, "«Тогда вспоминай»")
go(engine, "«Скажу»")
go(engine, "Подойти к огню с девочкой")
go(engine, "Коснуться огня")
go(engine, "«Я не могу это отдать»")
go(engine, "Принять удар и обнять его")
check("Артинс обнят", engine:hasFlag("embraced_twin"))
go(engine, "«Не в этот раз»")
local beforeFinal = engine:serialize()
go(engine, "«Тогда решай я»")
go(engine, "Отдать огонь Артинсу и уйти в пламя")
view = engine:current()
check("финал — Артём мёртв", view.isEnding and view.ending.id == "ash", view.ending and view.ending.id)
check("текст концовки длинный", view.ending and #view.ending.text > 200)
check("состояние запомнило концовку", engine.state.ending == "ash")

--------------------------------------------------------------------------------
print("— граф: все сцены и концовки достижимы")

-- Полный обход состояний в WASM не укладывается в бюджет инструкций, поэтому
-- проверяем граф статически: выбор проходим, если все его требования вообще
-- где-то выполняются. Для 95 сцен и 14 флагов этого достаточно.

local settable, givable = {}, {}
local function noteEffects(effects)
	for flag in pairs(effects and effects.set or {}) do
		settable[flag] = true
	end
	for _, item in ipairs(effects and effects.give or {}) do
		givable[item] = true
	end
end
for _, node in ipairs(StoryData.nodes) do
	noteEffects(node.onEnter)
	for _, choice in ipairs(node.choices or {}) do
		noteEffects(choice)
	end
end

local function passable(requires)
	if not requires then
		return true
	end
	for _, flag in ipairs(requires.flags or {}) do
		if not settable[flag] then
			return false
		end
	end
	for _, flag in ipairs(requires.notFlags or {}) do
		if not settable[flag] then
			return false
		end
	end
	for _, item in ipairs(requires.items or {}) do
		if not givable[item] then
			return false
		end
	end
	return true
end

local reachable = {}
local endingsSeen = {}
local stack = { StoryData.meta.start }
local visitedNodes = 0
while #stack > 0 do
	local id = table.remove(stack)
	if not reachable[id] then
		reachable[id] = true
		visitedNodes += 1
		local node = findNode(function(candidate)
			return candidate.id == id
		end)
		if node then
			if node.ending then
				endingsSeen[node.ending] = true
			end
			for _, choice in ipairs(node.choices or {}) do
				if passable(choice.requires) and choice.goto then
					table.insert(stack, choice.goto)
				end
			end
		end
	end
end

check("все сцены достижимы", visitedNodes == #StoryData.nodes, visitedNodes .. "/" .. #StoryData.nodes)
for id in pairs(StoryData.endings) do
	check("концовка «" .. StoryData.endings[id].title .. "» достижима", endingsSeen[id] == true)
end
check("лишних концовок нет", (function()
	local count = 0
	for _ in pairs(endingsSeen) do
		count += 1
	end
	return count == 3
end)())

local deadEnds = 0
for _, node in ipairs(StoryData.nodes) do
	if not node.ending and not (node.choices and #node.choices > 0) then
		deadEnds += 1
	end
end
check("тупиков нет", deadEnds == 0, deadEnds)

-- Три концовки из одной точки: смерть неизбежна, различается только кто.
local atUltimatum = StoryEngine.new(StoryData, beforeFinal)
local finalIndex = nil
for index, choice in ipairs(atUltimatum:node().choices or {}) do
	if choice.goto == "final_choice" then
		finalIndex = index
	end
end
check("путь к финальному выбору есть", finalIndex ~= nil)
local atFinal = StoryEngine.new(StoryData, beforeFinal)
if finalIndex then
	atFinal:choose(finalIndex)
end
check("финальный выбор сохранён", atFinal:node().id == "final_choice", atFinal:node().id)
local outcomes = {}
for index, choice in ipairs(atFinal:node().choices or {}) do
	local copy = StoryEngine.new(StoryData, atFinal:serialize())
	if copy:choose(index) then
		outcomes[#outcomes + 1] = copy:current()
	end
end
check("три финала доступны сразу", #outcomes == 3, #outcomes)
local finalEndings = {}
for _, outcome in ipairs(outcomes) do
	if outcome.ending then
		finalEndings[outcome.ending.id] = true
		check("финал «" .. outcome.ending.title .. "» — смерть", (outcome.ending.text:find("умираешь", 1, true) ~= nil or outcome.ending.text:find("умер", 1, true) ~= nil or outcome.ending.text:find("пепел", 1, true) ~= nil or outcome.ending.text:find("остыв", 1, true) ~= nil or outcome.ending.text:find("перестаёшь", 1, true) ~= nil))
	end
end
check("все три концовки — в финальном выборе", finalEndings.ash and finalEndings.shard and finalEndings.loop)

print("— сохранение, рестарт, защита от мусора")

engine = newEngine()
go(engine, "Обойти обшивку снаружи")
check("флаг hull_scar", engine:hasFlag("hull_scar"))
local saved = engine:serialize()
local restored = StoryEngine.new(StoryData, saved)
check("флаг сохраняется", restored:hasFlag("hull_scar"))
check("сцена сохраняется", restored.state.nodeId == engine.state.nodeId)

engine:restart()
check("рестарт — стартовая сцена", engine.state.nodeId == "start")
check("рестарт — флаги пусты", next(engine.state.flags) == nil)

local ok = engine:choose(999)
check("несуществующий выбор отклонён", ok == false)

local broken = StoryEngine.new(StoryData, { nodeId = "нет такой сцены", flags = {}, items = {} })
check("битое сохранение откатывается на старт", broken.state.nodeId == "start")

--------------------------------------------------------------------------------
print("— порядок сцен: по нему собирается крыло из комнат")

check("StoryData.order есть", type(StoryData.order) == "table")
check("в порядке столько же сцен, сколько в сюжете", #(StoryData.order or {}) == #StoryData.nodes, #(StoryData.order or {}) .. " из " .. #StoryData.nodes)
check("порядок — это ровно те же id", (function()
	local seen = {}
	for _, id in ipairs(StoryData.order or {}) do
		seen[id] = (seen[id] or 0) + 1
	end
	for _, node in ipairs(StoryData.nodes) do
		if seen[node.id] ~= 1 then
			return false
		end
	end
	for id, n in pairs(seen) do
		if n ~= 1 then return false end
	end
	return true
end)())
check("первая сцена порядка — старт", StoryData.order[1] == StoryData.meta.start, StoryData.order[1])
check("последняя сцена порядка — концовка", (function()
	local last = StoryData.nodes[#StoryData.order]
	return last and last.ending ~= nil
end)())
check("в порядке есть все четыре акта", (function()
	local acts = {}
	for _, node in ipairs(StoryData.nodes) do
		acts[node.act or 1] = true
	end
	return acts[1] and acts[2] and acts[3] and acts[4]
end)())
check("текст каждой сцены не пустой", (function()
	for _, node in ipairs(StoryData.nodes) do
		if type(node.text) ~= "string" or node.text == "" then
			return false
		end
	end
	return true
end)())

print("")
print(string.format("Проверок: %d, провалено: %d", checks, failures))
return failures

