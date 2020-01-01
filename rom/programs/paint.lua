-- CONSTANTS

local carbon = require "carbon"
local GUI = carbon()
local rainbow = {}
local brushes = {}
local wPicker, hPicker = 5, 10
local wSelected = #screen.colors["white"] / 2 * wPicker



-- VARIABLES

local running = true
local inMenu = false
local primary = "white"
local secondary = "blue"
local brush = "pencil" -- "pixel", "pencil", "line", "rect", "circle"
local zoom = 1
local zoomInt = 1

local name = ""
local image
local overlay



-- HELPER FUNCTIONS

function encode()
	
end

function decode(file)
	
end

function open(path)
	local foundPath = shell.find( path, "f" )

	if foundPath then
		path = foundPath
		local file = disk.read(path)
		name = disk.getFilename(path)
		image = decode(file)
	else
		name = disk.getFilename(path)
		path = shell.absolute(path)
	end
end

function new()
	image = screen.newCanvas( tonumber(prompt("Width: ")), tonumber(prompt("Height: ")) )
	image:clear("black")
	overlay = screen.newCanvas( image.w, image.h )
end

function prompt(name)
	screen.rect( 1, screen.height-9, screen.width, 10, "black" )
	screen.write( name, 1, screen.height-8 )
	return read()
end

function getImageCoords( x, y )
	if x > wPicker*7 and y < screen.height-10 and image then -- Drawing area
		local xImg = math.ceil( (x-wPicker*7) / zoomInt )
		local yImg = math.ceil( y / zoomInt )
		if xImg <= image.w and yImg <= image.h then
			return xImg, yImg
		end
	end
end



-- MENU

local currentMenu
local menu = {}
menu.main = {
	{name = "brush", type = "menu", data = "brush"},
	selected = 1
}
menu.brush = {
	{name = "BRUSH", type = "menu", data = "main"},
	{name = "pixel", type = "select", data = "pixel"},
	{name = "pencil", type = "select", data = "pencil"},
	{name = "line", type = "select", data = "line"},
	{name = "rect", type = "select", data = "rect"},
	{name = "circle", type = "select", data = "circle"},
	select = function(s)
		brush = s
		for i = 1, #menu.main do
			if menu.main[i].name == "options" then
				table.remove( menu.main, i )
			end
		end
		if brushes[brush].options then
			menu.options = {}
			table.insert( menu.main, {name = "options", type = "menu", data = "options"} )
			table.insert( menu.options, {name = "OPTIONS", type = "menu", data = "main"} )
			for k, v in pairs(brushes[brush].options) do
				table.insert( menu.options, {name = k, type = "input.boolean", source = brushes[brush].options, data = v} )
			end
		end
		currentMenu = menu.main
		inMenu = false
	end,
	selected = 1,
}
currentMenu = menu.main




-- BRUSHES

brushes.pixel = {}
function brushes.pixel.mouse( x, y, btn )
	local xImg, yImg = getImageCoords( x, y )
	if not xImg then return end
	image:pixel( xImg, yImg, btn == 1 and primary or (btn == 2 and secondary) )
end
function brushes.pixel.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	image:pixel( xImg, yImg, btn == 1 and primary or (btn == 2 and secondary) )
end

brushes.pencil = {}
function brushes.pencil.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	image:line( brushes.pencil.prevX or xImg, brushes.pencil.prevY or yImg, xImg, yImg, btn == 1 and primary or (btn == 2 and secondary) )
	brushes.pencil.prevX, brushes.pencil.prevY = xImg, yImg
end
function brushes.pencil.mouseUp( x, y, btn )
	brushes.pencil.prevX, brushes.pencil.prevY = nil, nil
end

brushes.line = {}
function brushes.line.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.drag.x, mouse.drag.y )
	if not xImg then return end
	brushes.line.startX, brushes.line.startY = xImg, yImg
	
	local x, y = getImageCoords( mouse.x, mouse.y )
	if not x then return end
	overlay:clear()
	overlay:line( xImg, yImg, x, y, "gray" )
end
function brushes.line.mouseUp( x, y, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	image:line( brushes.line.startX, brushes.line.startY, xImg, yImg, btn == 1 and primary or (btn == 2 and secondary) )
	overlay:clear()
end

brushes.rect = {}
brushes.rect.options = {
	fill = false
}
function brushes.rect.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.drag.x, mouse.drag.y )
	if not xImg then return end
	brushes.rect.startX, brushes.rect.startY = xImg, yImg
	
	local x, y = getImageCoords( mouse.x, mouse.y )
	overlay:clear()
	overlay:rect( xImg, yImg, x-xImg+1, y-yImg+1, "gray", brushes.rect.options.fill )
end
function brushes.rect.mouseUp( x, y, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	local startX, startY = brushes.rect.startX, brushes.rect.startY
	image:rect( startX, startY, xImg-startX+1, yImg-startY+1, btn == 1 and primary or (btn == 2 and secondary), brushes.rect.options.fill )
	overlay:clear()
end

brushes.circle = {}
brushes.circle.options = {
	fill = false
}
function brushes.circle.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.drag.x, mouse.drag.y )
	if not xImg then return end
	brushes.circle.startX, brushes.circle.startY = xImg, yImg
	
	local x, y = getImageCoords( mouse.x, mouse.y )
	overlay:clear()
	overlay:circle( xImg, yImg, math.sqrt( (x-xImg)^2 + (y-yImg)^2 ), "gray", brushes.circle.options.fill )
