local drawFeatures = require("lib/drawFeatures")
require("lib/vector")

local gpu = love.graphics

local mathRad = math.rad
local mathCos = math.cos
local mathSin = math.sin
local mathModf = math.modf
local mathFloor = function(...) return unpack({...}) end
local mathMax, mathMin = math.max, math.min

local screenWidth, screenHeight = gpu.getWidth(), gpu.getHeight()

local shadowCanvas, shadowCanvasData, effect, vertex, shader

local updateRate = 5 --secs
local time = love.timer.getTime()

local chargeSize = 7
local minDistSquared = 50^2

-- Настройка графической темы программы --
local mainFont = gpu.newFont("fonts/BAUHS93.ttf", 16)
local charges = {}

local function map(x, in_min, in_max, out_min, out_max)
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

local function RGBToHSB(r, g, b)
	local max, min = mathMax(r, g, b), mathMin(r, g, b)

	if max == min then
		return 0, max == 0 and 0 or (1 - min / max), max / 255
	elseif max == r and g >= b then
		return 60 * (g - b) / (max - min), max == 0 and 0 or (1 - min / max), max / 255
	elseif max == r and g < b then
		return 60 * (g - b) / (max - min) + 360, max == 0 and 0 or (1 - min / max), max / 255
	elseif max == g then
		return 60 * (b - r) / (max - min) + 120, max == 0 and 0 or (1 - min / max), max / 255
	elseif max == b then
		return 60 * (r - g) / (max - min) + 240, max == 0 and 0 or (1 - min / max), max / 255
	else
		return 0, max == 0 and 0 or (1 - min / max), max / 255
	end
end

function HSBToRGB(h, s, l)
	if s<=0 then return l,l,l,a end
	h, s, l = h/256*6, s/255, l/255
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return (r+m)*255,(g+m)*255,(b+m)*255
end

local function randomCharge()
	math.randomseed(love.timer.getTime())

	return (math.random(-1, 1) > 0) and 1 or -1
end

local function randomPos()
	math.randomseed(love.timer.getTime())

	return createVector(math.random(-screenWidth/2, screenWidth/2), math.random(-screenHeight/2, screenHeight/2))
end

local function randomRGBColor()
	math.randomseed(love.timer.getTime())

	return {math.random(), math.random(), math.random()}
end

local function createGravityField(mass, mainChargePos, testChargePos)
	local _relPos = testChargePos-mainChargePos
	local _temp = -mass / length(_relPos)^3

	return createVector(_temp * _relPos[1], _temp * _relPos[2])
end

local function createElectricField(charge, mainChargePos, testChargePos)
	local _relPos = testChargePos-mainChargePos
	local _temp = charge / length(_relPos)^3

	return createVector(_temp * _relPos[1], _temp * _relPos[2])
end

local function createSummaryField(testChargePos)
	local summaryField = createVector(0, 0)

	for _, obj in ipairs(charges) do
		summaryField = summaryField + createElectricField(obj.charge, obj.pos, testChargePos)
	end

	return summaryField
end

local function drawForceLine(obj, startAngle, steps, precision)
	local color = obj.color

	local shift = createVector(mathCos(mathRad(startAngle)), mathSin(mathRad(startAngle)))
	local testChargePos = copyVector(obj.pos) + shift

	for step = 1, steps, 1 do
		local alphaChannel = map(step, 0, steps, 255, 0)

		local fix = (obj.charge > 0) and 1 or -1
		local nextTestChargePos = copyVector(testChargePos) + normalize(createSummaryField(testChargePos))*precision*fix

		gpu.setColor(color[1], color[2], color[3], alphaChannel)
		gpu.line(testChargePos[1], testChargePos[2], nextTestChargePos[1], nextTestChargePos[2])

		testChargePos = copyVector(nextTestChargePos)
	end
end

local function drawElectricField(color)
	if (not color) then
		color = randomRGBColor()
	end

	for y = -screenHeight/2, screenHeight/2, 10 do
		for x = -screenWidth/2, screenWidth/2, 10 do
			local testChargePos = createVector(x, y)

			gpu.push()
				gpu.translate(testChargePos[1], testChargePos[2])

				drawFeatures.drawVector(createSummaryField(testChargePos), '', color)
			gpu.pop()
		end
	end
