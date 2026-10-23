--!nonstrict
-- Cinema — циклический проигрыватель анимаций новеллы.
--
-- Анимация в story.json выглядит так:
--   { id = "fire", loop = true, fps = 6, frames = { "🔥····", "·🔥···", ... } }
--
-- Правило простое: когда кадры заканчиваются, проигрыватель перезапускает
-- анимацию с первого кадра и увеличивает счётчик кругов. Бесконечно.
-- Никаких зависимостей от Roblox — модуль работает и в тестах.
--
--   local cinema = Cinema.new(scene.animations, 1)
--   local frames = cinema:advance(0.1)  -- { {id=..., text=..., index=..., loops=...}, ... }
--   cinema:restart("fire")             -- принудительный перезапуск с первого кадра

local Cinema = {}
Cinema.__index = Cinema

local function sanitize(definition, index)
	local frames = {}
	for _, frame in ipairs(definition.frames or {}) do
		table.insert(frames, tostring(frame))
	end
	local fps = tonumber(definition.fps) or 4
	if fps <= 0 then
		fps = 4
	end
	return {
		id = tostring(definition.id or ("anim" .. index)),
		frames = frames,
		fps = fps,
		loop = definition.loop ~= false,
		elapsed = 0,
		index = 1,
		loops = 0,
		finished = #frames == 0,
	}
end

--- @param definitions table|nil список анимаций сцены
--- @param fallbackFps number запасной FPS, если в анимации его нет
function Cinema.new(definitions, fallbackFps)
	local self = setmetatable({}, Cinema)
	self.tracks = {}
	self.fallbackFps = fallbackFps or 4
	for i, definition in ipairs(definitions or {}) do
		local track = sanitize(definition, i)
		if not definition.fps then
			track.fps = self.fallbackFps
		end
		track.elapsed = 0
		table.insert(self.tracks, track)
	end
	self.enabled = #self.tracks > 0
	return self
end

--- Текущий кадр дорожки (без прокрутки времени).
function Cinema:frame(id)
	for _, track in ipairs(self.tracks) do
		if track.id == id then
			return track.frames[track.index]
		end
	end
	return nil
end

--- Прокрутить все дорожки на dt секунд.
--- Возвращает список { id, text, index, loops, restarted } — по одному на дорожку.
--- restarted = true, если на этом шаге анимация закончилась и началась заново.
function Cinema:advance(dt)
	local out = {}
	dt = math.max(tonumber(dt) or 0, 0)
	for _, track in ipairs(self.tracks) do
		local restarted = false
		if #track.frames == 0 then
			track.finished = true
		elseif track.loop then
			track.elapsed += dt
			local step = 1 / track.fps
			-- while, а не if: после долгой паузы проматываем несколько кадров сразу
			while track.elapsed >= step do
				track.elapsed -= step
				track.index += 1
				if track.index > #track.frames then
					track.index = 1
					track.loops += 1
					restarted = true
				end
			end
			track.finished = false
		elseif not track.finished then
			track.elapsed += dt
			local step = 1 / track.fps
			while track.elapsed >= step and not track.finished do
				track.elapsed -= step
				track.index += 1
				if track.index > #track.frames then
					track.index = #track.frames
					track.finished = true
				end
			end
		end
		table.insert(out, {
			id = track.id,
			text = track.frames[track.index],
			index = track.index,
			frames = #track.frames,
			loops = track.loops,
			restarted = restarted,
			finished = track.finished,
		})
	end
	return out
end

--- Перезапустить дорожку с первого кадра (или все, если id не указан).
function Cinema:restart(id)
	for _, track in ipairs(self.tracks) do
		if id == nil or track.id == id then
			track.index = 1
			track.elapsed = 0
			track.loops = 0
			track.finished = #track.frames == 0
		end
	end
end

--- Сводка для отладки/тестов.
function Cinema:snapshot()
	local out = {}
	for _, track in ipairs(self.tracks) do
		table.insert(out, {
			id = track.id,
			index = track.index,
			frames = #track.frames,
			loops = track.loops,
			loop = track.loop,
		})
	end
	return out
end

return Cinema
