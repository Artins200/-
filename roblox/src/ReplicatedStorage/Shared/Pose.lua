--!nonstrict
-- Pose — позы персонажей вместо текста.
--
-- В крыле стоят копии моделей с карты: обычные R6-манекены (Torso, Left Arm…)
-- и R15-риги (UpperTorso, RightUpperArm…). Части у них анкорены, поэтому поза
-- ставится прямым присваиванием CFrame: никакой физики и никакого интерфейса.
-- Фраза «ударил» — это поза punch, «шагнул» — step, «взял за горло» — choke.
--
-- local base = Pose.capture(model)
-- Pose.apply(model, base, "punch")
-- Pose.reset(model, base)

local Pose = {}

Pose.ROOT = "HumanoidRootPart"

-- Логические группы частей: одинаково работают для R6 и R15.
Pose.GROUPS = {
	torso = { "Torso", "UpperTorso", "LowerTorso" },
	head = { "Head" },
	rightArm = { "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand" },
	leftArm = { "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	rightLeg = { "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" },
	leftLeg = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
}

-- Корпус: у R6 один Torso, у R15 — UpperTorso (по нему и считаем плечи).
Pose.TORSO = { "Torso", "UpperTorso" }

-- pitch > 0 — вперёд (персонаж смотрит в −Z корпуса).
Pose.definitions = {
	idle = {},
	say = { rightArm = { pitch = 0.5 }, head = { yaw = 0.18 } },
	point = { rightArm = { pitch = 1.5 }, head = { yaw = 0.2 } },
	step = { rightLeg = { pitch = 0.6 }, leftLeg = { pitch = -0.35 }, lean = 0.1, forward = 0.7 },
	reach = { rightArm = { pitch = 1.4 }, lean = 0.12 },
	grab = { leftArm = { pitch = 1.5 }, rightArm = { pitch = 1.5 }, lean = 0.2 },
	punch = { rightArm = { pitch = 1.6, yaw = -0.3 }, leftArm = { pitch = 0.8 }, lean = 0.3 },
	throw = { rightArm = { pitch = -1.0 }, leftArm = { pitch = -0.3 }, lean = -0.2 },
	block = { leftArm = { pitch = 1.2, yaw = 0.7 }, rightArm = { pitch = 1.2, yaw = -0.7 } },
	choke = { leftArm = { pitch = 1.55, yaw = 0.2 }, rightArm = { pitch = 1.55, yaw = -0.2 }, lean = 0.35 },
	guard = { leftArm = { pitch = 0.9 }, rightArm = { pitch = 0.9 }, lean = 0.1 },
	kneel = { leftLeg = { pitch = 1.4 }, rightLeg = { pitch = 1.4 }, drop = 2.0, lean = 0.15 },
	fall = { lean = 1.25, drop = 2.6, forward = 1.5 },
}

--- Части модели, входящие в группу (в порядке цепочки).
function Pose.partsOf(model, group)
	local out = {}
	for _, name in ipairs(Pose.GROUPS[group] or {}) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			table.insert(out, part)
		end
	end
	return out
end

--- Корпус модели: Torso у R6, UpperTorso у R15.
function Pose.torsoOf(model)
	for _, name in ipairs(Pose.TORSO) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

--- Какой риг у модели: "R6", "R15" или nil.
function Pose.rigOf(model)
	if model:FindFirstChild("UpperTorso") then
		return "R15"
	end
	if model:FindFirstChild("Torso") then
		return "R6"
	end
	return nil
end

--- Запоминает исходные CFrame всех частей модели.
function Pose.capture(model)
	local base = { parts = {} }
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			base.parts[child.Name] = child.CFrame
		end
	end
	base.root = base.parts[Pose.ROOT]
	base.torso = nil
	local torso = Pose.torsoOf(model)
	if torso then
		base.torso = base.parts[torso.Name]
		base.torsoName = torso.Name
	end
	base.rig = Pose.rigOf(model)
	return base
end

local function rotateAbout(cf, pivot, localRot, frameRotation)
	local worldRot = frameRotation * localRot * frameRotation:Inverse()
	return (CFrame.new(pivot) * worldRot * CFrame.new(-pivot)) * cf
end

--- Ставит позу. alpha = 0..1 — мягкий переход для анимации.
function Pose.apply(model, base, poseName, alpha)
	local def = Pose.definitions[poseName] or Pose.definitions.idle
	alpha = math.clamp(alpha or 1, 0, 1)

	if not base or not base.parts or not base.torso then
		return false
	end
	local torso = Pose.torsoOf(model)
	if not torso then
		return false
	end

	local torsoBase = base.torso
	local rotation = torsoBase - torsoBase.Position -- только поворот корпуса
	local tw, th = torso.Size.X, torso.Size.Y

	local forward = def.forward or 0
	local drop = def.drop or 0
	local lean = (def.lean or 0) * alpha
	local offset = rotation * Vector3.new(0, -drop * alpha, -forward * alpha)

	local hip = torsoBase * Vector3.new(0, -th * 0.5, 0)
	local neck = torsoBase * Vector3.new(0, th * 0.5, 0)
	local leanRot = CFrame.Angles(lean, 0, 0)

	-- Мировая точка корпуса с учётом сдвига и наклона: по ней считаются плечи и бёдра.
	local function leaned(worldPoint)
		local p = worldPoint + offset
		if lean ~= 0 then
			p = rotateAbout(CFrame.new(p), hip + offset, leanRot, rotation).Position
		end
		return p
	end

	-- 1. Корпус целиком: R6 — Torso, R15 — UpperTorso и LowerTorso.
	for _, name in ipairs(Pose.GROUPS.torso) do
		local part = model:FindFirstChild(name)
		local cf = base.parts[name]
		if part and cf then
			local moved = cf + offset
			if lean ~= 0 then
				moved = rotateAbout(moved, hip + offset, leanRot, rotation)
			end
			part.CFrame = moved
		end
	end

	-- 2. Руки: поворот всей цепочки вокруг плеча (R15 — от UpperArm до Hand).
	for _, group in ipairs({ "rightArm", "leftArm" }) do
		local angles = def[group]
		local sign = if group == "rightArm" then 1 else -1
		local parts = Pose.partsOf(model, group)
		if #parts > 0 then
			local width = parts[1].Size.X
			local shoulder = torsoBase * Vector3.new(sign * (tw * 0.5 + width * 0.5), th * 0.35, 0)
			local pivotPoint = leaned(shoulder)
			local rot = CFrame.Angles(
				(angles and angles.pitch or 0) * alpha,
				(angles and angles.yaw or 0) * alpha,
				(angles and angles.roll or 0) * alpha
			)
			for _, part in ipairs(parts) do
				local cf = base.parts[part.Name]
				if cf then
					local moved = cf + offset
					if lean ~= 0 then
						moved = rotateAbout(moved, hip + offset, leanRot, rotation)
					end
					if angles then
						moved = rotateAbout(moved, pivotPoint, rot, rotation)
					end
					part.CFrame = moved
				end
			end
		end
	end

	-- 3. Ноги: шаг и присед. Ступни остаются у пола, поэтому только сдвиг.
	for _, group in ipairs({ "rightLeg", "leftLeg" }) do
		local angles = def[group]
		local sign = if group == "rightLeg" then 1 else -1
		local parts = Pose.partsOf(model, group)
		if #parts > 0 then
			local width = parts[1].Size.X
			local hipPoint = torsoBase * Vector3.new(sign * (tw * 0.5 + width * 0.5) * 0.2, -th * 0.5, 0)
			local rot = CFrame.Angles(
				(angles and angles.pitch or 0) * alpha,
				(angles and angles.yaw or 0) * alpha,
				(angles and angles.roll or 0) * alpha
			)
			for _, part in ipairs(parts) do
				local cf = base.parts[part.Name]
				if cf then
					local moved = cf + offset
					if angles then
						moved = rotateAbout(moved, hipPoint + offset, rot, rotation)
					end
					part.CFrame = moved
				end
			end
		end
	end

	-- 4. Голова: лёгкий поворот в сторону собеседника.
	local head = model:FindFirstChild("Head")
	if head and base.parts.Head then
		local moved = base.parts.Head + offset
		if lean ~= 0 then
			moved = rotateAbout(moved, hip + offset, leanRot, rotation)
		end
		local h = def.head
		if h then
			moved = rotateAbout(
				moved,
				leaned(neck),
				CFrame.Angles((h.pitch or 0) * alpha, (h.yaw or 0) * alpha, 0),
				rotation
			)
		end
		head.CFrame = moved
	end

	if base.root then
		local rootPart = model:FindFirstChild(Pose.ROOT)
		if rootPart then
			rootPart.CFrame = base.root + offset
		end
	end

	return true
end

--- Вернуть модель в исходное положение.
function Pose.reset(model, base)
	if not base or not base.parts then
		return
	end
	for name, cf in pairs(base.parts) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.CFrame = cf
		end
	end
end

--- Сдвинуть всю модель: база пересчитывается, позы остаются рабочими.
function Pose.shift(base, delta)
	if not base or not base.parts then
		return
	end
	for name, cf in pairs(base.parts) do
		base.parts[name] = cf + delta
	end
	base.root = base.parts[Pose.ROOT]
	base.torso = base.torsoName and base.parts[base.torsoName] or nil
end

--- Повернуть всю модель вокруг её корня на yaw (радианы).
function Pose.turn(base, yaw)
	if not base or not base.parts then
		return
	end
	local pivot = (base.root or base.torso)
	if not pivot then
		return
	end
	local point = pivot.Position
	local rot = CFrame.Angles(0, yaw, 0)
	for name, cf in pairs(base.parts) do
		base.parts[name] = CFrame.new(point) * rot * CFrame.new(-point) * cf
	end
	base.root = base.parts[Pose.ROOT]
	base.torso = base.torsoName and base.parts[base.torsoName] or nil
end

--- Шаг к точке: модель идёт сама, без Humanoid:MoveTo (части анкорены).
function Pose.walkToward(model, base, target, speed, stopAt)
	if not base or not base.parts then
		return false
	end
	local current = (base.root or base.torso)
	if not current then
		return false
	end
	local here = current.Position
	local flat = Vector3.new(target.X - here.X, 0, target.Z - here.Z)
	local distance = flat.Magnitude
	if distance < (stopAt or 4.5) then
		return false
	end
	local step = math.min(distance - (stopAt or 4.5), speed or 2.2)
	local delta = flat.Unit * step
	-- Поворачиваемся по ходу движения: atan2 от −Z корпуса.
	local yaw = math.atan2(-delta.X, -delta.Z)
	local look = current.LookVector
	local currentYaw = math.atan2(-look.X, -look.Z)
	Pose.turn(base, yaw - currentYaw)
	Pose.shift(base, delta)
	for name, cf in pairs(base.parts) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.CFrame = cf
		end
	end
	return true
end

--- Позы, при которых персонаж явно что-то делает: их проигрываем рывком.
Pose.actions = {
	punch = true,
	throw = true,
	choke = true,
	grab = true,
	block = true,
	reach = true,
	kneel = true,
	fall = true,
}

return Pose
