------------- RULES -------------
-- vector1 ⭘ vector2 = nVector --
-- vector1 ⭘ literal = nVector --
---------------------------------

------------- CONST -------------
local x, y = 1, 2

------- PRIVATE FUNCTIONS -------
local isTable  = function(value) return type(value) == "table" end
local isNumber = function(value) return type(value) == "number" end

local function checkTypes(value1, value2)
	local isTwoVectors      = isTable(value1) and isTable(value2)
	local isOneFirstVector  = isTable(value1) and isNumber(value2)
	local isOneSecondVector = isNumber(value1) and isTable(value2)

	local mainValue = (isTwoVectors or isOneFirstVector) and value1 or (isOneSecondVector) and value2
	local value = (isTwoVectors or isOneFirstVector) and value2 or (isOneSecondVector) and value1

	if not (isTwoVectors or isOneFirstVector or isOneSecondVector) then
		error("Expected TABLE or NUMBER. Value #1 is [" .. type(value1) .. "], Value #2 is [" .. type(value2) .. "].")
	end

	return copyVector(mainValue), isTable(value) and copyVector(value) or value
end

------- METATABLE -------
local overloadedOperators = 
{
	__add = function(value1, value2)
		value1, value2 = checkTypes(value1, value2)

		if (isTable(value1) and isTable(value2)) then
			value1[x], value1[y] = value1[x] + value2[x], value1[y] + value2[y]
		else
			value1[x], value1[y] = value1[x] + value2, value1[y] + value2
		end

		return value1
	end,

	__sub = function(value1, value2)
		value1, value2 = checkTypes(value1, value2)

		if (isTable(value1) and isTable(value2)) then
			value1[x], value1[y] = value1[x] - value2[x], value1[y] - value2[y]
		else
			value1[x], value1[y] = value1[x] - value2, value1[y] - value2
		end

		return value1
	end,

	__mul = function(value1, value2)
		value1, value2 = checkTypes(value1, value2)

		if (isTable(value1) and isTable(value2)) then
			value1[x], value1[y] = value1[x] * value2[x], value1[y] * value2[y]
		else
			value1[x], value1[y] = value1[x] * value2, value1[y] * value2
		end

		return value1
	end,

	__div = function(value1, value2)
		value1, value2 = checkTypes(value1, value2)

		if (isTable(value1) and isTable(value2)) then
			value1[x], value1[y] = value1[x] / value2[x], value1[y] / value2[y]
		else
			value1[x], value1[y] = value1[x] / value2, value1[y] / value2
		end

		return value1
	end,

	__unm = function(value)
		if (isTable(value)) then
			value[x], value[y] = -value[x], -value[y]
		else
			error("Invalid type. Is correct: -value1[table].")
		end

		return value
	end,

	__pow = function(value1, value2)
		if (isTable(value1) and isNumber(value2)) then
			value1[x], value1[y] = math.pow(value1[x], value2), math.pow(value1[y], value2)
		else
			error("Invalid type. Is correct: value1[table]^value2[number].")
		end

		return value1
	end,

	__mod = function(value1, value2)
		if not (isTable(value1) or isNumber(value2)) then
			error("Invalid type. Is correct: value1[table]%value2[table].")
		end

		return value1[x]*value2[x] + value1[y]*value2[y]
	end,

	__len = function(value)
		if (not isTable(value)) then
			error("Invalid type. Is correct: #value1[table].")
		end

		return math.sqrt( value[x]^2 + value[y]^2 )
	end
}

------- PUBLIC FUNCTIONS -------
function length2(value)
	return value[x]^2 + value[y]^2
end

function length(value)
	return math.sqrt( value[x]^2 + value[y]^2 )
end

function normalize(value)
	local len = length(value)

	if (len > 0) then
		return createVector(value[x] / len, value[y] / len)
	end

	return createVector(0, 0)
end

function mirrorOn(value1, value2)
	local s = 2 * (value1[1] * value2[1] + value1[2] * value2[2]) / (value2[1] * value2[1] + value2[2] * value2[2])
	return createVector(s * value2[1] - value1[1], s * value2[2] - value1[2])
end

function perpendicular(value1)
	return createVector(-value1[2], value1[1])
end

function copyVector(vector)
	return setmetatable( {vector[x], vector[y]}, overloadedOperators )
end

function createVector( a, b )
	return setmetatable( {a, b}, overloadedOperators )
end