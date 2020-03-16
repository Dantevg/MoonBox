-- Themes
local themes = {}
themes.dark = {
	background = "gray-2",
	linenumbers = "gray+2",
	toolbarbg = "gray-1",
	toolbartext = "gray+1",
	selectionbg = "blue-1",
	selectiontext = "white",
	comment = "gray",
	string = "green+1",
	number = "red+1",
	punctuation = "gray+1",
	keyword = "yellow+1",
	word = "white",
	whitespace = "white",
	other = "white",
}
themes.light = {
	background = "gray+3",
	linenumbers = "gray+1",
	toolbarbg = "blue",
	toolbartext = "white",
	selectionbg = "blue+3",
	comment = "gray",
	string = "green-1",
	number = "red+1",
	punctuation = "gray",
	keyword = "blue",
	word = "gray-2",
	whitespace = "gray-2",
	other = "gray-2",
}
themes.gray = {
	background = "gray-1",
	linenumbers = "gray+2",
	toolbarbg = "gray",
	toolbartext = "gray-1",
	selectionbg = "gray-2",
	selectiontext = "gray+1",
	comment = "gray-2",
	string = "black",
	number = "black",
	punctuation = "white",
	keyword = "white",
	word = "gray+1",
	whitespace = "gray+1",
	other = "gray+1"
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

local lines = {""}

if disk.exists(path) and disk.info(path).type == "file" then
	lines = disk.readLines(path)
	if not lines then
		error( "Couldn't open file", 2 )
	end
end

-- Convert tabs to spaces
for y = 1, #lines do
	lines[y] = string.gsub( lines[y], "\t", "  " )
end

-- Variables

local syntax = require "syntax"
if disk.getExtension(path) == ".md" then
	syntax = syntax( require("mdsyntax") )
else
	syntax = syntax( require("luasyntax") )
end

local lineStart = math.floor( math.log10(#lines) ) + 2 -- Width of line numbers

local running = true
local timer = os.startTimer(0.5)
local cursor = true
local x, y, xScroll, yScroll = 1, 1, 0, 0
local indent = 0
local selection


-- Functions
function save()
	disk.write( path, "" )
	for i = 1, #lines do
		disk.append( path, lines[i].."\n" )
	end
end

function setIndent()
	local _, _, s = string.find( lines[y], "^(%s+)" )
	if s then
		indent = math.floor( #s / 2 )
	else
		indent = 0
	end
end

function withinSelection( x, y )
	if not selection or not selection.from or not selection.to then return false end -- No selection
	if y > selection.from[2] and y < selection.to[2] then return true end            -- Complete line selected
	if y == selection.from[2] and y == selection.to[2] then                          -- Only one line selected
		return x >= selection.from[1] and x < selection.to[1]
	end
	if y == selection.from[2] and x >= selection.from[1] then return true end        -- First line of selection
	if y == selection.to[2] and x < selection.to[1] then return true end             -- Last line of selection
end

function getSelection()
	-- Only one line selected
	if selection.from[2] == selection.to[2] then
		return string.sub( lines[ selection.from[2] ], selection.from[1], selection.to[1]-1 )
	end
	
	-- Multiple lines selected
	local s = string.sub( lines[ selection.from[2] ], selection.from[1] )
	for line = selection.from[2]+1, selection.to[2]-1 do
		s = s.."\n"..lines[line]
	end
	s = s.."\n"..string.sub( lines[ selection.to[2] ], 1, selection.to[1]-1 )
	return s
end

function getWords(line)
	local words = {}
	local length = 1
	for word, separator in string.gmatch( lines[line], "(%w*)(%W*)" ) do
		table.insert( words, { type="word", data=word, s=length, e=length+#word-1 } )
		table.insert( words, { type="separator", data=separator, s=length+#word, e=length+#word+#separator-1 } )
		length = length + #word + #separator
	end
	return words
end

function drawLine( row, start )
	local line = lines[row+yScroll]
	local suggestion = #line>0 and x == #line+1 and syntax.autocomplete(line) or ""
	screen.setCharPos( 1, row )
	screen.setColour(theme.linenumbers)
	screen.write(row + yScroll)
	screen.setCharPos( start+1, row )
	
	local min = xScroll+1
	local max = math.min( screen.charWidth-start+xScroll, #line )
	local col = 0
	
	while #line > 0 and col < max do
		local match, type = syntax.match( line, col+1 )
		for i = math.max(min-col, 0), max-col do
			local bg = withinSelection( col+i, row+yScroll ) and theme.selectionbg or theme.background
			local colour = withinSelection( col+i, row+yScroll ) and theme.selectiontext or theme[type]
			screen.write( string.sub(match,i,i), {overflow="none", background=bg, colour = colour} )
		end
		col = col + #match
	end
	
	-- Suggestion
	screen.write( string.sub( suggestion, 1, screen.charWidth-start+xScroll-col ), {colour="gray"} )
end

function draw()
	-- Background
	screen.clear(theme.background)
	
	-- File contents, line numbers
	local maxY = math.min( screen.charHeight-1, #lines - yScroll )
	for row = 1, maxY do
		drawLine( row, lineStart )
	end
	
	-- Cursor
	if cursor then
		screen.setCharPos( x-xScroll + lineStart, y-yScroll )
		local x, y = screen.getPixelPos()
		screen.rect( x, y, screen.font.width, screen.font.height, theme.background )
		screen.setColour(theme.word)
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

function setCursor( newX, newY, select )
	if select and event.keyDown("shift") then
		selection = selection or { from = {x,y} }
		selection.to = { math.min(newX, #lines[y]+1), newY }
	else
		selection = nil
	end
	
	x, y = math.min(newX, #lines[newY]+1), newY
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
			lines[y] = ""
			for i = 1, #words do
				lines[y] = lines[y] .. words[i].data
			end
		else
			if x > 1 then
				lines[y] = string.sub( lines[y], 1, x-2 )..string.sub( lines[y], x )
				setCursor( x-1, y )
			elseif y > 1 then
				setCursor( #lines[y-1]+1, y-1 )
				lines[y] = lines[y] .. lines[y+1]
				table.remove( lines, y+1 )
			end
		end
		lineStart = math.floor( math.log10(#lines) ) + 2 -- Recalculate line number width
	elseif key == "delete" then
		if event.keyDown("ctrl") and x < #lines[y] then
			local words = getWords(y)
			for i = 1, #words do
				if x > words[i].s and x <= words[i].e+1 then
					words[i].data = string.sub( words[i].data, 1, x - words[i].s )
					break
				end
			end
			lines[y] = ""
			for i = 1, #words do
				lines[y] = lines[y] .. words[i].data
			end
		else
			if x <= #lines[y] then
				lines[y] = string.sub( lines[y], 1, x-1 )..string.sub( lines[y], x+1 )
			elseif y < #lines then
				lines[y] = lines[y] .. lines[y+1]
				table.remove( lines, y+1 )
			end
		end
		lineStart = math.floor( math.log10(#lines) ) + 2 -- Recalculate line number width
	elseif key == "enter" then
		table.insert( lines, y+1, "" )
		setIndent()
		lines[y+1] = string.rep( "  ", indent ) .. string.sub( lines[y], x, -1 )
		lines[y] = string.sub( lines[y], 1, x-1 )
		setCursor( indent*2+1, y+1 )
		lineStart = math.floor( math.log10(#lines) ) + 2 -- Recalculate line number width
	elseif key == "tab" then
		if event.keyDown("shift") then -- Remove one level of indentation
			if string.sub( lines[y], 1, 2 ) == "  " then
				lines[y] = string.sub( lines[y], 3 )
				x = x-2
			end
		else
			local completion = syntax.autocomplete( lines[y] )
			if #lines[y] > 0 and x == #lines[y]+1 and completion and completion ~= "" then -- Accept autocompletion
				lines[y] = lines[y] .. completion
				setCursor( x + #completion, y )
			else -- Insert tab
				lines[y] = string.sub( lines[y], 1, x-1 ).."  "..string.sub( lines[y], x, -1 )
				x = x+2
				setIndent()
			end
		end
	elseif key == "up" then
		if y > 1 then
			setCursor( math.min( x, #lines[y-1]+1 ), y-1 )
		else
			setCursor( 1, 1 )
		end
	elseif key == "right" then
		if event.keyDown("ctrl") and x < #lines[y] then
			local words = getWords(y)
			for i = 1, #words do
				if x >= words[i].s and x <= words[i].e then
					setCursor( (words[i].type == "separator") and words[i+1].e+1 or words[i].e+1, y, true )
					break
				end
			end
		else
			if x < #lines[y]+1 then
				setCursor( x+1, y, true )
			elseif y < #lines then
				setCursor( 1, y+1, true )
			end
		end
	elseif key == "down" then
		if y < #lines then
			setCursor( math.min( x, #lines[y+1]+1 ), y+1, true )
		else
			setCursor( #lines[y]+1, y, true )
		end
	elseif key == "left" then
		if event.keyDown("ctrl") and x > 1 then
			local words = getWords(y)
			for i = 1, #words do
				if x > words[i].s and x <= words[i].e+1 then
					setCursor( (words[i].type == "word") and (words[i-1] and words[i-1].s) or words[i].s, y, true )
					break
				end
			end
		else
			if x > 1 then
				setCursor( x-1, y, true )
			elseif y > 1 then
				setCursor( #lines[y-1]+1, y-1, true )
			end
		end
	elseif key == "pageup" then
		yScroll = math.max( yScroll - screen.charHeight, 0 )
		setCursor( x, math.max(y-screen.charHeight, 1), true )
	elseif key == "pagedown" then
		yScroll = math.min( yScroll + screen.charHeight, math.max( 0, #lines-screen.charHeight+1 ) )
		setCursor( x, math.min(y+screen.charHeight, #lines), true )
	elseif key == "end" then
		setCursor( #lines[y]+1, y, true )
	elseif key == "home" then
		setCursor( 1, y, true )
	elseif event.keyDown("ctrl") then
		if key == "e" or key == "q" then
			running = false
			os.sleep()
		elseif key == "s" then
			save()
		elseif key == "c" and selection then
			os.setClipboard( getSelection() )
		elseif key == "v" then
			local paste = os.getClipboard():gsub( "\r\n", "\n" ) -- CRLF (\r\n) -> LF (\n)
			paste = paste:gsub("\t", "  ") -- Convert tab to double space
			local before = string.sub( lines[y], 1, x-1 )
			local after = string.sub( lines[y], x )
			lines[y] = before
			for line in string.gmatch( paste, "(.-)\n" ) do
				lines[y] = lines[y]..line
				table.insert( lines, y+1, "" )
				setCursor( indent*2+1, y+1 )
			end
			local lastLine = string.match( paste, "[^\n]+$" ) or ""
			lines[y] = lines[y]..lastLine..after
			setCursor( x+#lastLine, y )
			lineStart = math.floor( math.log10(#lines) ) + 2 -- Recalculate line number width
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
		lines[y] = string.sub( lines[y], 1, x-1 )..p1..string.sub( lines[y], x )
		setCursor( x+1, y )
	elseif e == "timer" and p1 == timer then
		cursor = not cursor
		timer = os.startTimer(0.5)
	elseif e == "scroll" then
		yScroll = math.max( 0, math.min( yScroll - p3, #lines - screen.charHeight + 1 ) )
	elseif e == "mouse" then
		local x = math.ceil( p1 / (screen.font.width+1) - lineStart + xScroll )
		local y = math.ceil( p2 / (screen.font.height+1) + yScroll )
		setCursor( x, y )
	end
end

-- Close
screen.clear("black")
screen.pos.set(1,1)