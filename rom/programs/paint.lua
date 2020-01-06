--[[
	
	Paint program
	by RedPolygon
	
	for MoonBox
	
]]--

-- CONSTANTS

local he = helium.new( 1, 1, screen.width, screen.height )
local gui = {}
local brushes = {}
local margin = 10
local bgScale = 10



-- VARIABLES

local running = true
local inMenu = false
local zoom = 1
local zoomInt = 1
local ox, oy = 1, 1
local primary = "white"
local secondary = "blue"
local brush = "pixel" -- "pixel", "pencil", "line", "rect", "circle"

local path
local image
local overlay



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
-- Images for brushes (16x16 png, base64 encoded)
brushes.pixel.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUpKSn///+UkWbiAAAAEUlEQVR4nGNgwADMBxAIAwAAR9YDDfFoq3wAAAAASUVORK5CYII="

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
brushes.pencil.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUpKSn///+UkWbiAAAAI0lEQVR4nGNgYGCoYGBgYWBgAiNGGGJogCEHMDJgYOADigIAOiUCwm2RpdIAAAAASUVORK5CYII="

brushes.line = {}
function brushes.line.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.drag.x, mouse.drag.y )
	if not xImg then return end
	brushes.line.startX, brushes.line.startY = xImg, yImg
	
	local x, y = getImageCoords( mouse.x, mouse.y )
	if not x then return end
	overlay:clear()
	overlay:line( xImg, yImg, x, y, "gray (0.5)" )
end
function brushes.line.mouseUp( x, y, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	image:line( brushes.line.startX, brushes.line.startY, xImg, yImg, btn == 1 and primary or (btn == 2 and secondary) )
	overlay:clear()
end
brushes.line.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUpKSn///+UkWbiAAAAK0lEQVR4nGNgYGBIYGAoYGCwYGCQYWDgY2BgZ2BgbmBgPMDA8ABVgg2oFgBqvgQ2wlA5YQAAAABJRU5ErkJggg=="

brushes.rect = {}
brushes.rect.options = {
	fill = true
}
function brushes.rect.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.drag.x, mouse.drag.y )
	if not xImg then return end
	brushes.rect.startX, brushes.rect.startY = xImg, yImg
	
	local x, y = getImageCoords( mouse.x, mouse.y )
	if not x then return end
	overlay:clear()
	if x < xImg then x, xImg = xImg, x end
	if y < yImg then y, yImg = yImg, y end
	overlay:rect( xImg, yImg, x-xImg+1, y-yImg+1, "gray (0.5)", brushes.rect.options.fill )