end
function brushes.circle.mouseUp( x, y, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	local startX, startY = brushes.circle.startX, brushes.circle.startY
	local r = math.sqrt( (xImg-startX)^2 + (yImg-startY)^2 )
	image:circle( startX, startY, r, btn == 1 and primary or (btn == 2 and secondary), brushes.circle.options.fill )
	overlay:clear()
end



-- EVENT FUNCTIONS

local events = {}

function events.mouse( x, y, btn )
	if x < wPicker*7 and y < #rainbow*hPicker then -- Color picker
		local color = rainbow[ math.floor(y/hPicker)+1 ]
		local brightness = math.floor(x/wPicker) - 3
		if btn == 1 then
			primary = colors.compose( color, brightness )
		elseif btn == 2 then
			secondary = colors.compose( color, brightness )
		end
	elseif y > screen.height-10 then -- Toolbar
		
	end
end

function events.scroll( x, y, dir )
	zoom = math.max( 1, zoom + dir/5 )
	zoomInt = math.floor(zoom)
end



-- PROGRAM FUNCTIONS

function draw()
	screen.clear("gray-2")
	
	-- Image
	if image then
		image:draw( wPicker*7, 1, zoomInt )
		if overlay then overlay:draw( wPicker*7, 1, zoomInt ) end
	end
	
	-- Toolbar
	-- GUI:draw()
	screen.rect( 1, screen.height-9, screen.width, 10, "black" )
	screen.write( name, {x=1, y=screen.height-8, color="gray-1", overflow="ellipsis", max=9} )
	screen.write( "x"..zoomInt, {x=60, y=screen.height-8, color="gray+1"} )
	screen.write( brush, {x=90, y=screen.height-8, color="gray+1"} )
	
	-- Color picker
	screen.rect( 1, 1, wPicker*7, screen.height-10, "black" )
	for i = 1, #rainbow do
		for brightness = -3, 3 do
			screen.rect( (brightness+3)*wPicker, (i-1)*hPicker, wPicker, hPicker, colors.compose(rainbow[i], brightness) )
		end
	end
	
	-- Selected colors
	screen.rect( 1, #rainbow*hPicker + 1, wSelected - 1, hPicker, primary )
	screen.rect( wSelected + 1, #rainbow*hPicker + 1, wSelected - 1, hPicker, secondary )
	
	-- Menu
	if inMenu then
		screen.rect( 1, screen.height-9, screen.width, 10, "black" )
		local x = 1
		for i = 1, #currentMenu do
			local color = currentMenu.selected == i and "white" or "gray-1"
			screen.write( currentMenu[i].name, {x=x, y=screen.height-8, background=bg, color=color} )
			if currentMenu[i].type == "input.boolean" and currentMenu[i].data == true then
				screen.rect( x, screen.height, (#currentMenu[i].name) * (screen.font.width+1), 2, "white" )
			end
			x = x + (#currentMenu[i].name+1) * (screen.font.width+1)
		end
	end
end



-- INIT

-- Fill rainbow
for name, color in pairs(screen.colors) do
	table.insert( rainbow, name )
end
-- Sorts by hue, if same hue sorts by saturisation, if same saturisation sorts by lightness
-- "Welcome to ternary hell!" ;)
table.sort( rainbow, function(a,b)
	return ({colors.hsl(a)})[1] == ({colors.hsl(b)})[1]
		and ( ({colors.hsl(a)})[2] == ({colors.hsl(b)})[2]
			and ({colors.hsl(a)})[3] > ({colors.hsl(b)})[3] -- Lightness
			or ({colors.hsl(a)})[2] < ({colors.hsl(b)})[2] ) -- Saturisation
		or colors.hsl(a) < colors.hsl(b) -- Hue
	end )

local path = ...

if path then
	open(path)
end



-- MAIN LOOP

while running do
	draw()
	if not image then new() end
	local e = {event.wait()}
	GUI:event( unpack(e) )
	if e[1] == "key" then
		if event.keyDown("ctrl") then
			if e[2] == "q" then
				running = false
				break
			elseif e[2] == "s" then
				save()
			-- elseif e[2] == "c" then
			-- 	console()
			end
		elseif e[2] == "escape" then
			inMenu = not inMenu
			currentMenu = menu.main
			currentMenu.selected = 1
		elseif inMenu then
			if e[2] == "left" then
				repeat
					currentMenu.selected = (currentMenu.selected-2) % #currentMenu + 1
				until currentMenu[currentMenu.selected].type ~= "text"
			elseif e[2] == "right" then
				repeat
					currentMenu.selected = (currentMenu.selected) % #currentMenu + 1
				until currentMenu[currentMenu.selected].type ~= "text"
			elseif e[2] == "enter" then
				local selected = currentMenu[currentMenu.selected]
				if selected.type == "menu" then
					currentMenu = menu[selected.data]
					currentMenu.selected = 1
				elseif selected.type == "input.boolean" then
					selected.data = not selected.data
					selected.source[selected.name] = not selected.source[selected.name]
				elseif selected.type == "select" then
					currentMenu.select(selected.data)
				end
			end
		end
	elseif events[e[1]] then
		events[e[1]]( unpack(e,2) )
	end
	if brushes[brush][e[1]] then
		brushes[brush][e[1]]( unpack(e,2) )
	end
end



-- CLOSE

screen.clear("black")
screen.pos.x, screen.pos.y = 1, 1