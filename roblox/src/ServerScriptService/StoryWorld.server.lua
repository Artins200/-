--!nonstrict
-- StoryWorld — вся новелла идёт по карте, без единого элемента интерфейса.
--
-- Каждая сцена — это комната (модель Scene_<id>) в Workspace.StoryWing:
--   Sign    — вывеска с текстом сцены (SurfaceGui на части, как 225 вывесок карты)
--   Arrival — светящаяся площадка, куда игрока выбрасывает портал предыдущей сцены
--   Exit    — оранжевая площадка у портала в следующую комнату
--   Персонаж сцены — копия модели с карты, стоит впереди лицом к входу
--
-- Портал — папка «Teleport One Way» из этого же плейса: телепортирует сам,
-- скриптом Ignore внутри. Сервер только двигает сюжет: открывает нужную
-- вывеску и переключает свет. Никакого ScreenGui здесь нет.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(shared:WaitForChild("StoryData"))
local StoryEngine = require(shared:WaitForChild("StoryEngine"))

local wing = Workspace:WaitForChild("StoryWing", 30)
if not wing then
	warn("StoryWorld: нет Workspace.StoryWing — соберите файл через npm run place")
	return
end

-- Интерполяция $предметов берётся из движка, состояние сюжета — своё, линейное.
local engine = StoryEngine.new(StoryData)

local function labelOf(node)
	return engine:interpolate(node.text or "")
end

local function speakerName(node)
	local cast = StoryData.characters[node.speaker]
	return cast and cast.name or ""
end

--- Собираем сцены в порядке сюжета: каждая — комната в крыле.
local scenes = {}
for index, id in ipairs(StoryData.order) do
	local node = StoryData.nodes[index]
	if node and node.id == id then
		local model = wing:FindFirstChild("Scene_" .. id)
		if model then
			local npc = nil
			for _, child in ipairs(model:GetChildren()) do
				if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
					npc = child
					break
				end
			end
			local sign = model:FindFirstChild("Sign")
			local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
			local label = gui and gui:FindFirstChildOfClass("TextLabel")
			table.insert(scenes, {
				id = id,
				index = index,
				act = node.act or 1,
				model = model,
				gui = gui,
				label = label,
				arrival = model:FindFirstChild("Arrival"),
				exit = model:FindFirstChild("Exit"),
				portal = wing:FindFirstChild("Portal_" .. id),
				npc = npc,
				text = labelOf(node),
			})
		end
	end
end

if #scenes == 0 then
	warn("StoryWorld: в крыле нет ни одной сцены")
	return
end

-- Все вывески, кроме первой, погашены: игрок видит только свою сцену.
for _, scene in ipairs(scenes) do
	if scene.gui then
		scene.gui.Enabled = false
	end
end

local ACT_LIGHT = {
	[1] = { ClockTime = 6.2, Ambient = Color3.fromRGB(24, 30, 44), OutdoorAmbient = Color3.fromRGB(30, 38, 54), Brightness = 1.2, FogEnd = 900 },
	[2] = { ClockTime = 13.0, Ambient = Color3.fromRGB(60, 66, 78), OutdoorAmbient = Color3.fromRGB(96, 104, 118), Brightness = 2.4, FogEnd = 1400 },
	[3] = { ClockTime = 18.4, Ambient = Color3.fromRGB(58, 34, 20), OutdoorAmbient = Color3.fromRGB(90, 52, 26), Brightness = 1.8, FogEnd = 900 },
	[4] = { ClockTime = 0.4, Ambient = Color3.fromRGB(46, 16, 10), OutdoorAmbient = Color3.fromRGB(64, 22, 12), Brightness = 1.1, FogEnd = 500 },
}

local function applyLight(act)
	local preset = ACT_LIGHT[act] or ACT_LIGHT[1]
	Lighting.ClockTime = preset.ClockTime
	Lighting.Ambient = preset.Ambient
	Lighting.OutdoorAmbient = preset.OutdoorAmbient
	Lighting.Brightness = preset.Brightness
	Lighting.FogEnd = preset.FogEnd
	Lighting.FogColor = preset.Ambient
end

--- Показать сцену: включить её вывеску, погасить остальные, выставить свет.
local function show(scene)
	for _, other in ipairs(scenes) do
		if other.gui then
			other.gui.Enabled = other == scene
		end
	end
	applyLight(scene.act)
	print(string.format("[Станция] сцена %d/%d · %s · %s", scene.index, #scenes, scene.id, speakerName(StoryData.nodes[scene.index]) ))
end

local sessions = {}

local function placePlayer(player, scene)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local spot = scene and scene.arrival
	if not root or not spot then
		return
	end
	root.CFrame = spot.CFrame + Vector3.new(0, 3, 0)
	root.AssemblyLinearVelocity = Vector3.zero
end

local function sessionFor(player)
	local session = sessions[player]
	if not session then
		session = { index = 1, finished = false, lastTouch = 0 }
		sessions[player] = session
	end
	return session
end

--- Переход к следующей сцене: открыть её вывеску, переставить свет.
local function advance(player, session)
	if session.index >= #scenes then
		return false
	end
	session.index += 1
	local scene = scenes[session.index]
	show(scene)
	return true
end

-- Портал каждой сцены: касание площадки = сцена пройдена.
for index, scene in ipairs(scenes) do
	local portal = scene.portal
	if portal then
		local pad = portal:FindFirstChild("TeleportPart1")
		if pad then
			pad.Touched:Connect(function(hit)
				local character = hit.Parent
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not humanoid then
					return
				end
				local player = Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end
				local session = sessionFor(player)
				-- Срабатывает только та сцена, на которой игрок сейчас стоит.
				if session.index ~= index then
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
end

-- Последний портал: после финальной главы — в следующую локацию.
local finalPortal = wing:FindFirstChild("Portal_Final")
if finalPortal then
	local pad = finalPortal:FindFirstChild("TeleportPart1")
	if pad then
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = character and Players:GetPlayerFromCharacter(character)
			if player then
				sessions[player] = sessionFor(player)
				sessions[player].finished = true
			end
		end)
	end
end

-- Появление игрока: ставим его в первую комнату крыла.
local function onCharacter(player)
	local session = sessionFor(player)
	local scene = scenes[math.min(session.index, #scenes)]
	task.wait(0.2)
	placePlayer(player, scene)
	show(scene)
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

-- Персонажи акта IV не стоят смирно: подходят к игроку, когда он рядом.
task.spawn(function()
	while true do
		task.wait(0.8)
		local players = Players:GetPlayers()
		for _, scene in ipairs(scenes) do
			if scene.act == 4 and scene.npc then
				local npc = scene.npc
				local humanoid = npc:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local npcRoot = npc:FindFirstChild("HumanoidRootPart")
					for _, player in ipairs(players) do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root and npcRoot and (root.Position - npcRoot.Position).Magnitude < 26 then
							humanoid:MoveTo(root.Position)
						end
					end
				end
			end
		end
	end
end)

show(scenes[1])
print(string.format("[Станция] крыло готово: %d комнат, %d порталов, ни одного интерфейса", #scenes, #scenes))
