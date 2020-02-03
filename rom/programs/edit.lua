-- Themes
local themes = {}
themes.dark = {
	background = "gray-2",
	linenumbers = "gray+2",
	toolbarbg = "gray-1",
	toolbartext = "gray+1",
	text = "white",
	comment = "gray",
	string = "green+1",
	number = "red+1",
	keyword = "yellow+1",
	boolean = "orange+2",
	["self"] = "blue+2",
	punctuation = "gray+2"
}
themes.light = {
	background = "gray+3",
	linenumbers = "gray+1",
	toolbarbg = "blue",
	toolbartext = "white",
	text = "gray-2",
	comment = "gray",
	string = "green-1",
	number = "red+1",
	keyword = "blue",
	boolean = "yellow",
	["self"] = "purple",
	punctuation = "gray"
}
themes.gray = {
	background = "gray-1",
	linenumbers = "gray+2",
	toolbarbg = "gray",
	toolbartext = "gray-1",
	text = "gray+1",
	comment = "gray-2",
	string = "white",
	number = "gray-2",
	keyword = "white",
	boolean = "black",
	["self"] = "gray+2",
	punctuation = "white"
}

local theme = themes.dark

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
	["false"] = theme.boolean,
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
	["self"] = theme["self"],
	["then"] = true,
	["true"] = theme.boolean,
	["until"]= true,
	["while"] = true,
}

local patterns = {
	-- Comments
	{"^%-%-%[%[.-%]%]", theme.comment},
	{"^%-%-.*", theme.comment},
	-- Strings
	{"^\"\"", theme.string},
	{"^\".-[^\\]\"", theme.string},
	{"^\'\'", theme.string},
	{"^\'.-[^\\]\'", theme.string},
	{"^%[%[.-%]%]", theme.string},
	-- Numbers
	{"^%d+", theme.number},
	-- (Key)words
	{"^[%w_]+", function(match)
		if keywords[match] == true then
			return theme.keyword
		elseif keywords[match] then
			return keywords[match]
		else
			return theme.text
		end
	end},
	{"^%p", theme.punctuation},
	-- Everything else
	{"^[^%w_]", theme.text}
}

