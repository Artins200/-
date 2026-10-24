--!nonstrict
-- Проверка поз: то, что игрок должен видеть в комнате, а не читать в тексте.
-- Модель считается «сыгранной», если после Pose.apply у неё реально поменялись
-- руки, ноги, корпус или высота — то есть сцену видно, а не описано словами.

local failures = 0
local total = 0
local function check(name, ok, info)
	total += 1
	if ok then
		print(string.format("  ok   %s", name))
	else
		failures += 1
		print(string.format("  FAIL %s%s", name, info ~= nil and (" — " .. tostring(info)) or ""))
	end
end

local function snapshot(model)
	local out = {}
	for _, part in ipairs(model:GetChildren()) do
		out[part.Name] = { cf = part.CFrame, pos = part.CFrame.Position }
	end
	return out
end

local function moved(before, after, name, minDistance)
	local a = before[name]
	local b = after[name]
	if not a or not b then
		return false
	end
	return (a.pos - b.pos).Magnitude > (minDistance or 0.2)
end

local function headY(model)
	local head = model:FindFirstChild("Head")
	return head and head.CFrame.Position.Y or 0
end

local function partY(model, name)
	local part = model:FindFirstChild(name)
	return part and part.CFrame.Position.Y or 0
end

local function poseDistance(baseName, poseName)
	local model = r6()
	local base = Pose.capture(model)
	local before = snapshot(model)
	Pose.apply(model, base, poseName, 1)
	local after = snapshot(model)
	return model, base, before, after
end

print("— позы R6: каждая что-то делает с моделью")
for poseName in pairs(Pose.definitions) do
	local model, base, before, after = poseDistance("r6", poseName)
	local changed = false
	for name in pairs(before) do
		if moved(before, after, name) then
			changed = true
			break
		end
	end
	if poseName == "idle" then
		check("idle ничего не двигает", not changed)
	else
		check(string.format("поза %s меняет модель", poseName), changed)
	end
	Pose.reset(model, base)
	local back = snapshot(model)
	local restored = true
	for name in pairs(before) do
		if (before[name].pos - back[name].pos).Magnitude > 0.001 then
			restored = false
		end
	end
	check(string.format("после %s модель возвращается в стойку", poseName), restored)
end

print("— удар виден: рука идёт вперёд, корпус наклоняется")
do
	local model, _, before, after = poseDistance("r6", "punch")
	local armBefore = before["Right Arm"].pos
	local armAfter = after["Right Arm"].pos
	-- персонаж смотрит в −Z, значит удар — это минус по Z
	check("кулак уходит вперёд (−Z)", armAfter.Z < armBefore.Z - 0.3, string.format("%.2f → %.2f", armBefore.Z, armAfter.Z))
	check("корпус наклоняется за ударом", after["Head"].pos.Z < before["Head"].pos.Z - 0.1)
end

print("— захват за горло: обе руки вперёд")
do
	local model = r6()
	local base = Pose.capture(model)
	local before = snapshot(model)
	Pose.apply(model, base, "choke", 1)
	local after = snapshot(model)
	check("левая рука вперёд", after["Left Arm"].pos.Z < before["Left Arm"].pos.Z - 0.3)
	check("правая рука вперёд", after["Right Arm"].pos.Z < before["Right Arm"].pos.Z - 0.3)
	check("корпус наклонён к противнику", after["Torso"].pos.Z < before["Torso"].pos.Z - 0.2)
end

print("— падение и колено: персонаж уходит на пол")
do
	local model = r6()
	local base = Pose.capture(model)
	local standY = headY(model)
	Pose.apply(model, base, "fall", 1)
	local fallenY = headY(model)
	check("голова падает ниже пояса", fallenY < standY - 3, string.format("%.2f → %.2f", standY, fallenY))
	check("тело остаётся над полом", fallenY > 0)

	Pose.reset(model, base)
	local standTorso = partY(model, "Torso")
	Pose.apply(model, base, "kneel", 1)
	check("на колене корпус ниже", partY(model, "Torso") < standTorso - 1.5)
end

print("— лежит на полу, а не висит")
do
	local model = r6()
	local base = Pose.capture(model)
	Pose.apply(model, base, "fall", 1)
	local head = model:FindFirstChild("Head").CFrame.Position
	local torso = model:FindFirstChild("Torso").CFrame.Position
	check("голова у пола", head.Y > 0.2 and head.Y < 1.6, string.format("y %.2f", head.Y))
	check("корпус горизонтально у пола", torso.Y < 1.4, string.format("y %.2f", torso.Y))
	check("тело вытянулось вперёд", head.Z < torso.Z - 1, string.format("z %.2f / %.2f", head.Z, torso.Z))
end

