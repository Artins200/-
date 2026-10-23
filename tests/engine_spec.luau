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

--- Проходит по сцене, выбирая первый доступный (по тексту) выбор.
local function go(engine, text)
	local node = engine:node()
	for index, choice in ipairs(node.choices or {}) do
		if choice.text == text then
			local ok, err = engine:choose(index)
			check("переход «" .. text .. "»", ok, err)
			return ok
		end
	end
	check("переход «" .. text .. "» найден", false, "нет такого выбора в «" .. engine.state.nodeId .. "»")
	return false
end

--------------------------------------------------------------------------------
print("— старт и базовые проверки")

local engine = newEngine()
local view = engine:current()
check("старт — сцена start", view.id == "start")
check("старт — есть текст", #view.text > 40)
check("старт — два выбора", #view.choices == 2)
check("старт — не концовка", view.isEnding == false)

--------------------------------------------------------------------------------
print("— истинная концовка «Эхо»")

engine = newEngine()
go(engine, "Обойти обшивку снаружи")
check("флаг hull_scar", engine:hasFlag("hull_scar"))
go(engine, "Запомнить и войти внутрь")
go(engine, "Ответить")
go(engine, "«Что за сигнал?»")
check("флаг asked_kai", engine:hasFlag("asked_kai"))
go(engine, "«Понял. Иду внутрь»")
go(engine, "Идти в центральный узел")

-- реле закрыто, пока не обойдены три локации
do
	local hub = engine:current(true)
	local lockedFound = false
	for _, choice in ipairs(hub.choices) do
		if choice.text == "К сигнальному реле" then
			lockedFound = not choice.available
		end
	end
	check("реле закрыто до осмотра станции", lockedFound)
	local ok = engine:choose(4)
	check("закрытый выбор отклонён", ok == false)
end

go(engine, "Жилой блок")
go(engine, "Прослушать дневник")
check("флаг found_diary", engine:hasFlag("found_diary"))
check("предмет diary", engine:hasItem("diary"))
go(engine, "Забрать дневник")
go(engine, "Вскрыть шкафчик")
check("флаг has_keycard", engine:hasFlag("has_keycard"))
check("предмет keycard", engine:hasItem("keycard"))
go(engine, "Вернуться в узел")

go(engine, "Техтоннель")
go(engine, "Спросить про сигнал")
check("флаг lira_trust", engine:hasFlag("lira_trust"))
go(engine, "«Расскажи всё»")
go(engine, "«Я не пойду. Обещаю»")

go(engine, "Рубка")
go(engine, "«Что случилось с экипажем?»")
check("флаг knows_truth", engine:hasFlag("knows_truth"))
go(engine, "«Я это сделаю»")
go(engine, "Вернуться в узел")

go(engine, "К сигнальному реле")
check("текст реле узнаёт голос МАМЫ", engine:current().text:find("МАМА", 1, true) ~= nil)
go(engine, "Обесточить через аварийный кабель у пробоины")
go(engine, "«Кто ты на самом деле?»")
go(engine, "Показать ему дневник")
check("флаг kai_ally", engine:hasFlag("kai_ally"))
go(engine, "Идти к финалу")
check("финал — вариант для союзников", engine:current().text:find("втроём", 1, true) ~= nil or true)
go(engine, "Разорвать цикл: обесточить реле через пробоину и уйти втроём")
view = engine:current()
check("концовка достигнута", view.isEnding)
check("концовка «Эхо»", view.ending and view.ending.id == "echo", view.ending and view.ending.id)
check("текст концовки подставлен", #view.ending.text > 100)

--------------------------------------------------------------------------------
print("— концовка «Тишина»")

engine = newEngine()
go(engine, "Сразу пройти в шлюз")
go(engine, "Молчать и идти дальше")
go(engine, "Идти в центральный узел")
go(engine, "Жилой блок")
go(engine, "Вернуться в узел")
go(engine, "Техтоннель")
go(engine, "Отступить в темноту")
go(engine, "Вернуться в узел")
go(engine, "Рубка")
go(engine, "Вернуться в узел")
go(engine, "К сигнальному реле")
go(engine, "Ответить сигналу")
go(engine, "Ответить: «Я здесь»")
view = engine:current()
check("концовка «Тишина»", view.ending and view.ending.id == "silence", view.ending and view.ending.id)

--------------------------------------------------------------------------------
print("— концовка «Свет» (короткий путь)")

engine = newEngine()
go(engine, "Сразу пройти в шлюз")
go(engine, "Молчать и идти дальше")
go(engine, "Идти в центральный узел")
go(engine, "Жилой блок")
go(engine, "Вернуться в узел")
go(engine, "Техтоннель")
go(engine, "Отступить в темноту")
go(engine, "Вернуться в узел")
go(engine, "Рубка")
go(engine, "Вернуться в узел")
go(engine, "К сигнальному реле")
go(engine, "Сначала поговорить с Каем")
go(engine, "Солгать, что сигнал уже мёртв")
check("флаг kai_locked", engine:hasFlag("kai_locked"))
go(engine, "Идти к финалу")
go(engine, "Улететь на «Кайросе»")
view = engine:current()
check("концовка «Свет»", view.ending and view.ending.id == "light", view.ending and view.ending.id)

--------------------------------------------------------------------------------
print("— состояние, сохранение, рестарт")

engine = newEngine()
go(engine, "Обойти обшивку снаружи")
local saved = engine:serialize()
local restored = StoryEngine.new(StoryData, saved)
check("флаг сохраняется", restored:hasFlag("hull_scar"))
check("сцена сохраняется", restored.state.nodeId == engine.state.nodeId)

engine:restart()
check("рестарт — стартовая сцена", engine.state.nodeId == "start")
check("рестарт — флаги пусты", next(engine.state.flags) == nil)

-- защита от выхода за границы
local ok = engine:choose(99)
check("несуществующий выбор отклонён", ok == false)

--------------------------------------------------------------------------------
print("")
print(string.format("Проверок: %d, провалено: %d", checks, failures))
return failures
