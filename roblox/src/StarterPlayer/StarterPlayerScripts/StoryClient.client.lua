--!nonstrict
-- Клиент новеллы, которая идёт по настоящей карте.
--
-- Никакого полноэкранного меню: игрок видит мир, идёт к метке, а внизу
-- появляется реплика очередной сцены. Выборы — компактная строка кнопок,
-- в бою добавляется «Ударить», в финале — кнопка телепорта.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("StoryRemotes")
local RequestState = remotes:WaitForChild("RequestState")
local Choose = remotes:WaitForChild("Choose")
local Restart = remotes:WaitForChild("Restart")
local StateChanged = remotes:WaitForChild("StateChanged")
local Teleport = remotes:WaitForChild("Teleport")
local Strike = remotes:WaitForChild("Strike")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local StoryData = require(sharedFolder:WaitForChild("StoryData"))
local Cinema = require(sharedFolder:WaitForChild("Cinema"))

local COLORS = {
	panel = Color3.fromRGB(10, 12, 20),
	accent = Color3.fromRGB(125, 211, 252),
	text = Color3.fromRGB(232, 236, 246),
	muted = Color3.fromRGB(140, 148, 172),
	locked = Color3.fromRGB(112, 120, 140),
	good = Color3.fromRGB(163, 230, 53),
	bad = Color3.fromRGB(248, 113, 113),
	true_ = Color3.fromRGB(251, 191, 36),
	hot = Color3.fromRGB(249, 115, 22),
}

local TYPE_LABEL = { neutral = "НЕЙТРАЛЬНАЯ КОНЦОВКА", bad = "ПЛОХАЯ КОНЦОВКА", ["true"] = "ИСТИННАЯ КОНЦОВКА" }
local TYPE_COLOR = { neutral = COLORS.accent, bad = COLORS.bad, ["true"] = COLORS.true_ }

