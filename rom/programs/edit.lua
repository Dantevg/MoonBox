-- Open file
local path = ...
if not path then
	error( "Expected path", 2 )
end

local foundPath = shell.find( path, "f" )

if foundPath then
	path = foundPath
else
	path = shell.absolute(path)
end

local file = {""}

if disk.exists(path) and disk.info(path).type == "file" then
	file = disk.readLines(path)
	if not file then
		error( "Couldn't open file", 2 )
	end
end

-- Convert tabs to spaces
for y = 1, #file do
	file[y] = string.gsub( file[y], "\t", "  " )
end

-- Variables
local keywords = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"]= true,
	["while"] = true,
}

local patterns = {
	-- Comments
	{"^%-%-%[%[.-%]%]", "gray"},
	{"^%-%-.*", "gray"},
	-- Strings
	{"^\"\"", "green+1"},
	{"^\".-[^\\]\"", "green+1"},
	{"^\'\'", "green+1"},
	{"^\'.-[^\\]\'", "green+1"},
	{"^%[%[.-%]%]", "green+1"},
	-- Numbers
	{"^%d+", "red+1"},
	-- (Key)words
	{"^[%w_]+", function(match)
		if keywords[match] then
			return "yellow+1"
		else
			return "white"
		end
	end},
	-- Everything else
	{"^[^%w_]", "white"}
}

local running = true
local timer = os.startTimer(0.5)
local cursor = true
local x, y, xScroll, yScroll = 1, 1, 0, 0
local indent = 0


-- Functions
function save()
	disk.write( path, "" )
	for i = 1, #file do
		disk.append( path, file[i].."\n" )
	end
end