end
function brushes.rect.mouseUp( x, y, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	local startX, startY = brushes.rect.startX, brushes.rect.startY
	if not xImg or not startX then return end
	if xImg < startX then startX, xImg = xImg, startX end
	if yImg < startY then startY, yImg = yImg, startY end
	image:rect( startX, startY, xImg-startX+1, yImg-startY+1, btn == 1 and primary or (btn == 2 and secondary), brushes.rect.options.fill )
	overlay:clear()
end
brushes.rect.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAACVBMVEUpKSmrq6v/////1S+2AAAAHUlEQVR4nGNgAAFRMLFq1QIIwUU8EQIhgABMMAAAt+4X0BBAqu0AAAAASUVORK5CYII="

brushes.circle = {}
brushes.circle.options = {
	fill = true
}
function brushes.circle.drag( dx, dy, btn )
	local xImg, yImg = getImageCoords( mouse.drag.x, mouse.drag.y )
	if not xImg then return end
	brushes.circle.startX, brushes.circle.startY = xImg, yImg
	
	local x, y = getImageCoords( mouse.x, mouse.y )
	overlay:clear()
	overlay:circle( xImg, yImg, math.sqrt( (x-xImg)^2 + (y-yImg)^2 ), "gray (0.5)", brushes.circle.options.fill )
end
function brushes.circle.mouseUp( x, y, btn )
	local xImg, yImg = getImageCoords( mouse.x, mouse.y )
	if not xImg then return end
	local startX, startY = brushes.circle.startX, brushes.circle.startY
	local r = math.sqrt( (xImg-startX)^2 + (yImg-startY)^2 )
	image:circle( startX, startY, r, btn == 1 and primary or (btn == 2 and secondary), brushes.circle.options.fill )
	overlay:clear()
end
brushes.circle.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAQMAAAAlPW0iAAAABlBMVEUpKSn///+UkWbiAAAAJklEQVR4nGNgYGBgPsDA/4FB/geD/R8Qqv+HQBARoBRQAVAZAwMAiQAQk9vnA4wAAAAASUVORK5CYII="

brushes.drag = {}
function brushes.drag.drag( dx, dy, btn )
	if mouse.x <= gui.paint.obj.picker.w() then return end
	ox, oy = ox + dx/zoomInt, oy + dy/zoomInt
end



-- GUI

he.w = function() return screen.width end
he.h = function() return screen.height end

local colourPicker = {}
function colourPicker.new( p, x, y, w, h )
	local obj = {}
	
	obj.rainbow = {}
	for name, color in pairs(screen.colors) do
		table.insert( obj.rainbow, name )
	end
	-- Sorts by hue, if same hue sorts by saturisation, if same saturisation sorts by lightness
	-- Welcome to ternary hell ;)
	table.sort( obj.rainbow, function(a,b)
		return ({colors.hsl(a)})[1] == ({colors.hsl(b)})[1]
			and ( ({colors.hsl(a)})[2] == ({colors.hsl(b)})[2]
				and ({colors.hsl(a)})[3] > ({colors.hsl(b)})[3] -- Lightness
				or ({colors.hsl(a)})[2] < ({colors.hsl(b)})[2] ) -- Saturisation
			or colors.hsl(a) < colors.hsl(b) -- Hue
		end )
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"colourPicker", "*"}
	obj.x = helium.make.x(obj, x)
	obj.y = helium.make.y(obj, y)
	obj.w = helium.proxy( w * 7 )
	obj.h = helium.proxy( h * #obj.rainbow )
	
	obj.wColour = helium.proxy(w)
	obj.hColour = helium.proxy(h)
	
	return setmetatable( obj, {__index = colourPicker} )
end
function colourPicker:draw(parent)
	self.parent = parent or self.parent
	screen.rect( self.x(), self.y(), self.w(), self.h(), "black" )
	for i = 1, #self.rainbow do
		for brightness = -3, 3 do
			screen.rect( (brightness+3)*self.wColour(), (i-1)*self.hColour(), self.wColour(), self.hColour(), colors.compose(self.rainbow[i], brightness) )
		end
	end
end
function colourPicker:mouse( x, y, btn )
	if not self:within( x, y ) then return end
	x, y = self:toLocalCoords( x, y )
	
	local color = self.rainbow[ math.floor(y/self.hColour())+1 ]
	local brightness = math.floor(x/self.wColour()) - 3
	if not color or not brightness then return end
	
	if btn == 1 then
		primary = colors.compose( color, brightness, gui.paint.obj.picker.obj.primaryOpacity.value )
	elseif btn == 2 then
		secondary = colors.compose( color, brightness, gui.paint.obj.picker.obj.secondaryOpacity.value )
	end
end
setmetatable( colourPicker, {
	__index = helium,
	__call = function( _, ... ) return colourPicker.new(...) end
})

he.styles.input = {
	padding = 1,
	border = "gray+1",
	background = "white",
	mouse = function( self, x, y, btn )
		if self:within( x, y ) then
			eachObj( gui.menu, function(obj)
				if obj:hasTag("active") then
					obj:removeTag("active")
					obj.read.cursor = false
				end
			end )
			self:addTag("active")
			self.read.timer = os.startTimer(0.5)
			self.read.cursor = true
			self.read.pos = #self.read.history[self.read.selected] + 1
		end
	end
}

he.styles.button = {
	color = "white",
	background = "gray-1",
	activeColor = "white",
	activeBackground = "gray",
}

gui.paint = he:box( 1, 1, nil, nil, "black (0)" )
gui.paint:autosize( "wh", he )
gui.paint.obj = {}

	gui.paint.obj.picker = colourPicker( gui.paint, 1, 1, 5, 10 )
	gui.paint.obj.picker.h = function() return he.h() - 10 end
	gui.paint.obj.picker.obj = {}
	local Picker = gui.paint.obj.picker

		Picker.obj.primary = Picker:box( 1, Picker.hColour() * #Picker.rainbow + 1, Picker.w()/2 - 1, 10, function() return colors.compose( colors.getName(primary), colors.getBrightness(primary) ) end )
		Picker.obj.secondary = Picker:box( Picker.w()/2+1, Picker.hColour() * #Picker.rainbow + 1, Picker.w()/2 - 1, 10, function() return colors.compose( colors.getName(secondary), colors.getBrightness(secondary) ) end )
		
		Picker.obj.primaryOpacity = Picker:slider( 1, Picker.obj.primary.y() + Picker.obj.primary.h() + 1, Picker.w()/2 - 1, 10 )
		Picker.obj.primaryOpacity.callback = function( self, value )
			primary = colors.compose( colors.getName(primary), colors.getBrightness(primary), value )
		end
		Picker.obj.primaryOpacity.value = 1
		
		Picker.obj.secondaryOpacity = Picker:slider( Picker.w()/2+1, Picker.obj.primary.y() + Picker.obj.primary.h() + 1, Picker.w()/2 - 1, 10 )
		Picker.obj.secondaryOpacity.callback = function( self, value )
			secondary = colors.compose( colors.getName(secondary), colors.getBrightness(secondary), value )
		end
		Picker.obj.secondaryOpacity.value = 1
		
		local xOff, yOff = 2, 1
		for b in pairs(brushes) do
			if brushes[b].image then
				local y = yOff
				local img = screen.loadImage( math.decode64(brushes[b].image) )
				Picker.obj[b] = Picker:image( xOff, nil, img )
				Picker.obj[b].y = function() return Picker.obj.primaryOpacity.y() + Picker.obj.primaryOpacity.h() + y end
				Picker.obj[b].mouse = function( self, x, y, btn )
					if self:within( x, y ) then brush = b end
				end
				xOff = xOff + img.w + 1
				if xOff + img.w > Picker.w() then
					xOff = 2
					yOff = yOff + img.h + 1
				end
			end
		end
		
	gui.paint.obj.toolbar = gui.paint:box( 1, nil, nil, 10, "black" )
	gui.paint.obj.toolbar.y = function() return screen.height - 9 end
	gui.paint.obj.toolbar.w = function() return screen.width end
	gui.paint.obj.toolbar.obj = {}
	local Toolbar = gui.paint.obj.toolbar
		
		Toolbar.obj.file = Toolbar:text( 1, nil, function() return path or "no file opened" end, function() return path and "gray" or "gray-2" end )
		Toolbar.obj.file:center("y")
		
		Toolbar.obj.brush = Toolbar:text( nil, nil, function() return brush end, "gray" )
		Toolbar.obj.brush.x = function() return Toolbar.obj.file.x() + Toolbar.obj.file.w() + 10 end
		Toolbar.obj.brush:center("y")
		Toolbar.obj.brush.mouseUp = function( self, x, y, btn )
			if not self:within( x, y ) then return end
			local b = {}
			for k in pairs(brushes) do
				table.insert( b, k )
			end
			for i = 1, #b do
				if b[i] == brush then
					brush = b[ i % #b + 1 ]
					return
				end
			end
		end
		
		Toolbar.obj.zoom = Toolbar:text( nil, nil, function() return zoomInt.."x" end, "gray" )
		Toolbar.obj.zoom.x = function() return Toolbar.obj.brush.x() + Toolbar.obj.brush.w() + 10 end
		Toolbar.obj.zoom:center("y")

gui.menu = he:box( 1, 1, nil, nil, "gray+2" )
gui.menu:autosize( "wh", he )
gui.menu.obj = {}

	gui.menu.obj.path = gui.menu:box( margin, margin, nil, 20, "gray+2" )
	gui.menu.obj.path:autosize( "w", -margin, gui.menu )
	gui.menu.obj.path.obj = {}
	local Path = gui.menu.obj.path

		Path.obj.title = Path:text( 1, 1, "OPEN/SAVE", "black" )
		
		Path.obj.input = Path:input( 1, nil, nil, screen.font.height, "black" )
		Path.obj.input.y = function() return Path.obj.title.y() + Path.obj.title.h() + 5 end
		Path.obj.input:autosize( "w", Path )
		Path.obj.input.border = function(obj)
			if #obj.read.history[obj.read.selected] == 0 then
				return "gray+1"
			else
				return disk.info( obj.read.history[obj.read.selected] ).type == "file" and "blue" or "orange"
			end
		end
		Path.obj.input.background = function(obj)
			if #obj.read.history[obj.read.selected] == 0 or not obj:hasTag("active") then
				return "white"
			else
				return disk.info( obj.read.history[obj.read.selected] ).type == "file" and "blue+3" or "orange+3"
			end
		end
		Path.obj.input.callback = function( self, input )
			self:removeTag("active")
		end
		
		local buttonWidth = function() return (Path.w() - margin)/2
		end
		
		Path.obj.open = Path:button( 1, nil, nil, 11, "OPEN" )
		Path.obj.open.y = function() return Path.obj.input.y() + Path.obj.input.h() + 5 end
		Path.obj.open.w = buttonWidth
		Path.obj.open.callback = function()
			if loadFile( Path.obj.input.read.history[Path.obj.input.read.selected] ) then
				inMenu = false
			end
		end
		
		Path.obj.save = Path:button( nil, nil, nil, 11, "SAVE" )
		Path.obj.save.x = function() return Path.x() + Path.w() - buttonWidth() end
		Path.obj.save.y = function() return Path.obj.input.y() + Path.obj.input.h() + 5 end
		Path.obj.save.w = buttonWidth
		Path.obj.save.callback = function()
			if saveFile( Path.obj.input.read.history[Path.obj.input.read.selected] ) then
				inMenu = false
			end
		end
	
	Path:autosize( "h", 5, Path.obj.title, Path.obj.input, Path.obj.open, Path.obj.save )

	gui.menu.obj.create = gui.menu:box( margin, nil, nil, 20, "gray+2" )
	gui.menu.obj.create:autosize( "w", -margin, gui.menu )
	gui.menu.obj.create.y = function() return Path.y() + Path.h() + margin end
	gui.menu.obj.create.obj = {}
	local Create = gui.menu.obj.create

		Create.obj.title = Create:text( 1, 1, "NEW IMAGE", "black" )
		
		Create.obj.widthLabel = Create:text( 1, nil, "Width", "black" )
		Create.obj.widthLabel.y = function() return Create.obj.title.y() + Create.obj.title.h() + 6 end
		Create.obj.width = Create:input( nil, nil, 50, screen.font.height-1, "black" )
		Create.obj.width.x = function() return Create.obj.widthLabel.x() + Create.obj.widthLabel.w() + 5 end
		Create.obj.width.y = function() return Create.obj.width.parent.obj.title.y() + Create.obj.width.parent.obj.title.h() + 5 end
		Create.obj.width.char = function( self, char )
			if string.find( char, "%d" ) then
				self:update( "char", char )
			end
		end
		Create.obj.width.key = function( self, key )
			self:update( "key", key )
			if key == "tab" and self:hasTag("active") then
				self:removeTag("active")
				self.read.cursor = false
				Create.obj.height:addTag("active")
				Create.obj.height.read.timer = os.startTimer(0.5)
				Create.obj.height.read.cursor = true
			end
		end
		Create.obj.width.callback = function(self)
			self:removeTag("active")
			Create.obj.submit:callback()
		end
		
		Create.obj.heightLabel = Create:text( nil, nil, "Height", "black" )
		Create.obj.heightLabel.x = function() return Create.obj.width.x() + Create.obj.width.w() + 20 end
		Create.obj.heightLabel.y = Create.obj.widthLabel.y
		Create.obj.height = Create:input( nil, nil, 50, screen.font.height-1, "black" )
		Create.obj.height.x = function() return Create.obj.heightLabel.x() + Create.obj.heightLabel.w() + 5 end
		Create.obj.height.y = function() return Create.obj.height.parent.obj.title.y() + Create.obj.height.parent.obj.title.h() + 5 end
		Create.obj.height.char = function( self, char )
			if string.find( char, "%d" ) then
				self:update( "char", char )
			end
		end
		Create.obj.height.callback = function(self)
			self:removeTag("active")
			Create.obj.submit:callback()
		end
		
		Create.obj.submit = Create:button( nil, nil, 50, 11, "CREATE" )
		Create.obj.submit.x = function() return Create.x() + Create.w() - Create.obj.submit.w() end
		Create.obj.submit.y = function() return Create.obj.title.y() + Create.obj.title.h() + 4 end
		Create.obj.submit.callback = function(obj)
			local width = Create.obj.width.read.history[ Create.obj.width.read.selected ]
			local height = Create.obj.height.read.history[ Create.obj.height.read.selected ]
			if not tonumber(width) or not tonumber(height) then return end
			createImage( tonumber(width), tonumber(height) )
			inMenu = false
		end
	
	Create:autosize( "h", 5, Create.obj.title, Create.obj.width )



-- HELPER FUNCTIONS

function createImage( width, height )
	image = screen.newCanvas( width, height )
	image:clear("black")
	overlay = screen.newCanvas( image.w, image.h )
end

function loadFile(p)
	if disk.info(p).type ~= "file" then return false end
	path = p
	
	local img = screen.loadImage(path)
	image = screen.newCanvas( img.w, img.h )
	overlay = screen.newCanvas( image.w, image.h )
	image:drawImage(img)
	
	return true
end

function saveFile(p)
	if not image or (disk.exists(p) and disk.info(p).type ~= "file") then return false end
	path = p
	
	local img = image.canvas:newImageData():encode("png")
	disk.write( path, img:getString() )
	
	return true
end

function getImageCoords( x, y )
	if x > gui.paint.obj.picker.w() and y < screen.height-10 and image then -- Drawing area
		local xImg = math.ceil( (x-gui.paint.obj.picker.w()) / zoomInt - ox + 1 )
		local yImg = math.ceil( y / zoomInt - oy + 1 )
		if xImg <= image.w and yImg <= image.h then
			return xImg, yImg
		end
	end
end

local events = {}

function events.key(key)
	if key == "escape" then
		inMenu = not inMenu
	elseif key == "q" and event.keyDown("ctrl") then
		screen.clear()
		screen.pos = {x=1,y=1}
		running = false
	elseif key == "s" and event.keyDown("ctrl") then
		saveFile(path)
	end
end

function events.mouse( x, y, btn )
	-- gui.paint.obj.picker:mouse( x, y, btn )
	eachObj( gui.menu, function(obj)
		if obj:hasTag("input") and obj:hasTag("active") then
			obj:removeTag("active")
			obj.read.cursor = false
		end
	end )
end

function events.scroll( x, y, dir )
	zoom = math.max( 1, zoom + dir/5 )
	zoomInt = math.floor(zoom)
end

function eachObj( obj, fn, ... )
	fn( obj, ... )
	if obj.obj then
		for k, v in pairs(obj.obj) do
			eachObj( v, fn, ... )
		end
	end
end

function propagateEvents( obj, e, ... )
	eachObj( obj, function( obj, e, ... )
		if obj[e] then obj[e]( obj, ... ) end
	end, e, ... )
end



-- PROGRAM FUNCTIONS

function draw(obj)
	-- Background
	screen.clear("gray-2")
	for x = 1, math.floor(screen.width/bgScale) do
		for y = 1, math.floor(screen.height/bgScale) do
			if (x+y) % 2 == 0 then
				screen.rect( (x-1)*bgScale+1, (y-1)*bgScale+1, bgScale, bgScale, "gray-3" )
			end
		end
	end
	
	-- Image
	if not inMenu and image then
		if event.keyDown("m") then
			image:draw( gui.paint.obj.picker.w(), 1, 0.2 )
			if overlay then overlay:draw( gui.paint.obj.picker.w(), 1, 0.2 ) end
		else
			image:draw( gui.paint.obj.picker.w() + (ox-1)*zoomInt + 1, (oy-1)*zoomInt + 1, zoomInt )
			if overlay then overlay:draw( gui.paint.obj.picker.w() + (ox-1)*zoomInt + 1, (oy-1)*zoomInt + 1, zoomInt ) end
		end
	end
	
	-- GUI
	eachObj( obj, function(obj) obj:draw() end )
end

function printUsage()
	print("Usage:")
	print("  paint <path>")
	print("  paint --new <width> <height>")
end



-- RUN

local arg = {...}
if #arg > 0 then
	if arg[1] == "--new" then
		if #arg < 3 then
			printUsage()
			return
		end
		createImage( tonumber(arg[2]), tonumber(arg[3]) )
	else
		local p = shell.find( arg[1] )
		if loadFile(p) then
			gui.menu.obj.path.obj.input.read.history[1] = p
		end
	end
end

while running do
	draw( inMenu and gui.menu or gui.paint )
	
	local e = {event.wait()}
	if events[ e[1] ] then
		events[ e[1] ]( unpack(e, 2) )
	end
	if not event.keyDown("m") and not inMenu then
		local b = event.keyDown("ctrl") and "drag" or brush
		if brushes[b][ e[1] ] then
			brushes[b][ e[1] ]( unpack(e, 2) )
		end
	end
	
	propagateEvents( inMenu and gui.menu or gui.paint, unpack(e) )
end