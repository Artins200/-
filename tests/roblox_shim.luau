--!nonstrict
-- Окружение Roblox для проверки Pose.lua вне движка.
-- Здесь только то, чем пользуется Pose: CFrame, Vector3 и поддельные Instance.
-- Матрица поворота — 3×3, как в Roblox: LookVector = −третий столбец.

local Vector3 = {}
Vector3.__index = Vector3
Vector3.__type = "Vector3"

function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end

Vector3.zero = Vector3.new(0, 0, 0)

function Vector3.__add(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end

function Vector3.__sub(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

function Vector3.__unm(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end

function Vector3.__mul(a, b)
	if type(a) == "number" then
		return Vector3.new(b.X * a, b.Y * a, b.Z * a)
	end
	return Vector3.new(a.X * b, a.Y * b, a.Z * b)
end

Vector3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end

function Vector3.__tostring(a)
	return string.format("(%.2f, %.2f, %.2f)", a.X, a.Y, a.Z)
end

function Vector3.__index(self, key)
	if key == "Magnitude" then
		return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
	elseif key == "Unit" then
		local m = self.Magnitude
		if m == 0 then
			return Vector3.new(0, 0, 0)
		end
		return Vector3.new(self.X / m, self.Y / m, self.Z / m)
	end
	return nil
end

local CFrame = {}
CFrame.__index = CFrame
CFrame.__type = "CFrame"

-- typeof в Luau смотрит в метатаблицу; здесь проще сравнить её напрямую.
local function kind(value)
	local mt = getmetatable(value)
	if mt == Vector3 then
		return "Vector3"
	elseif mt == CFrame then
		return "CFrame"
	end
	return type(value)
end

local function mulMat(a, b)
	local out = {}
	for i = 1, 3 do
		out[i] = {}
		for j = 1, 3 do
			out[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j]
		end
	end
	return out
end

local function mulVec(m, v)
	return Vector3.new(
		m[1][1] * v.X + m[1][2] * v.Y + m[1][3] * v.Z,
		m[2][1] * v.X + m[2][2] * v.Y + m[2][3] * v.Z,
		m[3][1] * v.X + m[3][2] * v.Y + m[3][3] * v.Z
	)
end

local IDENTITY = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }

local function newCFrame(m, p)
	return setmetatable({ m = m, p = p }, CFrame)
end

function CFrame.new(a, b, c)
	if kind(a) == "Vector3" then
		return newCFrame(IDENTITY, a)
	end
	return newCFrame(IDENTITY, Vector3.new(a or 0, b or 0, c or 0))
end

-- Как CFrame.Angles в Roblox: сначала X, потом Y, потом Z.
function CFrame.Angles(x, y, z)
	local cx, sx = math.cos(x), math.sin(x)
	local cy, sy = math.cos(y), math.sin(y)
	local cz, sz = math.cos(z), math.sin(z)
	local mx = { { 1, 0, 0 }, { 0, cx, -sx }, { 0, sx, cx } }
	local my = { { cy, 0, sy }, { 0, 1, 0 }, { -sy, 0, cy } }
	local mz = { { cz, -sz, 0 }, { sz, cz, 0 }, { 0, 0, 1 } }
	return newCFrame(mulMat(mulMat(mx, my), mz), Vector3.zero)
end

CFrame.fromEulerAnglesXYZ = CFrame.Angles

function CFrame:Inverse()
	-- транспонирование поворота и обратный перенос
	local t = {
		{ self.m[1][1], self.m[2][1], self.m[3][1] },
		{ self.m[1][2], self.m[2][2], self.m[3][2] },
		{ self.m[1][3], self.m[2][3], self.m[3][3] },
	}
	return newCFrame(t, -mulVec(t, self.p))
end

local function positionOf(cf)
	return cf.p
end

CFrame.__index = function(self, key)
	if key == "Position" then
		return positionOf(self)
	elseif key == "LookVector" then
		return Vector3.new(-self.m[1][3], -self.m[2][3], -self.m[3][3])
	elseif key == "RightVector" then
		return Vector3.new(self.m[1][1], self.m[2][1], self.m[3][1])
	elseif key == "UpVector" then
		return Vector3.new(self.m[1][2], self.m[2][2], self.m[3][2])
	elseif key == "Rotation" then
		return newCFrame(self.m, Vector3.zero)
	elseif key == "X" then
		return self.p.X
	elseif key == "Y" then
		return self.p.Y
	elseif key == "Z" then
		return self.p.Z
	end
	return CFrame[key]
end

function CFrame.__add(a, v)
	return newCFrame(a.m, a.p + v)
end

function CFrame.__sub(a, b)
	if kind(b) == "Vector3" then
		return newCFrame(a.m, a.p - b)
	end
	-- CFrame − CFrame: поворот первого, разность позиций.
	return newCFrame(a.m, a.p - b.p)
end

function CFrame.__mul(a, b)
	if kind(b) == "Vector3" then
		return mulVec(a.m, b) + a.p
	end
	return newCFrame(mulMat(a.m, b.m), mulVec(a.m, b.p) + a.p)
end

function CFrame.__tostring(a)
	return string.format("CFrame(%s)", tostring(a.p))
end

-- instance: ровно те методы, которые зовёт Pose.
local function makePart(name, size, position)
	local part = {
		Name = name,
		Size = size,
		CFrame = CFrame.new(position),
		ClassName = "Part",
	}
	function part:IsA(className)
		return className == "BasePart"
	end
	return part
end

local function makeModel(parts)
	local model = { Name = "Actor", children = parts }
	function model:GetChildren()
		return self.children
	end
	function model:FindFirstChild(name)
		for _, child in ipairs(self.children) do
			if child.Name == name then
				return child
			end
		end
		return nil
	end
	return model
end

-- R6-манекен 2×2×1, стоит на полу лицом в −Z.
local function r6()
	local parts = {
		makePart("Head", Vector3.new(2, 1, 1), Vector3.new(0, 5.5, 0)),
		makePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 4, 0)),
		makePart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 4, 0)),
		makePart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 4, 0)),
		makePart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 2, 0)),
		makePart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 2, 0)),
		makePart("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 4, 0)),
	}
	return makeModel(parts)
