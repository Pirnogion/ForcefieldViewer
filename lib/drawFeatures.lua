local atan, cos, sin = math.atan, math.cos, math.sin
local pi = math.pi

local gpu = love.graphics

local function map(x, in_min, in_max, out_min, out_max)
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

local drawFeatures = {}

function drawFeatures.generateNgon(r, n)
	local shape = {}

	for i=0, n-1, 1 do
		table.insert(shape, cos(2*pi/n*i)*r)
		table.insert(shape, sin(2*pi/n*i)*r)
	end

	table.insert(shape, shape[1])
	table.insert(shape, shape[2])

	return shape
end

function drawFeatures.drawVector(vector, label, color)
	local slopeFactor = vector[2] / vector[1]
	local ninetyDegrees = pi/2

	local angle = math.atan(slopeFactor)
	local fix = (vector[1] < 0) and -ninetyDegrees or ninetyDegrees

	gpu.setColor(color)
	gpu.line(0, 0, vector[1], vector[2])
	
	gpu.push()
	gpu.translate(vector[1], vector[2])

	gpu.setColor(0, 0, 0, 100)
	gpu.print(label, 4, 1)
	gpu.setColor(color)
	gpu.print(label, 3, 0)

	gpu.rotate(angle + fix)
	gpu.polygon("fill", 0, 0, 2, 7, -2, 7)
	
	gpu.pop()
end

local trajectories = {}

function drawFeatures.createTrajectory(capacity, color, timeOfLife)
	table.insert(trajectories, {cap = 4*capacity, clr = color or {0, 0, 0}, tol = timeOfLife or 4*capacity, mem = {}})

	return #trajectories
end

function drawFeatures.removeTrajectory(id)
	error("Work in progress.")
end

function drawFeatures.updateTrajectory(id, x1, y1, x2, y2)
	local trajectory = trajectories[id]

	if (#trajectory.mem == trajectory.cap) then
		table.remove(trajectory.mem, 1)
		table.remove(trajectory.mem, 1)
		table.remove(trajectory.mem, 1)
		table.remove(trajectory.mem, 1)
	end

	table.insert(trajectory.mem, x1)
	table.insert(trajectory.mem, y1)
	table.insert(trajectory.mem, x2)
	table.insert(trajectory.mem, y2)
end

function drawFeatures.drawTrajectory(id)
	drawFeatures.drawUserTrajectory(trajectories[id].mem, trajectories[id].tol, trajectories[id].clr)
end

function drawFeatures.drawUserTrajectory(trajectory, maxTrajectoryLife, color)
	for i = 1, #trajectory, 4 do
		local alpha = map(i+1, 0, math.min(#trajectory, maxTrajectoryLife), 0, 1)

		gpu.setColor(color[1], color[2], color[3], alpha)
		gpu.line(trajectory[i], trajectory[i+1], trajectory[i+2], trajectory[i+3])
	end
end

return drawFeatures