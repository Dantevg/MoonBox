-- Boot
screen.setFont("/rom/fonts/5x5_pxl_round.lua")

local _, fn = event.wait("elevateFunction") -- Get function

local function center( text, y )
	screen.write( text, { x = ( screen.width - #text*(screen.font.width+1) ) / 2, y = y, color = "gray-1" } )
end

-- Ask permission to user
screen.clear("white")
center( "Request to run this function out of sandbox:", 20 )
center( "(y/n to accept/decline)", 30 )
screen.write( fn, { x = 10, y = 60, color = "black", overflow = "wrap", max = screen.charWidth-3 } )

local _, key = event.wait("char")
if key ~= "y" then
	event.push( "elevateReturn", false, "unauthorized" )
	return
end

-- Execute function and return results
local chunk, err = load( fn, "elevated" )
if err then
	event.push( "elevateReturn", false, err )
	return
end
event.push( "elevateReturn", true, chunk() )