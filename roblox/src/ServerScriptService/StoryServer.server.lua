--!nonstrict
-- Серверная обвязка новеллы, которая живёт на настоящей карте.
--
-- Сюжет идёт не в окне: у каждой сцены есть точка в мире (WorldKit), игрок
-- доходит до неё — сцена сменяется. Живые НПС карты отыгрывают свои реплики,
-- в финале начинается драка, а телепорт физически переносит персонажа.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(shared:WaitForChild("StoryData"))
local StoryEngine = require(shared:WaitForChild("StoryEngine"))
local TeleportDirector = require(shared:WaitForChild("TeleportDirector"))
local WorldKit = require(shared:WaitForChild("WorldKit"))

local world = WorldKit.new(StoryData)

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
local Strike = ensure("RemoteEvent", "Strike")

local sessions = {}

-- Живые НПС карты: список собираем один раз, чтобы удар не перебирал 42k инстансов.
local hostiles = {}
task.spawn(function()
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
			table.insert(hostiles, model)
		end
	end
end)

local function sessionFor(player)
	local session = sessions[player]
	if not session then
		local engine = StoryEngine.new(StoryData)
		engine:enter(engine.state.nodeId)
		session = { engine = engine, lastChoiceAt = 0, lastHitAt = 0, lastStrikeAt = 0 }
		sessions[player] = session
	end
	return session
end

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

--- Полное состояние для клиента: сцена + куда идти + что происходит вокруг.
local function viewFor(player, session, extra)
	local view = session.engine:current(false)
	view.progress = session.engine:progress()
	view.items = session.engine.state.items

	local entry = world:point(view.id)
	if entry then
		local autoIndex = world:autoChoice(view.id)
		local root = rootOf(player)
		local distance = nil
		if root then
			local target = Vector3.new(entry.pos[1], entry.pos[2], entry.pos[3])
			distance = math.floor((root.Position - target).Magnitude)
		end
		view.world = {
			pos = entry.pos,
			zone = entry.zone,
			npc = entry.npc,
			reach = WorldKit.REACH,
			talk = WorldKit.TALK,
			auto = autoIndex ~= nil,
			distance = distance,
			-- Выбирать можно, когда игрок уже почти на месте: иначе выборы
			-- превращаются в обычное меню поверх карты.
			ready = distance == nil or distance <= WorldKit.REACH * 4,
		}
	end
	if extra then
		for key, value in pairs(extra) do
			view[key] = value
		end
	end
	return view
end

local function push(player, session, extra)
	StateChanged:FireClient(player, viewFor(player, session, extra))
end

RequestState.OnServerInvoke = function(player)
	local session = sessionFor(player)
	return viewFor(player, session)
end

-- Ограничение частоты: 1 выбор в 0.1 с на игрока.
local function canAct(session)
	local now = os.clock()
	if now - session.lastChoiceAt < 0.1 then
		return false
	end
	session.lastChoiceAt = now
	return true
end

Choose.OnServerEvent:Connect(function(player, index)
	if type(index) ~= "number" then
		return
	end
	local session = sessionFor(player)
	if not canAct(session) then
		return
	end

	local ok = session.engine:choose(index)
	if not ok then
		return
	end
	push(player, session)
end)

-- Телепорт последней главы: клиент присылает только id сцены, координаты
-- берутся с сервера, поэтому подделать точку назначения нельзя.
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
		push(player, session, { notice = reason })
		return
	end

	local definition = plan.definition
	local root = rootOf(player)
	if root then
		root.CFrame = CFrame.new(definition.target[1], definition.target[2] + 4, definition.target[3])
		root.AssemblyLinearVelocity = Vector3.zero
	end

	if definition.arrival then
		if session.engine:node(definition.arrival) then
			session.engine:enter(definition.arrival)
		end
	end
	push(player, session, { notice = definition.label })

	if definition.placeId and tostring(definition.placeId) ~= tostring(game.PlaceId) then
		local TeleportService = game:GetService("TeleportService")
		local ok = pcall(function()
			TeleportService:Teleport(tonumber(definition.placeId), player)
		end)
		if not ok then
			-- Игрок уже стоит на арене — сюжет продолжается без перехода.
			warn("TeleportDirector: не удалось перейти в плейс " .. tostring(definition.placeId))
		end
	end
end)