function setIndent()
	local _, _, s = string.find( file[y], "^(%s+)" )
	if s then
		indent = math.floor( #s / 2 )
	else
		indent = 0
	end
end

function getWords(line)
	local words = {}
	local length = 1
	for word, separator in string.gmatch( file[line], "(%w*)(%W*)" ) do
		table.insert( words, { type="word", data=word, s=length, e=length+#word-1 } )
		table.insert( words, { type="separator", data=separator, s=length+#word, e=length+#word+#separator-1 } )
		length = length + #word + #separator
	end
	return words
end

function drawLine( row, start )
	local line = file[row+yScroll]
	screen.setCharPos( 1, row )
	screen.setColor("gray+2")
	screen.write(row + yScroll)
	screen.setCharPos( start+1, row )
	
	local min = xScroll+1
	local max = math.min( screen.charWidth-start+xScroll, #line )
	local col = 0
	
	while #line > 0 and col < max do
		for i = 1, #patterns do
			local match = string.match( line, patterns[i][1] )
			if match then
				screen.setColor( type(patterns[i][2]) == "string" and patterns[i][2] or patterns[i][2](match) )
				screen.write( string.sub( match, math.max(min-col, 0), max-col ) )
				line = string.sub( line, #match+1 )
				col = col + #match
				break
			end
		end
	end
end

function draw()
	-- Background
	local lineStart = math.floor( math.log10(#file) ) + 2 -- Width of line numbers
	screen.clear("gray-2")
	
	-- File contents, line numbers
	local maxY = math.min( screen.charHeight-1, #file - yScroll )
	for row = 1, maxY do
		drawLine( row, lineStart )
	end
	
	-- Cursor
	if cursor then
		screen.setCharPos( x-xScroll + lineStart, y-yScroll )
		local x, y = screen.getPixelPos()
		screen.rect( x+1, y+1, screen.font.width, screen.font.height, "black" )
		screen.setColor("white")
		screen.cursor( x, y+1 )
	end
	
	-- File info
	screen.rect( 1, screen.height - screen.font.height, screen.width, screen.font.height+1, "gray-1" )
	screen.setColor("white")
	screen.setCharPos( 1, screen.charHeight )
	screen.write( disk.getFilename(path) )
	screen.setCharPos( screen.charWidth-#(x..":"..y) + 1, screen.charHeight )
	screen.write(x..":"..y)
end

function setCursor( newX, newY )
	x, y = newX, newY
	local w = math.floor( screen.charWidth - 1 )
	local h = math.floor( screen.charHeight + 1 )
	local lineStart = math.floor( math.log10(#file) ) + 1 -- Width of line numbers
	
	local xScreen = x - xScroll + lineStart - 1
	local yScreen = y - yScroll
	
	if xScreen <= lineStart then
		xScroll = x - 1
	elseif xScreen > w then
		xScroll = x - w + lineStart - 1
	end
	
	if yScreen < 1 then
		yScroll = y - 1
	elseif yScreen > h-2 then
		yScroll = y - (h-2)
	end
	
	cursor = true
	timer = os.startTimer(0.5)
end

function keyPress(key)
	if key == "backspace" then
		if event.keyDown("ctrl") and x > 1 then
			local words = getWords(y)
			for i = 1, #words do
				if x > words[i].s and x <= words[i].e+1 then
					local l = #words[i].data
					words[i].data = string.sub( words[i].data, x - words[i].s + 1 )
					x = math.max( 1, x-(l-#words[i].data) )
					break
				end
			end
			file[y] = ""
			for i = 1, #words do
				file[y] = file[y] .. words[i].data
			end
		else
			if x > 1 then
				file[y] = string.sub( file[y], 1, x-2 )..string.sub( file[y], x )
				setCursor( x-1, y )
			elseif y > 1 then
				setCursor( #file[y-1]+1, y-1 )
				file[y] = file[y] .. file[y+1]
				table.remove( file, y+1 )
			end
		end
	elseif key == "delete" then
		if event.keyDown("ctrl") and x < #file[y] then
			local words = getWords(y)
			for i = 1, #words do
				if x > words[i].s and x <= words[i].e+1 then
					words[i].data = string.sub( words[i].data, 1, x - words[i].s )
					break
				end
			end
			file[y] = ""
			for i = 1, #words do
				file[y] = file[y] .. words[i].data
			end
		else
			if x <= #file[y] then
				file[y] = string.sub( file[y], 1, x-1 )..string.sub( file[y], x+1 )
			elseif y < #file then
				file[y] = file[y] .. file[y+1]
				table.remove( file, y+1 )
			end
		end
	elseif key == "enter" then
		table.insert( file, y+1, "" )
		setIndent()
		file[y+1] = string.rep( "  ", indent ) .. string.sub( file[y], x, -1 )
		file[y] = string.sub( file[y], 1, x-1 )
		setCursor( indent*2+1, y+1 )
	elseif key == "tab" then
		file[y] = string.sub( file[y], 1, x ).."  "..string.sub( file[y], x+1, -1 )
		x = x+2
		setIndent()
	elseif key == "up" then
		if y > 1 then
			setCursor( math.min( x, #file[y-1]+1 ), y-1 )
		else
			setCursor( 1, 1 )
		end
	elseif key == "right" then
		if event.keyDown("ctrl") and x < #file[y] then
			local words = getWords(y)
			for i = 1, #words do
				if x >= words[i].s and x <= words[i].e then
					setCursor( (words[i].type == "separator") and words[i+1].e+1 or words[i].e+1, y )
					break
				end
			end
		else
			if x < #file[y]+1 then
				setCursor( x+1, y )
			elseif y < #file then
				setCursor( 1, y+1 )
			end
		end
	elseif key == "down" then
		if y < #file then
			setCursor( math.min( x, #file[y+1]+1 ), y+1 )
		else
			setCursor( #file[y]+1, y )
		end
	elseif key == "left" then
		if event.keyDown("ctrl") and x > 1 then
			local words = getWords(y)
			for i = 1, #words do
				if x > words[i].s and x <= words[i].e+1 then
					setCursor( (words[i].type == "word") and (words[i-1] and words[i-1].s) or words[i].s, y )
					break
				end
			end
		else
			if x > 1 then
				setCursor( x-1, y )
			elseif y > 1 then
				setCursor( #file[y-1]+1, y-1 )
			end
		end
	elseif key == "pageup" then
		yScroll = math.max( yScroll - screen.charHeight, 0 )
		setCursor( x, math.max(y-screen.charHeight, 1) )
	elseif key == "pagedown" then
		yScroll = math.min( yScroll + screen.charHeight, #file - screen.charHeight )
		setCursor( x, math.min(y+screen.charHeight, #file) )
	elseif key == "end" then
		setCursor( #file[y]+1, y )
	elseif key == "home" then
		setCursor( 1, y )
	elseif event.keyDown("ctrl") then
		if key == "e" or key == "q" then
			running = false
			os.sleep()
		elseif key == "s" then
			save()
		end
	end
end

-- Run
while running do
	draw()
	local event, param = event.wait()
	if event == "key" then
		keyPress(param)
	elseif event == "char" then
		file[y] = string.sub( file[y], 1, x-1 )..param..string.sub( file[y], x )
		setCursor( x+1, y )
	elseif event == "timer" and param == timer then
		cursor = not cursor
		timer = os.startTimer(0.5)
	end
end

-- Close
screen.clear("black")
screen.pos.x, screen.pos.y = 1, 1