local function new(className, props, children)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		inst[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or Enum.Font.Gotham
	return new("TextLabel", props)
end

--------------------------------------------------------------------------------
-- Каркас
--------------------------------------------------------------------------------

local gui = new("ScreenGui", {
	Name = "StoryHud",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
gui.Parent = playerGui

-- Верх слева: глава, сцена, здоровье.
local head = new("Frame", {
	Name = "Head",
	Position = UDim2.new(0, 18, 0, 18),
	Size = UDim2.new(0, 380, 0, 74),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
}, { corner(10) })
head.Parent = gui

local actLabel = text({
	Name = "Act",
	Position = UDim2.new(0, 12, 0, 8),
	Size = UDim2.new(1, -24, 0, 16),
	Text = "",
	TextSize = 12,
	TextColor3 = COLORS.accent,
	TextXAlignment = Enum.TextXAlignment.Left,
})
actLabel.Parent = head

local sceneLabel = text({
	Name = "Scene",
	Position = UDim2.new(0, 12, 0, 24),
	Size = UDim2.new(1, -24, 0, 20),
	Text = "",
	TextSize = 15,
	TextColor3 = COLORS.text,
	TextXAlignment = Enum.TextXAlignment.Left,
})
sceneLabel.Parent = head

local hpBar = new("Frame", {
	Name = "HpBar",
	Position = UDim2.new(0, 12, 0, 52),
	Size = UDim2.new(1, -24, 0, 6),
	BackgroundColor3 = Color3.fromRGB(40, 46, 62),
	BorderSizePixel = 0,
}, { corner(3) })
hpBar.Parent = head

local hpFill = new("Frame", {
	Name = "Fill",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = COLORS.good,
	BorderSizePixel = 0,
}, { corner(3) })
hpFill.Parent = hpBar

-- Верх справа: предметы и прогресс.
local side = new("Frame", {
	Name = "Side",
	Position = UDim2.new(1, -262, 0, 18),
	Size = UDim2.new(0, 244, 0, 74),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
}, { corner(10) })
side.Parent = gui

local itemsLabel = text({
	Name = "Items",
	Position = UDim2.new(0, 12, 0, 8),
	Size = UDim2.new(1, -24, 0, 34),
	Text = "Инвентарь пуст",
	TextSize = 12,
	TextColor3 = COLORS.muted,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
itemsLabel.Parent = side

local progressLabel = text({
	Name = "Progress",
	Position = UDim2.new(0, 12, 0, 46),
	Size = UDim2.new(1, -24, 0, 20),
	Text = "",
	TextSize = 12,
	TextColor3 = COLORS.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
})
progressLabel.Parent = side

-- Правый низ: кадры анимации сцены.
local animLabel = text({
	Name = "Anim",
	Position = UDim2.new(1, -262, 1, -196),
	Size = UDim2.new(0, 244, 0, 40),
	Text = "",
	TextSize = 12,
	Font = Enum.Font.Code,
	TextColor3 = COLORS.hot,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextYAlignment = Enum.TextYAlignment.Bottom,
	TextWrapped = true,
})
animLabel.Parent = gui

-- Низ: реплика и выборы.
local panel = new("Frame", {
	Name = "Panel",
	Position = UDim2.new(0.5, 0, 1, -176),
	AnchorPoint = Vector2.new(0.5, 1),
	Size = UDim2.new(1, -36, 0, 160),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.18,
	BorderSizePixel = 0,
}, { corner(14) })
panel.Parent = gui

local speakerLabel = text({
	Name = "Speaker",
	Position = UDim2.new(0, 20, 0, 12),
	Size = UDim2.new(1, -40, 0, 18),
	Text = "",
	TextSize = 14,
	TextColor3 = COLORS.accent,
	TextXAlignment = Enum.TextXAlignment.Left,
})
speakerLabel.Parent = panel

local bodyLabel = text({
	Name = "Body",
	Position = UDim2.new(0, 20, 0, 34),
	Size = UDim2.new(1, -40, 0, 74),
	Text = "",
	TextSize = 15,
	TextColor3 = COLORS.text,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
bodyLabel.Parent = panel

local hintLabel = text({
	Name = "Hint",
	Position = UDim2.new(0, 20, 0, 112),
	Size = UDim2.new(1, -40, 0, 16),
	Text = "",
	TextSize = 12,
	TextColor3 = COLORS.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
})
hintLabel.Parent = panel

local choicesBox = new("Frame", {
	Name = "Choices",
	Position = UDim2.new(0, 20, 0, 130),
	Size = UDim2.new(1, -40, 0, 26),
	BackgroundTransparency = 1,
}, {
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}),
})
choicesBox.Parent = panel

local function clearChoices()
	for _, child in ipairs(choicesBox:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

-- Кнопка телепорта: только когда сцена его предлагает.
local teleportButton = new("TextButton", {
	Name = "Teleport",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -190),
	Size = UDim2.new(0, 300, 0, 44),
	BackgroundColor3 = COLORS.hot,
	BorderSizePixel = 0,
	Text = "ШАГНУТЬ В ОГОНЬ",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(20, 12, 4),
	AutoButtonColor = true,
	Visible = false,
}, { corner(10) })
teleportButton.Parent = gui

-- Кнопка удара: только в драке.
local strikeButton = new("TextButton", {
	Name = "Strike",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -190),
	Size = UDim2.new(0, 132, 0, 40),
	BackgroundColor3 = Color3.fromRGB(120, 30, 30),
	BorderSizePixel = 0,
	Text = "УДАРИТЬ",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(255, 220, 220),
	Visible = false,
}, { corner(9) })
strikeButton.Parent = gui

-- Экран концовки.
local ending = new("Frame", {
	Name = "Ending",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	Visible = false,
}, {})
ending.Parent = gui

local endKind = text({
	Position = UDim2.new(0.5, 0, 0, 96),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0, 720, 0, 18),
	Text = "",
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
})
endKind.Parent = ending

local endTitle = text({
	Position = UDim2.new(0.5, 0, 0, 122),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0, 720, 0, 44),
	Text = "",
	TextSize = 32,
	Font = Enum.Font.GothamBold,
	TextColor3 = COLORS.text,
	TextXAlignment = Enum.TextXAlignment.Center,
})
endTitle.Parent = ending

local endSummary = text({
	Position = UDim2.new(0.5, 0, 0, 176),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0, 700, 0, 20),
	Text = "",
	TextSize = 14,
	TextColor3 = COLORS.muted,
	TextXAlignment = Enum.TextXAlignment.Center,
})
endSummary.Parent = ending

local endText = text({
	Position = UDim2.new(0.5, 0, 0, 210),
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.new(0, 720, 0, 210),
	Text = "",
	TextSize = 15,
	TextColor3 = COLORS.text,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
})
endText.Parent = ending

local againButton = new("TextButton", {
	Position = UDim2.new(0.5, -110, 0, 440),
	Size = UDim2.new(0, 220, 0, 44),
	BackgroundColor3 = COLORS.accent,
	BorderSizePixel = 0,
	Text = "Пройти заново",
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextColor3 = Color3.fromRGB(6, 12, 20),
}, { corner(10) })
againButton.Parent = ending

--------------------------------------------------------------------------------
-- Метка в мире
--------------------------------------------------------------------------------

local marker = new("BillboardGui", {
	Name = "StoryMarker",
	Size = UDim2.new(0, 320, 0, 90),
	AlwaysOnTop = true,
	MaxDistance = 600,
	Enabled = false,
})
marker.Parent = playerGui

local markerArrow = text({
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 48),
	Text = "▼",
	TextSize = 44,
	TextColor3 = COLORS.accent,
	TextXAlignment = Enum.TextXAlignment.Center,
})
markerArrow.Parent = marker

