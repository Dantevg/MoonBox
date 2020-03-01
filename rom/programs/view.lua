local path = ...
if not path then
	error( "Expected path", 2 )
end

path = shell.absolute(path)
if not disk.exists(path) or disk.info(path).type ~= "file" then
	error( "No such file", 2 )
end

local t = disk.readLines(path)
local xScroll = 1
local yScroll = 1
local maxWidth = 1
for i = 1, #t do
	maxWidth = math.max( maxWidth, #t[i] )
end

repeat
	screen.clear()
	
	screen.setPixelPos( 1, 1 )
	for line = yScroll, yScroll + screen.charHeight - 2 do
		if line > #t then break end
		screen.setCharPos( 1, line-yScroll+1 )
		screen.write( string.sub( t[line], xScroll ), {overflow = false} )
	end
	screen.setCharPos( 1, screen.charHeight )
	screen.write( "Arrow keys for navigation, esc/q for exit", {colour = "yellow+1"} )
	
	local e, key = event.wait("key")
	if key == "up" then
		yScroll = math.max( 1, yScroll-1 )
	elseif key == "down" and yScroll+screen.charHeight-1 <= #t then
		yScroll = yScroll+1
	elseif key == "left" then
		xScroll = math.max( 1, xScroll-1 )
	elseif key == "right" then
		xScroll = math.min( xScroll+1, maxWidth-screen.charWidth )
	end
until key == "escape" or key == "q"

os.sleep()
screen.clear()
screen.setPixelPos( 1, 1 )