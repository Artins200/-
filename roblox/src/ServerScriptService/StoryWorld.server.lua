--!nonstrict
-- StoryWorld — новелла идёт по карте: комнаты, персонажи, вывески, порталы.
-- Ни одного ScreenGui: всё, что видит игрок, стоит в Workspace.
--
-- Одна сцена = одна комната Scene_<id>:
--   Arrival — куда выбрасывает портал предыдущей комнаты
--   Exit    — оранжевая площадка у портала в следующую комнату
--   Sign    — вывеска: на ней по очереди появляются короткие реплики
--   модели персонажей — копии моделей карты, стоят друг напротив друга
--
-- Реплика не описывает действие — она его играет: Pose.lua меняет положение
-- рук, ног и корпуса (шаг, замах, удар, захват, падение).

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(shared:WaitForChild("StoryData"))
local StoryEngine = require(shared:WaitForChild("StoryEngine"))
local Pose = require(shared:WaitForChild("Pose"))

local wing = Workspace:WaitForChild("StoryWing", 30)
if not wing then
	warn("StoryWorld: нет Workspace.StoryWing — соберите файл через npm run place")
	return
end

local engine = StoryEngine.new(StoryData)
local finalPortal = nil

local ACT_LIGHT = {
	[1] = { ClockTime = 6.2, Ambient = Color3.fromRGB(24, 30, 44), Brightness = 1.3, FogEnd = 900 },
	[2] = { ClockTime = 13.0, Ambient = Color3.fromRGB(62, 68, 80), Brightness = 2.2, FogEnd = 1400 },
	[3] = { ClockTime = 18.4, Ambient = Color3.fromRGB(58, 34, 20), Brightness = 1.6, FogEnd = 900 },
	[4] = { ClockTime = 0.4, Ambient = Color3.fromRGB(52, 18, 10), Brightness = 1.0, FogEnd = 520 },
}

local function applyLight(act)
	local preset = ACT_LIGHT[act] or ACT_LIGHT[1]
	Lighting.ClockTime = preset.ClockTime
	Lighting.Ambient = preset.Ambient
	Lighting.OutdoorAmbient = preset.Ambient
	Lighting.Brightness = preset.Brightness
	Lighting.FogEnd = preset.FogEnd
	Lighting.FogColor = preset.Ambient
end

local function speakerName(key)
	local cast = StoryData.characters[key]
	return cast and cast.name or ""
end

--- Собираем сцены: комната, вывеска, актёры и их исходные позы.
local scenes = {}
for index, id in ipairs(StoryData.order) do
	local node = StoryData.nodes[index]
	if node and node.id == id then
		local model = wing:FindFirstChild("Scene_" .. id)
		if model then
			local sign = model:FindFirstChild("Sign")
			local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
			local label = gui and gui:FindFirstChildOfClass("TextLabel")
			local actors = {}
			local actorOrder = {}
			for _, child in ipairs(model:GetChildren()) do
				local humanoid = nil
				if child:IsA("Model") then
					for _, kid in ipairs(child:GetChildren()) do
						if kid:IsA("Humanoid") then
							humanoid = kid
							break
						end
					end
				end
				if humanoid then
					actors[child.Name] = { model = child, base = Pose.capture(child) }
					table.insert(actorOrder, child.Name)
				end
			end
			table.insert(scenes, {
				id = id,
				index = index,
				act = node.act or 1,
				node = node,
				model = model,
				gui = gui,
				label = label,
				actors = actors,
				actorOrder = actorOrder,
				down = {},
				arrival = model:FindFirstChild("Arrival"),
				portal = wing:FindFirstChild("Portal_" .. id),
				lines = node.lines or { { s = node.speaker, t = node.text, pose = "say" } },
			})
		end
	end
end

if #scenes == 0 then
	warn("StoryWorld: в крыле нет ни одной сцены")
	return
end

for _, scene in ipairs(scenes) do
	if scene.gui then
		scene.gui.Enabled = false
	end
	-- Портал открывается, только когда реплики сцены доиграны.
	local flag = scene.portal and scene.portal:FindFirstChild("Open")
	if flag then
		flag.Value = false
	end
end

local function poseFor(scene, name, poseName, alpha)
	local actor = scene.actors[name]
	if actor then
		Pose.apply(actor.model, actor.base, poseName, alpha)
	end
end

--- Позы, после которых персонаж остаётся лежать или стоять на колене до конца сцены.
local DOWN = { fall = true, kneel = true }

