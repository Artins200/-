--!nonstrict
-- Серверная обвязка визуальной новеллы.
-- Один StoryEngine на игрока, состояние не уходит клиенту напрямую —
-- клиент получает только готовое «представление» сцены.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(shared:WaitForChild("StoryData"))
local StoryEngine = require(shared:WaitForChild("StoryEngine"))
local TeleportDirector = require(shared:WaitForChild("TeleportDirector"))

-- Ремоуты создаём сами, чтобы не надо было собирать их руками в Studio.
local remotes = ReplicatedStorage:FindFirstChild("StoryRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "StoryRemotes"
	remotes.Parent = ReplicatedStorage
end

local function ensure(className, name)
	local existing = remotes:FindFirstChild(name)
	if existing then
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local RequestState = ensure("RemoteFunction", "RequestState")
local Choose = ensure("RemoteEvent", "Choose")
local Restart = ensure("RemoteEvent", "Restart")
local StateChanged = ensure("RemoteEvent", "StateChanged")
local Teleport = ensure("RemoteEvent", "Teleport")

local sessions = {}

local function sessionFor(player)
	local session = sessions[player]
	if not session then
		local engine = StoryEngine.new(StoryData)
		engine:enter(engine.state.nodeId)
		session = { engine = engine, lastChoiceAt = 0 }
		sessions[player] = session
	end
	return session
end

-- Простое ограничение частоты запросов: 1 выбор в 0.1 с на игрока.
local function canAct(session)
	local now = os.clock()
	if now - session.lastChoiceAt < 0.1 then
		return false
	end
	session.lastChoiceAt = now
	return true
end

RequestState.OnServerInvoke = function(player)
	local session = sessionFor(player)
	local view = session.engine:current(false)
	view.progress = session.engine:progress()
	return view
end

Choose.OnServerEvent:Connect(function(player, index)
	if type(index) ~= "number" then
		return
	end
	local session = sessionFor(player)
	if not canAct(session) then
		return
	end

	local ok, result = session.engine:choose(index)
	if not ok then
		return
	end

	local view = session.engine:current(false)
	view.progress = session.engine:progress()
	StateChanged:FireClient(player, view)
end)

-- Телепорт последней главы. Клиент присылает только id сцены — координаты
-- берутся с сервера из StoryData, поэтому подделать точку назначения нельзя.
Teleport.OnServerEvent:Connect(function(player, sceneId)
	if type(sceneId) ~= "string" then
		return
	end
	local session = sessionFor(player)
	local node = session.engine:node(sceneId)
	if not node or node.id ~= session.engine.state.nodeId then
		return
	end
	local plan = TeleportDirector.plan(node, session.engine.state)
	if not plan then
		return
	end
	local available, reason = TeleportDirector.availability(plan.definition, session.engine.state)
	if not available then
		StateChanged:FireClient(player, (function()
			local view = session.engine:current(false)
			view.progress = session.engine:progress()
			view.notice = reason
			return view
		end)())
		return
	end

	local definition = plan.definition
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		-- Сначала переносим внутри текущего плейса: это работает всегда,
		-- даже если внешний плейс ещё не опубликован.
		root.CFrame = CFrame.new(definition.target[1], definition.target[2] + 4, definition.target[3])
		root.AssemblyLinearVelocity = Vector3.zero
	end

	-- Телепорт — часть сюжета: после переноса сразу переходим в сцену прибытия.
	if definition.arrival then
		local arrival = session.engine:node(definition.arrival)
		if arrival then
			session.engine:enter(definition.arrival)
			local view = session.engine:current(false)
			view.progress = session.engine:progress()
			view.notice = definition.label
			StateChanged:FireClient(player, view)
		end
	end

	-- Если телепорт ведёт в другой опубликованный плейс — уходим туда.
	if definition.placeId and tostring(definition.placeId) ~= tostring(game.PlaceId) then
		local TeleportService = game:GetService("TeleportService")
		local ok = pcall(function()
			TeleportService:Teleport(tonumber(definition.placeId), player)
		end)
		if not ok then
			-- Не смогли — игрок уже стоит на арене, сюжет продолжается.
			warn("TeleportDirector: не удалось перейти в плейс " .. tostring(definition.placeId))
		end
	end
end)

Restart.OnServerEvent:Connect(function(player)
	local session = sessionFor(player)
	session.engine:restart()
	local view = session.engine:current(false)
	view.progress = session.engine:progress()
	StateChanged:FireClient(player, view)
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)
