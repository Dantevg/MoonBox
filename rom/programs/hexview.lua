-- Open file
local path = ...
if not path then
	error( "Expected path", 2 )
end

path = shell.absolute(path)
if disk.info(path).type ~= "file" then
	error( "No such file", 2 )
end

local file = disk.read(path)
local running = true
local width = 4
while width*2 * 4 + math.floor(width*2/4) < screen.charWidth do
	width = width * 2
end
local start, length = 1, screen.charHeight * width
local maxScroll = math.ceil( (#file-length)/width ) * width + 1

local function writeLine( start, y )
	local x = 1
	for i = start, math.min( start + width - 1, #file ) do
		local char = string.sub(file,i,i)
		local xHex = ((x-1)*3 + math.floor((x-1)/4)) * (screen.font.width+1) + 1
		local xChar = ((x-1)+width*3 + math.floor(width/4)) * (screen.font.width+1) + 1
		local yScreen = (y-1)*(screen.font.height+1)+1
		
		screen.write( string.format("%02X ", string.byte(char)), xHex, yScreen )
		if string.byte(char) >= 32 and string.byte(char) < 127 then
			screen.write( char, xChar, yScreen )
		else
			screen.write( ".", {x = xChar, y = yScreen, color="gray-1"} )
		end
		x = x+1
	end
end

local function redraw()
	screen.clear()
	local y = 1
	for i = start, start + length - 1, width do
		writeLine( i, y )
		y = y+1
	end
end

redraw()

-- Main loop
while running do
	local _, key = event.wait("key")
	if key == "q" or key == "escape" then
		running = false
	elseif key == "up" and start > width then
		start = math.max( start - width, 1 )
		screen.move( 0, screen.font.height+1 )
		writeLine( start, 1 )
	elseif key == "down" and start < maxScroll then
		start = math.min( start + width, math.max(1, maxScroll) )
		screen.move( 0, -screen.font.height-1 )
		writeLine( start + length - width, screen.charHeight )
	elseif key == "pageup" then
		start = math.max( start - length, 1 )
		redraw()
	elseif key == "pagedown" then
		start = math.min( start + length, math.max(1, maxScroll) )
		redraw()
	end
end

-- Reset
os.sleep()
screen.clear()
screen.pos.set(1,1)