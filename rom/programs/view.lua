local arg = {...}

local path = arg[1]
if not path then
	error( "Expected path", 2 )
end

path = shell.absolute(path)
if not disk.exists(path) or disk.info(path).type ~= "file" then
	error( "No such file", 2 )
end

local theme = {
	comment = {"gray"},
	heading = {"red+1"},
	hline = {"gray-1"},
	code = {"gray+2", "gray-2"},
	bold = {"orange"},
	italic = {"purple+1"},
	word = {"white"},
	whitespace = {"white"},
	other = {"white"},
}

local syntax = (arg[2] == "--highlight") and require "mdsyntax"
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
		screen.setCharPos( -xScroll+2, line-yScroll+1 )
		if syntax then
			for match, type in syntax.gmatch( t[line] ) do
				screen.write( match, {overflow = false, colour = theme[type][1], background = theme[type][2]} )
			end
		else
			screen.write( t[line], {overflow = false} )
		end
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