end

-- Создание зарядов --
local maxCharges = 10
local degree = 360/maxCharges
local radius = 100
for i = 1, maxCharges, 1 do
	table.insert(charges, {
		pos = createVector(mathCos(mathRad(degree*i))*radius, mathSin(mathRad(degree*i))*radius), 
		charge = 1, 
		color = randomRGBColor()
	})
end

function love.load()
	shadowCanvas = love.graphics.newCanvas()

	gpu.setBackgroundColor({255, 255, 255})
	gpu.setColor({0, 0, 0})

	effect = [[
		extern int charges;
		extern vec2[10] chargePositions;
        extern number[10] chargeValues;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
        	vec2 summary = vec2(0, 0);
        	vec2 allpos = vec2(0, 0);

        	for (int i = 0; i < charges; ++i)
        	{
        		vec2 a1 = pixel_coords-chargePositions[i];
	            number b1 = (chargeValues[i] * 8.9875517873681764 * pow(10, 9)) / pow(length(a1), 3);
	            
	            summary += b1*a1;
	            allpos += a1;
        	}

        	float result = dot(normalize(summary), normalize(allpos));
        	return vec4(result, 0.0, 0.0, 1.0);

        	//vec2 result = normalize(summary)*0.5+0.5;
            //return vec4(0.0, result.x, result.y, 1.0);

            //vec2 result = normalize(summary);
            //return vec4(result.x, result.y, 0.0, 1.0);

            //float brightness = (color.r+color.g+color.b)/3.0;
            //if (brightness == 0.0)
            //{
            //	return vec4(color.rgb, 0.2);
            //}

            //return color;
        }
    ]]

    vertex = [[
        vec4 position( mat4 transform_projection, vec4 vertex_position )
        {
            return transform_projection * vertex_position;
        }
    ]]

    shader = love.graphics.newShader(effect, vertex)
end

function love.update(dt)
	local currentTime = love.timer.getTime()

	for _, obj in ipairs(charges) do
		obj.pos = obj.pos + createVector(math.random(-1, 1), math.random(-1, 1))
	end

	if (currentTime-time > updateRate) then
		time = currentTime

		for id, obj in ipairs(charges) do
			local newPos = randomPos()

			::LOOP::
			for i = 1, id, 1 do
				if (length2(newPos - charges[i].pos) < minDistSquared) then
					newPos = randomPos()
					goto LOOP
				end
			end

			obj.pos = newPos
			obj.charge = randomCharge()
			obj.color = randomRGBColor()
		end
	end

	local toSendPositions = {}
	local toSendChargeValues = {}
	for _, obj in ipairs(charges) do
		table.insert(toSendPositions, {obj.pos[1]+screenWidth/2, obj.pos[2]+screenHeight/2})
		table.insert(toSendChargeValues, obj.charge)
	end

	shader:send("charges", #charges)
	shader:send("chargeValues", unpack(toSendChargeValues))
    shader:send("chargePositions", unpack(toSendPositions))
end

function love.draw()
	-- gpu.setCanvas(shadowCanvas)
	-- love.graphics.setShader(shader)
 --    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
 --    gpu.setCanvas()

 --    gpu.draw(shadowCanvas)

 --    love.graphics.setShader()

	gpu.setColor(0, 0, 0)
	gpu.print("FPS: " .. love.timer.getFPS(), 0, 0)

	gpu.push()
	gpu.translate(screenWidth/2, screenHeight/2)

	-- draw forcelines --
	for _, obj in ipairs(charges) do
		for angle = 1, 360, 24 do
			drawForceLine(obj, angle, 140, 6)
		end
	end

	--drawElectricField({0, 0, 0})

	-- draw particles --
	for _, obj in ipairs(charges) do
		local label = (obj.charge > 0) and "+" or "-"
		local labelText = gpu.newText(mainFont, label)

		local pos = obj.pos
		local color = obj.color

		gpu.setColor(color)
		gpu.circle("fill", pos[1], pos[2], chargeSize)

		gpu.setColor(255, 255, 255, 150)
		gpu.draw(labelText, pos[1]-labelText:getWidth()/2, pos[2]-labelText:getHeight()/2)
	end

	gpu.pop()
end