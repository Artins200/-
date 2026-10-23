--!nonstrict
-- Клиент визуальной новеллы: рисует сцену, текст с печатной машинкой,
-- выборы, инвентарь и финальный экран. Вся логика — на сервере.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("StoryRemotes")
local RequestState = remotes:WaitForChild("RequestState")
local Choose = remotes:WaitForChild("Choose")
local Restart = remotes:WaitForChild("Restart")
local StateChanged = remotes:WaitForChild("StateChanged")

-- Подписи флагов и предметов берём из того же StoryData, что и сервер.
local StoryData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StoryData"))

local COLORS = {
	bg = Color3.fromRGB(9, 11, 18),
	panel = Color3.fromRGB(18, 22, 34),
	panelAlt = Color3.fromRGB(24, 29, 44),
	accent = Color3.fromRGB(125, 211, 252),
	text = Color3.fromRGB(230, 235, 245),
	muted = Color3.fromRGB(138, 147, 170),
	locked = Color3.fromRGB(120, 128, 148),
	good = Color3.fromRGB(163, 230, 53),
	bad = Color3.fromRGB(248, 113, 113),
	true_ = Color3.fromRGB(251, 191, 36),
}

local ACT_NAMES = { "Акт I", "Акт II", "Акт III" }
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

--------------------------------------------------------------------------------
-- Каркас интерфейса
--------------------------------------------------------------------------------

local gui = new("ScreenGui", {
	Name = "StoryGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, {})
gui.Parent = playerGui

local root = new("Frame", {
	Name = "Root",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COLORS.bg,
	BorderSizePixel = 0,
}, {
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 20, 32)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 8, 14)),
		}),
	}),
})
root.Parent = gui

-- Мягкое свечение за панелью
new("Frame", {
	Name = "Glow",
	Size = UDim2.fromScale(0.9, 0.75),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(56, 89, 130),
	BackgroundTransparency = 0.93,
	BorderSizePixel = 0,
}, { corner(400) }).Parent = root

local layout = new("Frame", {
	Name = "Layout",
	Size = UDim2.new(1, -48, 1, -48),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
}, {
	new("UISizeConstraint", { MaxSize = Vector2.new(1180, 760) }),
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 20),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
layout.Parent = root

-- Основная панель истории
local story = new("Frame", {
	Name = "Story",
	LayoutOrder = 1,
	Size = UDim2.new(1, -300, 1, 0),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
}, {
	corner(18),
	new("UIStroke", { Color = Color3.fromRGB(60, 72, 100), Transparency = 0.5, Thickness = 1 }),
	new("UIPadding", {
		PaddingTop = UDim.new(0, 24),
		PaddingBottom = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 30),
		PaddingRight = UDim.new(0, 30),
	}),
	-- Позиции задаются явно: смешивать UIListLayout с scale-размерами
	-- в панели с прокруткой ненадёжно на разных экранах.
})
story.Parent = layout

local actLabel = new("TextLabel", {
	Name = "Act",
	LayoutOrder = 1,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = COLORS.accent,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "АКТ I",
}, {})
actLabel.Parent = story

