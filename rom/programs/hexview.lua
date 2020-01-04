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

-- Main loop
while running do
	screen.clear()
	local x, y = 1, 1
	for i = start, math.min( start + length - 1, #file ) do
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
		if i % width == 0 then
			x = 1
			y = y+1
		end
	end
	
	local _, key = event.wait("key")
	if key == "q" or key == "escape" then
		running = false
	elseif key == "up" then
		start = math.max( start - width, 1 )
	elseif key == "down" then
		start = math.min( start + width, math.max(1, maxScroll) )
	elseif key == "pageup" then
		start = math.max( start - length, 1 )
	elseif key == "pagedown" then
		start = math.min( start + length, math.max(1, maxScroll) )
	end
end

-- Reset
os.sleep()
screen.clear()
screen.pos = {x=1,y=1}