-- Удар в драке: ближайший НПС отлетает и получает искры.
Strike.OnServerEvent:Connect(function(player)
	local session = sessionFor(player)
	local root = rootOf(player)
	if not root or os.clock() - session.lastStrikeAt < 0.35 then
		return
	end
	session.lastStrikeAt = os.clock()

	local best, bestDist = nil, 18
	for _, model in ipairs(hostiles) do
		if model.Parent then
			local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
			if primary then
				local d = (primary.Position - root.Position).Magnitude
				if d < bestDist then
					best, bestDist = model, d
				end
			end
		end
	end
	if not best then
		return
	end

	local primary = best.PrimaryPart or best:FindFirstChild("HumanoidRootPart")
	if primary then
		local away = (primary.Position - root.Position).Unit
		best:PivotTo(CFrame.new(primary.Position + away * 6 + Vector3.new(0, 2, 0)))
	end
	local humanoid = best:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 25 then
		-- До смерти НПС не бьём: карта должна остаться целой.
		humanoid:TakeDamage(6)
	end
	local spark = Instance.new("Explosion")
	spark.Position = root.Position + root.CFrame.LookVector * 6
	spark.BlastRadius = 4
	spark.BlastPressure = 0
	spark.DestroyJointRadiusPercent = 0
	spark.Parent = workspace
	task.delay(0.4, function()
		spark:Destroy()
	end)
	push(player, session)
end)

Restart.OnServerEvent:Connect(function(player)
	local session = sessionFor(player)
	session.engine:restart()
	push(player, session)
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

--------------------------------------------------------------------------------
-- Мировой цикл: игрок дошёл до точки — сцена поехала дальше.

local BOILER = {
	[1] = "Станция «Тишина»",
	[2] = "Школа №0",
	[3] = "Огненный зал",
	[4] = "Арена «Сплав»",
}

-- Простые боевые сцены: в финале вокруг игрока становится жарко.
local function isFight(node, view)
	if node.fight then
		return true
	end
	if view and view.world and view.world.zone == "z4_c7" then
		return true
	end
	return node.act == 4
end

local function tiltCamera(player, power)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local base = camera.CFrame
	task.spawn(function()
		for i = 1, 6 do
			local offset = (math.random() - 0.5) * 0.06 * power
			camera.CFrame = base * CFrame.Angles(0, 0, offset)
			task.wait(0.04)
		end
		camera.CFrame = base
	end)
end

task.spawn(function()
	while true do
		task.wait(0.25)
		for player, session in pairs(sessions) do
			local node = session.engine:node()
			if not node then
				continue
			end
			local entry = world:point(node.id)
			local root = rootOf(player)
			if not entry or not root then
				continue
			end

			local target = Vector3.new(entry.pos[1], entry.pos[2], entry.pos[3])
			local distance = (root.Position - target).Magnitude
			local autoIndex = world:autoChoice(node.id)

			-- Сцена с одним безусловным выходом переключается сама.
			if autoIndex and distance <= WorldKit.REACH then
				if session.engine:choose(autoIndex) then
					push(player, session, { arrived = true })
					continue
				end
			end

			-- Драка: трясём камеру и понемногу снимаем здоровье, но не убиваем.
			if isFight(node) then
				local now = os.clock()
				if now - session.lastHitAt > 2.5 then
					session.lastHitAt = now
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 25 then
						humanoid.Health = humanoid.Health - 4
					end
					tiltCamera(player, 1)
					push(player, session)
				end
			end
		end
	end
end)

-- Метка мира: невидимый «маяк» в точке сцены, чтобы Studio-наблюдателю
-- и серверным эффектам было к чему прицепиться.
local beacon = Instance.new("Folder")
beacon.Name = "StoryWorld"
beacon.Parent = workspace
local markers = {}

local function markerFor(sceneId, pos)
	local marker = markers[sceneId]
	if not marker then
		marker = Instance.new("Part")
		marker.Name = "StoryPoint_" .. sceneId
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false
		marker.Transparency = 1
		marker.Size = Vector3.new(6, 10, 6)
		marker.Parent = beacon
		markers[sceneId] = marker
		CollectionService:AddTag(marker, "StoryPoint")
	end
	marker.CFrame = CFrame.new(pos[1], pos[2], pos[3])
	return marker
end

task.spawn(function()
	for sceneId, entry in pairs(world.plan) do
		markerFor(sceneId, entry.pos)
	end
	print(string.format("[Станция] мир готов: %d точек, %d живых НПС, зоны: %s",
		#StoryData.order, #(StoryData.world.cast or {}), table.concat((function()
			local names = {}
			for _, stage in ipairs(world:stages()) do
				table.insert(names, BOILER[stage.act] or ("Акт " .. stage.act))
			end
			return names
		end)(), " → ")))
end)
