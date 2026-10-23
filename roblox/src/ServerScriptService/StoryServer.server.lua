--!nonstrict
-- Серверная обвязка визуальной новеллы.
-- Один StoryEngine на игрока, состояние не уходит клиенту напрямую —
-- клиент получает только готовое «представление» сцены.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(shared:WaitForChild("StoryData"))
local StoryEngine = require(shared:WaitForChild("StoryEngine"))

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
