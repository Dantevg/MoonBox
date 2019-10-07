event = {}
local args = {...}
local computer = args[1]
local love = args[2]

function event.wait(event)
	local e = { coroutine.yield(event) }
	if e[1] == "terminate" then
		error( "Terminated", 0 )
	else
		return unpack(e)
	end
end

function event.push( event, ... )
	table.insert( computer.eventBuffer, {event, ...} )
end

function event.keyDown(key)
	if key == "shift" then
		return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	elseif key == "ctrl" or key == "control" then
		return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
	elseif key == "gui" then
		return love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui")
	else
		return love.keyboard.isDown(key)
	end
end

return event