local markerLabel = text({
	Position = UDim2.new(0, 0, 0, 44),
	Size = UDim2.new(1, 0, 0, 20),
	Text = "",
	TextSize = 13,
	TextColor3 = COLORS.text,
	TextXAlignment = Enum.TextXAlignment.Center,
})
markerLabel.Parent = marker

local markerAnchor = new("Part", {
	Name = "StoryMarkerAnchor",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.new(2, 2, 2),
	Parent = workspace,
})
marker.Adornee = markerAnchor

local beam = new("Part", {
	Name = "StoryBeam",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 0.55,
	Material = Enum.Material.Neon,
	Color = COLORS.accent,
	Size = Vector3.new(1.2, 40, 1.2),
	Parent = workspace,
})
local beamPoint = new("PointLight", {
	Brightness = 4,
	Range = 30,
	Color = COLORS.accent,
	Parent = beam,
})

--------------------------------------------------------------------------------
-- Состояние
--------------------------------------------------------------------------------

local state = {
	view = nil,
	cinema = nil,
	animIndex = 0,
	typing = nil,
	fullText = "",
}

local function setMarker(world)
	if not world or not world.pos then
		marker.Enabled = false
		beam.Transparency = 1
		beamPoint.Enabled = false
		return
	end
	local target = Vector3.new(world.pos[1], world.pos[2], world.pos[3])
	markerAnchor.Position = target
	marker.Enabled = true
	beam.Position = target + Vector3.new(0, 20, 0)
	beam.Transparency = 0.55
	beamPoint.Enabled = true
	markerLabel.Text = world.npc and ("поговорить: " .. world.npc) or "следующая сцена"
end