local sceneLabel = new("TextLabel", {
	Name = "Scene",
	LayoutOrder = 2,
	Position = UDim2.fromOffset(0, 22),
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 26,
	TextColor3 = COLORS.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, {})
sceneLabel.Parent = story

local speakerLabel = new("TextLabel", {
	Name = "Speaker",
	LayoutOrder = 3,
	Position = UDim2.fromOffset(0, 62),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = COLORS.accent,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, {})
speakerLabel.Parent = story

local bodyScroll = new("ScrollingFrame", {
	Name = "BodyScroll",
	LayoutOrder = 4,
	Position = UDim2.new(0, 0, 0, 92),
	Size = UDim2.new(1, 0, 0.42, -92),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Color3.fromRGB(80, 92, 120),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, {
	new("TextLabel", {
		Name = "Body",
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 19,
		LineHeight = 1.35,
		TextColor3 = COLORS.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = false,
		Text = "",
	}, {}),
})
bodyScroll.Parent = story
local bodyLabel = bodyScroll:WaitForChild("Body")

-- Тонкая линия-разделитель
new("Frame", {
	Name = "Divider",
	LayoutOrder = 5,
	Position = UDim2.new(0, 0, 0.42, 0),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = Color3.fromRGB(60, 72, 100),
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
}, {}).Parent = story

local choicesScroll = new("ScrollingFrame", {
	Name = "Choices",
	LayoutOrder = 6,
	Position = UDim2.new(0, 0, 0.42, 12),
	Size = UDim2.new(1, 0, 0.58, -12),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = Color3.fromRGB(80, 92, 120),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
choicesScroll.Parent = story

-- Боковая панель: что уже найдено
local side = new("Frame", {
	Name = "Side",
	LayoutOrder = 2,
	Size = UDim2.new(0, 280, 1, 0),
	BackgroundColor3 = COLORS.panelAlt,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
}, {
	corner(18),
	new("UIStroke", { Color = Color3.fromRGB(60, 72, 100), Transparency = 0.6 }),
	new("UIPadding", {
		PaddingTop = UDim.new(0, 22),
		PaddingBottom = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, 18),
		PaddingRight = UDim.new(0, 18),
	}),
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})
side.Parent = layout

new("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = COLORS.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "ЖУРНАЛ",
}, {}).Parent = side

local sideContent = new("ScrollingFrame", {
	LayoutOrder = 2,
	Size = UDim2.new(1, 0, 1, -170),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, {
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
sideContent.Parent = side

local progressLabel = new("TextLabel", {
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamMedium,
	TextSize = 12,
	TextColor3 = COLORS.muted,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Bottom,
	Text = "",
}, {})
progressLabel.Parent = side

local restartButton = new("TextButton", {
	LayoutOrder = 4,
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = Color3.fromRGB(40, 48, 68),
	BorderSizePixel = 0,
	AutoButtonColor = true,
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = COLORS.muted,
	Text = "Начать заново",
}, { corner(8) })
restartButton.Parent = side

--------------------------------------------------------------------------------
-- Экран концовки
--------------------------------------------------------------------------------

local endInner = new("Frame", {
	Size = UDim2.new(1, -48, 1, -48),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
}, {
	new("UISizeConstraint", { MaxSize = Vector2.new(720, 620) }),
	new("UIListLayout", {
		Padding = UDim.new(0, 16),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}),
	new("TextLabel", {
		Name = "Kind",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = COLORS.accent,
		Text = "",
	}),
	new("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 52,
		TextColor3 = COLORS.text,
		Text = "",
	}),
	new("TextLabel", {
		Name = "Summary",
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 15,
		TextColor3 = COLORS.muted,
		Text = "",
	}),
	new("TextLabel", {
		Name = "Text",
		Size = UDim2.new(1, 0, 0, 236),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 18,
		LineHeight = 1.35,
		TextColor3 = COLORS.text,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
	}),
	new("TextButton", {
		Name = "Again",
		Size = UDim2.new(0, 220, 0, 44),
		BackgroundColor3 = COLORS.accent,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(9, 11, 18),
		Text = "Пройти заново",
		AutoButtonColor = true,
	}, { corner(10) }),
})

local endScreen = new("Frame", {
	Name = "EndScreen",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(5, 6, 10),
	BackgroundTransparency = 1,
	Visible = false,
	BorderSizePixel = 0,
}, { endInner })
endScreen.Parent = root
local endKind = endInner:FindFirstChild("Kind")
local endTitle = endInner:FindFirstChild("Title")
local endSummary = endInner:FindFirstChild("Summary")
local endText = endInner:FindFirstChild("Text")
local endAgain = endInner:FindFirstChild("Again")

-- Адаптив: на узком экране прячем журнал
local function adapt()
	local width = root.AbsoluteSize.X
	local showSide = width >= 900
	side.Visible = showSide
	story.Size = if showSide then UDim2.new(1, -300, 1, 0) else UDim2.new(1, 0, 1, 0)
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(adapt)
adapt()

--------------------------------------------------------------------------------
-- Состояние и рендер
--------------------------------------------------------------------------------

local view = nil
local typewriterToken = 0
local busy = false

local function clear(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function setBodyText(text, instant)
	typewriterToken += 1
	local token = typewriterToken
	bodyLabel.Text = ""
	if instant or #text < 8 then
		bodyLabel.Text = text
		busy = false
		return
	end
	busy = true
	task.spawn(function()
		for i = 1, #text do
			if token ~= typewriterToken then
				return
			end
			bodyLabel.Text = text:sub(1, i)
			if i % 2 == 0 then
				task.wait(0.012)
			end
		end
		busy = false
	end)
end

local function makeChoiceButton(choice, order)
	local locked = not choice.available
	local button = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, -6, 0, 46),
		BackgroundColor3 = if locked then Color3.fromRGB(26, 30, 42) else Color3.fromRGB(32, 39, 58),
		BackgroundTransparency = if locked then 0.45 else 0.05,
		BorderSizePixel = 0,
		AutoButtonColor = not locked,
		Text = "",
		Selectable = not locked,
	}, {
		corner(10),
		new("UIStroke", {
			Color = if locked then Color3.fromRGB(50, 56, 72) else Color3.fromRGB(70, 90, 130),
			Transparency = 0.35,
		}),
		new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
		new("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 15,
			TextColor3 = if locked then COLORS.locked else COLORS.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Text = choice.text .. (locked and ("  ·  " .. tostring(choice.reason or "закрыто")) or ""),
		}),
	})
	if not locked then
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(44, 56, 82) }):Play()
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(32, 39, 58) }):Play()
		end)
		button.Activated:Connect(function()
			if busy then
				return
			end
			Choose:FireServer(choice.index)
		end)
	end
	return button