end

-- R15-риг: корпус из двух частей, руки и ноги из трёх.
local function r15()
	local parts = {
		makePart("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 5.6, 0)),
		makePart("UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 4.3, 0)),
		makePart("LowerTorso", Vector3.new(2, 1.2, 1), Vector3.new(0, 3.1, 0)),
		makePart("RightUpperArm", Vector3.new(1, 1, 1), Vector3.new(1.6, 4.6, 0)),
		makePart("RightLowerArm", Vector3.new(1, 1, 1), Vector3.new(1.6, 3.6, 0)),
		makePart("RightHand", Vector3.new(0.9, 0.9, 0.9), Vector3.new(1.6, 2.7, 0)),
		makePart("LeftUpperArm", Vector3.new(1, 1, 1), Vector3.new(-1.6, 4.6, 0)),
		makePart("LeftLowerArm", Vector3.new(1, 1, 1), Vector3.new(-1.6, 3.6, 0)),
		makePart("LeftHand", Vector3.new(0.9, 0.9, 0.9), Vector3.new(-1.6, 2.7, 0)),
		makePart("RightUpperLeg", Vector3.new(1, 1.4, 1), Vector3.new(0.6, 2.2, 0)),
		makePart("RightLowerLeg", Vector3.new(1, 1.3, 1), Vector3.new(0.6, 0.9, 0)),
		makePart("RightFoot", Vector3.new(1, 0.4, 1.4), Vector3.new(0.6, 0.2, -0.2)),
		makePart("LeftUpperLeg", Vector3.new(1, 1.4, 1), Vector3.new(-0.6, 2.2, 0)),
		makePart("LeftLowerLeg", Vector3.new(1, 1.3, 1), Vector3.new(-0.6, 0.9, 0)),
		makePart("LeftFoot", Vector3.new(1, 0.4, 1.4), Vector3.new(-0.6, 0.2, -0.2)),
		makePart("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3.5, 0)),
	}
	return makeModel(parts)
end