local function typeText(label, value, onDone)
	if state.typing then
		state.typing:Disconnect()
		state.typing = nil
	end
	state.fullText = value
	label.Text = ""
	local index = 0
	state.typing = RunService.Heartbeat:Connect(function(dt)
		index = math.min(#value, index + math.max(1, math.floor(dt * 90)))
		label.Text = string.sub(value, 1, index)
		if index >= #value then
			state.typing:Disconnect()
			state.typing = nil
			if onDone then
				onDone()
			end
		end
	end)
end

local function makeChoiceButton(choice, order, enabled)
	local button = new("TextButton", {
		Name = "Choice" .. order,
		LayoutOrder = order,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = if enabled then Color3.fromRGB(30, 40, 60) else Color3.fromRGB(24, 28, 38),
		BorderSizePixel = 0,
		Text = choice.text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = if enabled then COLORS.text else COLORS.locked,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = enabled,
	}, {
		corner(8),
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
	})
	button.Parent = choicesBox
	if enabled then
		button.Activated:Connect(function()
			Choose:FireServer(choice.index)
		end)
	end
	return button
end

local function renderEnding(view)
	local endingData = StoryData.endings[view.ending.id]
	if not endingData then
		return
	end
	ending.Visible = true
	endKind.Text = TYPE_LABEL[endingData.type] or "КОНЦОВКА"
	endKind.TextColor3 = TYPE_COLOR[endingData.type] or COLORS.accent
	endTitle.Text = endingData.title or view.ending.id
	endSummary.Text = endingData.summary or ""
	endText.Text = endingData.text or ""
	marker.Enabled = false
	beam.Transparency = 1
	beamPoint.Enabled = false
	panel.Visible = false
end

local function render(view)
	state.view = view
	ending.Visible = false
	panel.Visible = true

	local chapter = view.chapter or (StoryData.meta.chapters and StoryData.meta.chapters[view.act] and StoryData.meta.chapters[view.act].title) or ("Акт " .. tostring(view.act))
	actLabel.Text = string.upper(chapter)
	sceneLabel.Text = view.scene or ""

	local items = {}
	for id, _ in pairs(view.items or {}) do
		local item = StoryData.items and StoryData.items[id]
		table.insert(items, item and item.name or id)
	end
	table.sort(items)
	itemsLabel.Text = #items > 0 and table.concat(items, " · ") or "Инвентарь пуст"

	if view.progress then
		progressLabel.Text = string.format("Сцен пройдено: %d из %d", view.progress.visited or 0, view.progress.total or 0)
	end

	speakerLabel.Text = view.speaker or ""
	local okColor, parsed = pcall(Color3.fromHex, view.color or "#7dd3fc")
	speakerLabel.TextColor3 = if okColor then parsed else COLORS.accent

	-- Анимации сцены: выключаем прошлую и включаем новую.
	if view.animations and #view.animations > 0 then
		state.cinema = Cinema.new(view.animations, 6)
		state.animIndex = 0
	else
		state.cinema = nil
		animLabel.Text = ""
	end

	clearChoices()
	local worldInfo = view.world
	local ready = worldInfo == nil or worldInfo.ready ~= false
	-- Кнопки не блокируем по расстоянию: иначе игрок застрянет, если метка
	-- оказалась за геометрией. Расстояние показываем подсказкой.
	for index, choice in ipairs(view.choices or {}) do
		makeChoiceButton({ text = choice.text, index = index }, index, choice.available ~= false)
	end

	-- Подсказка «куда идти» и кнопки действий.
	if view.ending then
		renderEnding(view)
	elseif worldInfo and worldInfo.distance then
		if ready then
			hintLabel.Text = worldInfo.npc
					and ("Рядом: " .. worldInfo.npc .. " · сцена " .. view.scene)
				or ("Дошёл до места · сцена " .. view.scene)
		else
			hintLabel.Text = string.format("Иди по метке ▼ · ещё %d шагов", worldInfo.distance)
		end
	else
		hintLabel.Text = ""
	end

	-- Телепорт.
	if view.teleport and not view.ending then
		teleportButton.Visible = true
		teleportButton.Text = string.upper(view.teleport.label or "ТЕЛЕПОРТ")
		teleportButton.BackgroundColor3 = if view.teleport.available ~= false then COLORS.hot else Color3.fromRGB(90, 70, 55)
		teleportButton.TextColor3 = if view.teleport.available ~= false then Color3.fromRGB(20, 12, 4) else COLORS.locked
	else
		teleportButton.Visible = false
	end

	strikeButton.Visible = view.act == 4 and not view.ending
	setMarker(worldInfo)

	typeText(bodyLabel, view.text or "")
end

-- Сервер присылает view с полями сцены; клиент только рисует.
local function refresh()
	local ok, view = pcall(function()
		return RequestState:InvokeServer()
	end)
	if ok and view then
		render(view)
	end
end

StateChanged.OnClientEvent:Connect(function(view)
	render(view)
end)

teleportButton.Activated:Connect(function()
	local view = state.view
	if view and view.teleport then
		Teleport:FireServer(view.id)
	end
end)

strikeButton.Activated:Connect(function()
	Strike:FireServer()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		Strike:FireServer()
	elseif input.KeyCode == Enum.KeyCode.Space then
		local view = state.view
		if view and view.teleport then
			Teleport:FireServer(view.id)
		end
	end
end)

againButton.Activated:Connect(function()
	Restart:FireServer()
	refresh()
end)

-- Здоровье в верхней панели.
local function watchHealth()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local function update()
		local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		hpFill.Size = UDim2.new(ratio, 0, 1, 0)
		hpFill.BackgroundColor3 = if ratio > 0.5 then COLORS.good elseif ratio > 0.25 then COLORS.true_ else COLORS.bad
	end
	humanoid.HealthChanged:Connect(update)
	update()
end
task.spawn(watchHealth)

player.CharacterAdded:Connect(function()
	task.spawn(watchHealth)
end)

-- Кадры анимации прокручиваются бесконечно, пока сцена не сменится.
RunService.RenderStepped:Connect(function(dt)
	if not state.cinema then
		return
	end
	local tracks = state.cinema:advance(dt)
	local parts = {}
	for _, track in ipairs(tracks) do
		if track.text and track.text ~= "" then
			table.insert(parts, track.text)
		end
	end
	animLabel.Text = table.concat(parts, "   ")
end)

-- Метка пульсирует, чтобы её было видно издалека.
task.spawn(function()
	local t = 0
	while true do
		t += task.wait(0.08)
		if marker.Enabled then
			local scale = 1 + math.sin(t * 3) * 0.04
			markerArrow.TextSize = 44 * scale
			beam.Transparency = 0.55 + math.sin(t * 2) * 0.1
		end
	end
end)

refresh()