local lineStart = math.floor( math.log10(#file) ) + 2 -- Width of line numbers

local running = true
local timer = os.startTimer(0.5)
local cursor = true
local x, y, xScroll, yScroll = 1, 1, 0, 0
local indent = 0
local selection


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

function autocomplete(input)
	local start = string.find( input, "[a-zA-Z0-9%.]+$" )
	input = string.sub( input, start or 1 )
	start = 1
	
	-- Traverse through environment tables to get to input destination
	local t = _G
	local dot = string.find( input, ".", start, true )
	while dot do
		local part = string.sub( input, start, dot-1 )
		if type( t[part] ) == "table" then
			t = t[part]
			start = dot + 1
			dot = string.find( input, ".", start, true )
		else
			return ""
		end
	end
	
	-- Find element in keywords
	local part = string.sub( input, start )
	if t == _G then
		for k, v in pairs(keywords) do
			if string.sub( k, 1, #part ) == part then
				return string.sub( k, #part+1 )
			end
		end
	end
	
	-- Find element in table
	for k, v in pairs(t) do
		if string.sub( k, 1, #part ) == part and type(k) == "string" then
			local suffix = type(v) == "table" and "." or (type(v) == "function" and "(" or "")
			return string.sub( k..suffix, #part+1 )
		end
	end
end

function drawLine( row, start )
	local line = file[row+yScroll]
	local suggestion = #line>0 and y == row and x == #line+1 and autocomplete(line) or ""
	screen.setCharPos( 1, row )
	screen.setColour(theme.linenumbers)
	screen.write(row + yScroll)
	screen.setCharPos( start+1, row )
	
	local min = xScroll+1
	local max = math.min( screen.charWidth-start+xScroll, #line )
	local col = 0
	
	while #line > 0 and col < max do
		for i = 1, #patterns do
			local match = string.match( line, patterns[i][1] )
			if match then
				screen.setColour( type(patterns[i][2]) == "string" and patterns[i][2] or patterns[i][2](match) )
				local bg = theme.background
				if selection then
					if row > selection[1][2] and row < selection[2][2]
						or row == selection[1][2] and col >= selection[1][1]
						or row == selection[2][2] and col <= selection[2][1] then
						bg = "blue+2"
					end
				end
				screen.write( string.sub( match, math.max(min-col, 0), max-col ), {background=bg} )
				line = string.sub( line, #match+1 )
				col = col + #match
				break
			end
		end
	end
	
	-- Suggestion
	screen.write( string.sub( suggestion, 1, screen.charWidth-start+xScroll-col ), {colour="gray"} )
end

function draw()
	-- Background
	screen.clear(theme.background)
	
	-- File contents, line numbers
	local maxY = math.min( screen.charHeight-1, #file - yScroll )
	for row = 1, maxY do
		drawLine( row, lineStart )
	end
	
	-- Cursor
	if cursor then
		screen.setCharPos( x-xScroll + lineStart, y-yScroll )
		local x, y = screen.getPixelPos()
		screen.rect( x, y, screen.font.width, screen.font.height, theme.background )
		screen.setColour(theme.text)
		screen.cursor( x, y+1 )
	end
	
	-- File info
	local h = screen.height - screen.font.height + 1
	screen.rect( 1, screen.height - screen.font.height, screen.width, screen.font.height+1, theme.toolbarbg )
	screen.setColour(theme.toolbartext)
	screen.write( disk.getFilename(path), 1, h )
	screen.setCharPos( screen.charWidth-#(x..":"..y) + 1, screen.charHeight )
	screen.write( x..":"..y, screen.width-(screen.font.width+1) * #(x..":"..y) + 1, h )
end

function setCursor( newX, newY )
	if event.keyDown("shift") then
		selection = selection or { {x,y} }
		selection[2] = { math.min(newX, #file[y]+1), newY }
	else
		selection = nil
	end
	
	x, y = math.min(newX, #file[newY]+1), newY
	local w = math.floor( screen.charWidth - 1 )
	local h = math.floor( screen.charHeight + 1 )
	
	local xScreen = x - xScroll + lineStart - 1
	local yScreen = y - yScroll
	
	if xScreen <= lineStart then
		xScroll = x - 1
	elseif xScreen >= w then
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
		lineStart = math.floor( math.log10(#file) ) + 2 -- Recalculate line number width
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
		lineStart = math.floor( math.log10(#file) ) + 2 -- Recalculate line number width
	elseif key == "enter" then
		table.insert( file, y+1, "" )
		setIndent()
		file[y+1] = string.rep( "  ", indent ) .. string.sub( file[y], x, -1 )
		file[y] = string.sub( file[y], 1, x-1 )
		setCursor( indent*2+1, y+1 )
		lineStart = math.floor( math.log10(#file) ) + 2 -- Recalculate line number width
	elseif key == "tab" then
		if event.keyDown("shift") then -- Remove one level of indentation
			if string.sub( file[y], 1, 2 ) == "  " then
				file[y] = string.sub( file[y], 3 )
				x = x-2
			end
		else
			local completion = autocomplete( file[y] )
			if #file[y] > 0 and x == #file[y]+1 and completion and completion ~= "" then -- Accept autocompletion
				file[y] = file[y] .. completion
				setCursor( x + #completion, y )
			else -- Insert tab
				file[y] = string.sub( file[y], 1, x-1 ).."  "..string.sub( file[y], x, -1 )
				x = x+2
				setIndent()
			end
		end
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
		yScroll = math.min( yScroll + screen.charHeight, math.max( 0, #file-screen.charHeight+1 ) )
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
	local e, p1, p2, p3 = event.wait()
	if e == "key" then
		keyPress(p1)
	elseif e == "char" then
		file[y] = string.sub( file[y], 1, x-1 )..p1..string.sub( file[y], x )
		setCursor( x+1, y )
	elseif e == "timer" and p1 == timer then
		cursor = not cursor
		timer = os.startTimer(0.5)
	elseif e == "scroll" then
		yScroll = math.max( 0, math.min( yScroll - p3, #file - screen.charHeight + 1 ) )
	elseif e == "mouse" then
		local x = math.ceil( p1 / (screen.font.width+1) - lineStart + xScroll )
		local y = math.ceil( p2 / (screen.font.height+1) + yScroll )
		setCursor( x, y )
	end
end

-- Close
screen.clear("black")
screen.pos.set(1,1)