print("— удар дотягивается до собеседника")
do
	local a = r6()
	local partner = r6()
	local baseA = Pose.capture(a)
	-- собеседник в трёх шагах впереди (модель смотрит в −Z)
	for _, part in ipairs(partner:GetChildren()) do
		part.CFrame = part.CFrame + Vector3.new(0, 0, -4)
	end
	Pose.shift(baseA, Vector3.new(0, 0, -1.9))
	Pose.apply(a, baseA, "punch", 1)
	local arm = a:FindFirstChild("Right Arm").CFrame.Position
	local body = partner:FindFirstChild("Torso").CFrame.Position
	local forward = Vector3.new(arm.X - body.X, 0, arm.Z - body.Z).Magnitude
	check("кулак почти у корпуса собеседника", forward < 2.0, string.format("%.2f", forward))
	check("кулак впереди своего корпуса", arm.Z < a:FindFirstChild("Torso").CFrame.Position.Z - 0.7, string.format("%.2f", arm.Z - a:FindFirstChild("Torso").CFrame.Position.Z))
end

print("— шаг вперёд сдвигает всю модель")
do
	local model = r6()
	local base = Pose.capture(model)
	local before = snapshot(model)
	Pose.apply(model, base, "step", 1)
	local after = snapshot(model)
	check("модель сместилась вперёд", after["Torso"].pos.Z < before["Torso"].pos.Z - 0.3)
	check("все части ушли вместе", moved(before, after, "Head") and moved(before, after, "Left Leg"))
end

print("— R15: поза ставится на риг из трёх частей на конечность")
do
	local model = r15()
	local base = Pose.capture(model)
	check("риг определён как R15", base.rig == "R15", base.rig)
	local before = snapshot(model)
	Pose.apply(model, base, "punch", 1)
	local after = snapshot(model)
	check("плечо двигается", moved(before, after, "RightUpperArm"))
	check("предплечье двигается вместе с плечом", moved(before, after, "RightLowerArm"))
	check("кисть идёт за рукой", moved(before, after, "RightHand"))
	local upper = (before["UpperTorso"].pos - after["UpperTorso"].pos).Magnitude
	local lower = (before["LowerTorso"].pos - after["LowerTorso"].pos).Magnitude
	check("корпус наклоняется целиком", upper > 0.1 and lower > 0.05, string.format("%.2f / %.2f", upper, lower))
	check("левая нога не тронута", not moved(before, after, "LeftUpperLeg", 0.05))
	Pose.apply(model, base, "fall", 1)
	check("падение работает и на R15", headY(model) < 3)
end

print("— шаг к собеседнику: Pose.walkToward сокращает дистанцию")
do
	local model = r6()
	local base = Pose.capture(model)
	local start = base.root.Position
	local target = Vector3.new(10, 4, -6)
	local walked = Pose.walkToward(model, base, target, 2, 4.5)
	local distanceBefore = (Vector3.new(target.X - start.X, 0, target.Z - start.Z)).Magnitude
	local now = (base.root or base.torso).Position
	local distanceAfter = (Vector3.new(target.X - now.X, 0, target.Z - now.Z)).Magnitude
	check("модель пошла к цели", walked)
	check("дистанция сократилась", distanceAfter < distanceBefore - 0.5, string.format("%.2f → %.2f", distanceBefore, distanceAfter))
	check("модель не влезла в собеседника", distanceAfter > 4.4)
	check("повернулась по ходу движения", (base.root.LookVector.X > 0.5), base.root.LookVector)
	check("части в модели тоже сдвинулись", (model:FindFirstChild("Torso").CFrame.Position - base.parts.Torso.Position).Magnitude < 0.001)
end

print("— анимация: alpha управляет силой позы")
do
	local model = r6()
	local base = Pose.capture(model)
	local before = snapshot(model)
	Pose.apply(model, base, "punch", 0.5)
	local half = snapshot(model)
	Pose.apply(model, base, "punch", 1)
	local full = snapshot(model)
	local halfMove = (before["Right Arm"].pos - half["Right Arm"].pos).Magnitude
	local fullMove = (before["Right Arm"].pos - full["Right Arm"].pos).Magnitude
	check("половинная поза короче полной", halfMove > 0.05 and halfMove < fullMove)
end

print("— модель без корпуса не роняет сервер")
do
	local broken = { Name = "broken", children = {} }
	function broken:GetChildren()
		return self.children
	end
	function broken:FindFirstChild()
		return nil
	end
	check("Pose.capture без частей не падает", Pose.capture(broken) ~= nil)
	check("Pose.apply без корпуса возвращает false", Pose.apply(broken, Pose.capture(broken), "punch", 1) == false)
	check("Pose.reset без базы не падает", pcall(function()
		Pose.reset(broken, {})
	end))
end

print(string.format("\nПроверок: %d, провалено: %d", total, failures))
return failures