--- Стойки до первой реплики: комната живая ещё до текста.
-- Драка — обе стороны в защите, разговор — герой стоит, собеседник говорит.
local function stanceFor(scene)
	local poses = {}
	for _, line in ipairs(scene.lines) do
		poses[line.pose or "say"] = true
	end
	local fighting = poses.punch or poses.choke or poses.throw or poses.fall
	local down = poses.kneel
	local main = "idle"
	local partner = "say"
	if down then
		main = "kneel"
	elseif fighting or scene.act == 4 then
		main = "guard"
		partner = "guard"
	end
	local out = {}
	for index, name in ipairs(scene.actorOrder) do
		out[name] = if index == 1 then main elseif index == 2 then partner else "idle"
	end
	return out
end

--- Все, кроме говорящего, слушают.
local function idleExcept(scene, speaker)
	for name in pairs(scene.actors) do
		if name ~= speaker and not scene.down[name] then
			poseFor(scene, name, "idle", 1)
		end
	end
end

--- Ближайший собеседник: к кому герой делает шаг в драке.
local function partnerOf(scene, speaker)
	for _, name in ipairs(scene.actorOrder) do
		if name ~= speaker then
			return scene.actors[name]
		end
	end
	return nil
end

--- Шаг к собеседнику: модель сокращает дистанцию и возвращается назад.
-- Части анкорены, поэтому идём сдвигом базы позы, а не Humanoid:MoveTo.
local function lunge(actor, partner, distance)
	if not actor or not partner then
		return nil
	end
	local mine = actor.base.root or actor.base.torso
	local theirs = partner.base.root or partner.base.torso
	if not mine or not theirs then
		return nil
	end
	local delta = theirs.Position - mine.Position
	delta = Vector3.new(delta.X, 0, delta.Z)
	local gap = delta.Magnitude
	if gap < 0.2 then
		return nil
	end
	local step = math.min(distance, math.max(0, gap - 2.0))
	if step < 0.05 then
		return nil
	end
	local shift = delta.Unit * step
	Pose.shift(actor.base, shift)
	return shift
end

--- Действие руками: замах → рывок к собеседнику → возврат в стойку.
local function playAction(scene, speaker, poseName)
	local actor = scene.actors[speaker]
	if not actor then
		return
	end
	if not Pose.actions[poseName] then
		Pose.apply(actor.model, actor.base, poseName, 1)
		return
	end
	local partner = partnerOf(scene, speaker)
	local windUp = if poseName == "punch" or poseName == "throw" then "throw" else "guard"

	-- Замах и шаг к собеседнику: удар и захват видно, а не читается.
	Pose.apply(actor.model, actor.base, windUp, 0.6)
	local shift = lunge(actor, partner, if poseName == "fall" then 0 else 1.9)
	task.wait(0.16)
	Pose.apply(actor.model, actor.base, poseName, 1)

	if partner and (poseName == "punch" or poseName == "choke" or poseName == "throw") then
		-- Второй закрывается или уходит в сторону.
		task.spawn(function()
			Pose.apply(partner.model, partner.base, "block", 1)
			task.wait(0.6)
			if not scene.down[partner.model.Name] then
				Pose.apply(partner.model, partner.base, "guard", 1)
			end
		end)
	end

	-- Лежит или стоит на колене — так и остаётся до конца сцены.
	if DOWN[poseName] then
		return
	end

	task.delay(1.0, function()
		if shift then
			Pose.shift(actor.base, -shift)
		end
		if actor.model.Parent and not scene.down[speaker] then
			Pose.apply(actor.model, actor.base, "idle", 1)
		end
	end)
end

local sessions = {}

local function sessionFor(player)
	local session = sessions[player]
	if not session then
		session = { index = 1, ready = false, playing = false, lastTouch = 0 }
		sessions[player] = session
	end
	return session
end

local function placePlayer(player, scene)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not scene or not scene.arrival then
		return
	end
	local spot = scene.arrival.Position + Vector3.new(0, 3.2, 0)
	-- Всегда лицом к вывеске и актёрам, а не в стену.
	local look = scene.label and scene.label.Parent and scene.label.Parent.Position or (scene.model.Position + Vector3.new(16, 0, 0))
	root.CFrame = CFrame.lookAt(spot, Vector3.new(look.X, spot.Y, look.Z))
	root.AssemblyLinearVelocity = Vector3.zero
end