end

local function renderJournal(progress)
	clear(sideContent)
	local order = 0
	local items = progress.items or {}
	local flags = progress.flags or {}
	local any = false

	for itemId, owned in pairs(items) do
		if owned then
			any = true
			order += 1
			new("TextLabel", {
				LayoutOrder = order,
				Size = UDim2.new(1, -4, 0, 18),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = COLORS.true_,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = "◆ " .. (StoryData.items[itemId] and StoryData.items[itemId].name or tostring(itemId)),
			}).Parent = sideContent
		end
	end

	for flag, value in pairs(flags) do
		if value then
			any = true
			order += 1
			new("TextLabel", {
				LayoutOrder = order,
				Size = UDim2.new(1, -4, 0, 16),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				TextSize = 12,
				TextColor3 = COLORS.muted,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				Text = "· " .. (StoryData.flags[flag] and StoryData.flags[flag].label or tostring(flag)),
			}).Parent = sideContent
		end
	end

	if not any then
		new("TextLabel", {
			LayoutOrder = 1,
			Size = UDim2.new(1, -4, 0, 40),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLORS.muted,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = "Пока пусто. Всё, что найдёшь, появится здесь.",
		}).Parent = sideContent
	end
end

local function showEnding(ending)
	endKind.Text = TYPE_LABEL[ending.type] or "КОНЦОВКА"
	endKind.TextColor3 = TYPE_COLOR[ending.type] or COLORS.accent
	endTitle.Text = ending.title
	endSummary.Text = ending.summary or ""
	endText.Text = ending.text or ""

	endScreen.Visible = true
	endScreen.BackgroundTransparency = 1
	TweenService:Create(endScreen, TweenInfo.new(0.6), { BackgroundTransparency = 0.08 }):Play()
	story.BackgroundTransparency = 0.7
end

local function render(newView)
	view = newView
	endScreen.Visible = false
	story.BackgroundTransparency = 0.06

	actLabel.Text = string.upper(ACT_NAMES[view.act] or ("Акт " .. tostring(view.act)))
	sceneLabel.Text = view.scene
	speakerLabel.Text = view.speaker
	speakerLabel.TextColor3 = Color3.fromHex(view.color or "#7dd3fc")
	setBodyText(view.text, false)

	clear(choicesScroll)
	if view.isEnding then
		showEnding(view.ending)
		return
	end

	for order, choice in ipairs(view.choices) do
		makeChoiceButton(choice, order).Parent = choicesScroll
	end

	if view.progress then
		renderJournal(view.progress)
		local p = view.progress
		progressLabel.Text = string.format("Сцен исследовано: %d из %d", p.visited, p.total)
	end
end

--------------------------------------------------------------------------------
-- Управление
--------------------------------------------------------------------------------

bodyScroll.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if busy and view then
			typewriterToken += 1
			bodyLabel.Text = view.text
			busy = false
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R and view and not view.isEnding then
		-- R — повторить текущий текст без печатной машинки
		bodyLabel.Text = view.text
	end
end)

local function start()
	story.BackgroundTransparency = 0.06
	render(RequestState:InvokeServer())
end

endAgain.Activated:Connect(function()
	Restart:FireServer()
end)

restartButton.Activated:Connect(function()
	Restart:FireServer()
end)

StateChanged.OnClientEvent:Connect(render)

start()
