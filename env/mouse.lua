local mouse = {}
local args = {...}
local computer = args[1]
local love = args[2]

function mouse.isDown(button)
	return love.mouse.isDown(button)
end

setmetatable( mouse, {__index = function(t,k)
	if k == "x" then
		return computer.mouse.x
	elseif k == "y" then
		return computer.mouse.y
	elseif k == "pos" then
		return computer.mouse.x, computer.mouse.y
	elseif k == "drag" then
		if computer.mouse.drag then
			return {
				x = computer.mouse.drag.x,
				y = computer.mouse.drag.y
			}
		end
	end
end})

return mouse