--- Реплики идут одна за другой на вывеске, персонаж играет позу.
local function playScene(player, session, scene)
	if session.playing then
		return
	end
	session.playing = true
	session.ready = false
	applyLight(scene.act)
	if scene.gui then
		scene.gui.Enabled = true
	end

	for _, line in ipairs(scene.lines) do
		local name = speakerName(line.s)
		if DOWN[line.pose or ""] then
			scene.down[name] = true
		end
		local text = engine:interpolate(line.t or "")
		if scene.label then
			scene.label.Text = if name ~= "" then string.format("%s: «%s»", name, text) else text
		end
		idleExcept(scene, name)
		task.spawn(playAction, scene, name, line.pose or "say")
		-- Длина реплики задаёт темп: короткая фраза — быстрее.
		task.wait(math.clamp(1.4 + #text * 0.055, 1.8, 4.2))
		if session.index ~= scene.index then
			session.playing = false
			return
		end
	end

	-- Все реплики сыграны: открываем портал в следующую комнату.
	session.ready = true
	session.playing = false
	local flag = scene.portal and scene.portal:FindFirstChild("Open")
	if flag then
		flag.Value = true
	end
	-- Последняя сцена: открываем портал в следующую локацию.
	if scene.index == #scenes and finalPortal then
		local finalFlag = finalPortal:FindFirstChild("Open")
		if finalFlag then
			finalFlag.Value = true
		end
	end
end

local function startScene(player, session)
	local scene = scenes[session.index]
	if not scene then
		return
	end
	-- Каждый заход в комнату начинается с чистых стоек — даже если сцену уже играли.
	scene.down = {}
	local stances = stanceFor(scene)
	for name, actor in pairs(scene.actors) do
		Pose.reset(actor.model, actor.base)
		Pose.apply(actor.model, actor.base, stances[name] or "idle", 1)
	end
	for _, other in ipairs(scenes) do
		if other ~= scene and other.gui then
			other.gui.Enabled = false
		end
		local flag = other.portal and other.portal:FindFirstChild("Open")
		if flag and other ~= scene then
			flag.Value = false
		end
	end
	task.spawn(playScene, player, session, scene)
end

--- Переход вперёд: следующая комната и её реплики.
local function advance(player, session)
	if session.index >= #scenes or not session.ready then
		return
	end
	session.index += 1
	print(string.format("[Станция] сцена %d/%d · %s", session.index, #scenes, scenes[session.index].id))
	-- Ставим игрока на вход новой комнаты лицом к вывеске, чтобы он не приехал спиной.
	task.delay(0.1, function()
		placePlayer(player, scenes[session.index])
	end)
	startScene(player, session)
end

for index, scene in ipairs(scenes) do
	local portal = scene.portal
	local pad = portal and portal:FindFirstChild("TeleportPart1")
	if pad then
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character or not character:FindFirstChildOfClass("Humanoid") then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local session = sessionFor(player)
			if session.index ~= index or not session.ready then
				return
			end
			local now = os.clock()
			if now - session.lastTouch < 0.6 then
				return
			end
			session.lastTouch = now
			advance(player, session)
		end)
	end
end

finalPortal = wing:FindFirstChild("Portal_Final")
if finalPortal then
	local pad = finalPortal:FindFirstChild("TeleportPart1")
	if pad then
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				print("[Станция] финал. Игрок ушёл в следующую локацию.")
			end
		end)
	end
end

local function onCharacter(player)
	local session = sessionFor(player)
	session.index = 1
	session.ready = false
	session.playing = false
	task.wait(0.25)
	placePlayer(player, scenes[1])
	startScene(player, session)
end

local function onPlayer(player)
	sessionFor(player)
	player.CharacterAdded:Connect(function()
		onCharacter(player)
	end)
	if player.Character then
		onCharacter(player)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

-- Акт IV: персонажи комнаты идут на игрока, а не стоят статуями.
-- Части анкорены, поэтому идём не Humanoid:MoveTo, а сдвигом базы позы.
task.spawn(function()
	while true do
		task.wait(0.7)
		for _, scene in ipairs(scenes) do
			if scene.act == 4 and scene.model.Parent then
				for name, actor in pairs(scene.actors) do
					local base = actor.base
					local npcRoot = base.root or base.torso
					for _, player in ipairs(Players:GetPlayers()) do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root and npcRoot and (root.Position - npcRoot.Position).Magnitude < 24 then
							if Pose.walkToward(actor.model, base, root.Position, 1.6, 4.5) then
								Pose.apply(actor.model, base, "step", 1)
							end
						end
					end
				end
			end
		end
	end
end)

task.spawn(function()
	task.wait(1)
	for _, scene in ipairs(scenes) do
		if scene.gui and scene ~= scenes[1] then
			scene.gui.Enabled = false
		end
	end
end)

print(string.format("[Станция] крыло: %d комнат, %d порталов, реплики на вывесках, интерфейса нет",
	#scenes, #scenes))
