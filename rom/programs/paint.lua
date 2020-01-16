--[[
	
	Paint program
	by RedPolygon
	
	for MoonBox
	
]]--

-- CONSTANTS

local he = helium.new( 1, 1, screen.width, screen.height )
local gui = {}
local obj = { paint = {}, menu = {} }
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
brushes.pixel.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAACVBMVEUAAAApKSn///+ylTbtAAAAGUlEQVR4nGNgAAHR0NAQ7ETUUkwCl2IQAACJXRBfon9gmgAAAABJRU5ErkJggg=="

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
brushes.pencil.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAACVBMVEUAAAApKSn///+ylTbtAAAAJ0lEQVR4nGNgAAHR0NAQBqmlQEI0EkSE4SVCp8KJTBARtgRiAAgAAH6JEE/sRvsVAAAAAElFTkSuQmCC"

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
brushes.line.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAACVBMVEUAAAApKSn///+ylTbtAAAAOklEQVR4nGNgAAHR0NAQBikwMRVIiC0FEqIrQUQWiIiaCiTClgKJ0JUgIgtERE0BEmFLQHqXQAwAAQDAzhH0sxfzqAAAAABJRU5ErkJggg=="

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
brushes.rect.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAADFBMVEUAAAApKSmrq6v///9JX/HgAAAAKUlEQVR4nGNgAAHR0NAQBqmpIGL//ysQQvw/fuLfEgghGhq2BGIACAAAHe0hIQEioPYAAAAASUVORK5CYII="

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
brushes.circle.image = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAACVBMVEUAAAApKSn///+ylTbtAAAAL0lEQVR4nGNgAAHR0NAQBtGopUBi1aoQBrFVq6ZACKlVq5agEwhZsGKINpABIAAA00sYscPN9ocAAAAASUVORK5CYII="

brushes.drag = {}
function brushes.drag.drag( dx, dy, btn )
	if mouse.x <= gui.picker.w() then return end
	ox, oy = ox + dx/zoomInt, oy + dy/zoomInt
end



-- GUI

he.w = function() return screen.width end
he.h = function() return screen.height end

local colourPicker = {}
function colourPicker.new( p, x, y )
	local obj = {}
	
	-- 8x8 Base64 encoded palette image (to be scaled up x8)
	obj.palette = screen.loadImage(math.decode64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAxElEQVR4nBXMwWrCMBwH4F9IiyGjlMZOiXbLQQn8CVQheJJCJp58qj3Rjr6A57HjjruIXraCoIVRZp3nDz4GwEP6WAQZByX1zGBusd5wIoqv54eMX3L+M+anSV+UJrEm+od6/0kC1RD0DF3E4AKtjcqyfP940x7pHHIJuBSqaIDIOfeqRttUZrxnpAi/tMBwiuRe4aT/av/dTK9H4slA6kcBsK7rxv2XXAWZV4pWvgI52CdEjDHDvW4PptmFBr4m+6UR2hvzoS5T9lWhpgAAAABJRU5ErkJggg=="))
	-- 8x8 Base64 encoded clear image (not to be scaled)
	obj.clear = screen.loadImage(math.decode64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAABlBMVEUAAADmISHI/hBgAAAAEElEQVR4nGPwZJjEoMIAJwEV/QLaT6caBgAAAABJRU5ErkJggg=="))
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"colourPicker", "*"}
	obj.x = helium.make.x(obj, x)
	obj.y = helium.make.y(obj, y)
	obj.w = helium.proxy( obj.palette.w*8+1 )
	obj.h = helium.proxy( obj.palette.h*8 )
	
	return setmetatable( obj, {__index = colourPicker} )
end
function colourPicker:draw(parent)
	self.parent = parent or self.parent
	screen.rect( self.x(), self.y(), self.w(), self.h(), "black" )
	screen.drawImage( self.palette, 1, 1, 8 )
	screen.drawImage( self.clear, 1, 57 )
end
function colourPicker:mouse( x, y, btn )
	if not self:within( x, y ) then return end
	x, y = self:toLocalCoords( x, y )
	
	local c = colors.color( self.palette.image:getPixel(x/8, y/8) )
	local color, brightness = colors.getName(c), colors.getBrightness(c)
	
	if btn == 1 then
		primary = colors.compose( color, brightness, gui.primaryOpacity.value )
	elseif btn == 2 then
		secondary = colors.compose( color, brightness, gui.secondaryOpacity.value )
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
			for _, object in ipairs(gui.menu) do
				if object:hasTag("active") then
					object:removeTag("active")
					object.read.cursor = false
				end
			end
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
table.insert( obj.paint, gui.paint )
	
	gui.sidebar = gui.paint:box( 1, 1, 65, nil, "black" )
	gui.sidebar.h = function() return gui.paint.h() - 10 end
	table.insert( obj.paint, gui.sidebar )

	gui.picker = colourPicker( gui.sidebar, 1, 1 )
	table.insert( obj.paint, gui.picker )

		gui.primary = gui.picker:box( 1, gui.picker.x() + gui.picker.h() + 1, gui.picker.w()/2 - 1, 10, function() return colors.compose( colors.getName(primary), colors.getBrightness(primary) ) end )
		table.insert( obj.paint, gui.primary )
		gui.secondary = gui.picker:box( gui.picker.w()/2+1, gui.picker.x() + gui.picker.h() + 1, gui.picker.w()/2 - 1, 10, function() return colors.compose( colors.getName(secondary), colors.getBrightness(secondary) ) end )
		table.insert( obj.paint, gui.secondary )
		
		gui.primaryOpacity = gui.picker:slider( 1, gui.primary.y() + gui.primary.h() + 1, gui.picker.w()/2 - 1, 10 )
		gui.primaryOpacity.callback = function( self, value )
			primary = colors.compose( colors.getName(primary), colors.getBrightness(primary), value )
		end
		gui.primaryOpacity.value = 1
		table.insert( obj.paint, gui.primaryOpacity )
		
		gui.secondaryOpacity = gui.picker:slider( gui.picker.w()/2+1, gui.primary.y() + gui.primary.h() + 1, gui.picker.w()/2 - 1, 10 )
		gui.secondaryOpacity.callback = function( self, value )
			secondary = colors.compose( colors.getName(secondary), colors.getBrightness(secondary), value )
		end
		gui.secondaryOpacity.value = 1
		table.insert( obj.paint, gui.secondaryOpacity )
		
		local xOff, yOff = 1, 1
		for b in pairs(brushes) do
			if brushes[b].image then
				local y = yOff
				local img = screen.loadImage( math.decode64(brushes[b].image) )
				local imgObj = gui.picker:image( xOff, nil, img )
				imgObj.y = function() return gui.primaryOpacity.y() + gui.primaryOpacity.h() + y end
				imgObj.mouse = function( self, x, y, btn )
					if self:within( x, y ) then brush = b end
				end
				table.insert( obj.paint, imgObj )
				xOff = xOff + img.w
				if xOff + img.w > gui.picker.w() then
					xOff = 1
					yOff = yOff + img.h
				end
			end
		end
		
	gui.toolbar = gui.paint:box( 1, nil, nil, 10, "black" )
	gui.toolbar.y = function() return screen.height - 9 end
	gui.toolbar.w = function() return screen.width end
	table.insert( obj.paint, gui.toolbar )
		
		gui.file = gui.toolbar:text( 1, nil, function() return path or "no file opened" end, function() return path and "gray" or "gray-2" end )
		gui.file:center("y")
		table.insert( obj.paint, gui.file )
		
		gui.brush = gui.toolbar:text( nil, nil, function() return brush end, "gray" )
		gui.brush.x = function() return gui.file.x() + gui.file.w() + 10 end
		gui.brush:center("y")
		gui.brush.mouseUp = function( self, x, y, btn )
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
		table.insert( obj.paint, gui.brush )
		
		gui.zoom = gui.toolbar:text( nil, nil, function() return zoomInt.."x" end, "gray" )
		gui.zoom.x = function() return gui.brush.x() + gui.brush.w() + 10 end
		gui.zoom:center("y")
		table.insert( obj.paint, gui.zoom )

gui.menu = he:box( 1, 1, nil, nil, "gray+2" )
gui.menu:autosize( "wh", he )
table.insert( obj.menu, gui.menu )

	gui.path = gui.menu:box( margin, margin, nil, 20, "gray+2" )
	gui.path:autosize( "w", -margin, gui.menu )
	table.insert( obj.menu, gui.path )

		gui.pathTitle = gui.path:text( 1, 1, "OPEN/SAVE", "black" )
		table.insert( obj.menu, gui.pathTitle )
		
		gui.input = gui.path:input( 1, nil, nil, screen.font.height, "black" )
		gui.input.y = function() return gui.pathTitle.y() + gui.pathTitle.h() + 5 end
		gui.input:autosize( "w", gui.path )
		gui.input.border = function(obj)
			if #obj.read.history[obj.read.selected] == 0 then
				return "gray+1"
			else
				return disk.info( obj.read.history[obj.read.selected] ).type == "file" and "blue" or "orange"
			end
		end
		gui.input.background = function(obj)
			if #obj.read.history[obj.read.selected] == 0 or not obj:hasTag("active") then
				return "white"
			else
				return disk.info( obj.read.history[obj.read.selected] ).type == "file" and "blue+3" or "orange+3"
			end
		end
		gui.input.callback = function( self, input )
			self:removeTag("active")
		end
		table.insert( obj.menu, gui.input )
		
		local buttonWidth = function() return (gui.path.w() - margin)/2 end
		
		gui.open = gui.path:button( 1, nil, nil, 11, "OPEN" )
		gui.open.y = function() return gui.input.y() + gui.input.h() + 5 end
		gui.open.w = buttonWidth
		gui.open.callback = function()
			if loadFile( gui.input.read.history[gui.input.read.selected] ) then
				inMenu = false
			end
		end
		table.insert( obj.menu, gui.open )
		
		gui.save = gui.path:button( nil, nil, nil, 11, "SAVE" )
		gui.save.x = function() return gui.path.x() + gui.path.w() - buttonWidth() end
		gui.save.y = function() return gui.input.y() + gui.input.h() + 5 end
		gui.save.w = buttonWidth
		gui.save.callback = function()
			if saveFile( gui.input.read.history[gui.input.read.selected] ) then
				inMenu = false
			end
		end
		table.insert( obj.menu, gui.save )
	
	gui.path:autosize( "h", 5, gui.pathTitle, gui.input, gui.open, gui.save )

	gui.create = gui.menu:box( margin, nil, nil, 20, "gray+2" )
	gui.create:autosize( "w", -margin, gui.menu )
	gui.create.y = function() return gui.path.y() + gui.path.h() + margin end
	table.insert( obj.menu, gui.create )

		gui.createTitle = gui.create:text( 1, 1, "NEW IMAGE", "black" )
		table.insert( obj.menu, gui.createTitle )
		
		gui.widthLabel = gui.create:text( 1, nil, "Width", "black" )
		gui.widthLabel.y = function() return gui.createTitle.y() + gui.createTitle.h() + 6 end
		table.insert( obj.menu, gui.widthLabel )
		gui.width = gui.create:input( nil, nil, 50, screen.font.height-1, "black" )
		gui.width.x = function() return gui.widthLabel.x() + gui.widthLabel.w() + 5 end
		gui.width.y = function() return gui.createTitle.y() + gui.createTitle.h() + 5 end
		gui.width.char = function( self, char )
			if string.find( char, "%d" ) then
				self:update( "char", char )
			end
		end
		gui.width.key = function( self, key )
			self:update( "key", key )
			if key == "tab" and self:hasTag("active") then
				self:removeTag("active")
				self.read.cursor = false
				gui.height:addTag("active")
				gui.height.read.timer = os.startTimer(0.5)
				gui.height.read.cursor = true
			end
		end
		gui.width.callback = function(self)
			self:removeTag("active")
			gui.submit:callback()
		end
		table.insert( obj.menu, gui.width )
		
		gui.heightLabel = gui.create:text( nil, nil, "Height", "black" )
		gui.heightLabel.x = function() return gui.width.x() + gui.width.w() + 20 end
		gui.heightLabel.y = gui.widthLabel.y
		table.insert( obj.menu, gui.heightLabel )
		gui.height = gui.create:input( nil, nil, 50, screen.font.height-1, "black" )
		gui.height.x = function() return gui.heightLabel.x() + gui.heightLabel.w() + 5 end
		gui.height.y = function() return gui.createTitle.y() + gui.createTitle.h() + 5 end
		gui.height.char = function( self, char )
			if string.find( char, "%d" ) then
				self:update( "char", char )
			end
		end
		gui.height.callback = function(self)
			self:removeTag("active")
			gui.submit:callback()
		end
		table.insert( obj.menu, gui.height )
		
		gui.submit = gui.create:button( nil, nil, 50, 11, "CREATE" )
		gui.submit.x = function() return gui.create.x() + gui.create.w() - gui.submit.w() end
		gui.submit.y = function() return gui.createTitle.y() + gui.createTitle.h() + 4 end
		gui.submit.callback = function(obj)
			local width = gui.width.read.history[ gui.width.read.selected ]
			local height = gui.height.read.history[ gui.height.read.selected ]
			if not tonumber(width) or not tonumber(height) then return end
			createImage( tonumber(width), tonumber(height) )
			inMenu = false
		end
		table.insert( obj.menu, gui.submit )
	
	gui.create:autosize( "h", 5, gui.createTitle, gui.width )



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
	if x > gui.picker.w() and y < screen.height-10 and image then -- Drawing area
		local xImg = math.ceil( (x-gui.picker.w()) / zoomInt - ox + 1 )
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
		screen.pos.set(1,1)
		running = false
	elseif key == "s" and event.keyDown("ctrl") then
		saveFile(path)
	end
end

function events.mouse( x, y, btn )
	for _, object in ipairs(obj.menu) do
		if object:hasTag("input") and object:hasTag("active") then
			object:removeTag("active")
			object.read.cursor = false
		end
	end
end

function events.scroll( x, y, dir )
	zoom = math.max( 1, zoom + dir/5 )
	zoomInt = math.floor(zoom)
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
			image:draw( gui.picker.w(), 1, 0.2 )
			if overlay then overlay:draw( gui.picker.w(), 1, 0.2 ) end
		else
			image:draw( gui.picker.w() + (ox-1)*zoomInt + 1, (oy-1)*zoomInt + 1, zoomInt )
			if overlay then overlay:draw( gui.picker.w() + (ox-1)*zoomInt + 1, (oy-1)*zoomInt + 1, zoomInt ) end
		end
	end
	
	-- GUI
	for _, object in ipairs(obj) do
		object:draw()
	end
end

function printUsage()
	print("Usage:")
	print("  paint <path>")
	print("  paint --new <width> <height>")
	print()
	print("  paint --exportresources <path>", "gray")
	print("  paint --exportresources --encode64 <path>", "gray")
	running = false
end



-- RUN

local arg = {...}
if #arg > 0 then
	if arg[1] == "-h" or arg[1] == "-?" then
		printUsage()
	elseif arg[1] == "--new" then
		if #arg < 3 then printUsage() return end
		createImage( tonumber(arg[2]), tonumber(arg[3]) )
	elseif arg[1] == "--exportresources" then
		running = false
		if #arg < 2 then printUsage() return end
		if arg[2] == "--encode64" then
			if #arg < 3 then printUsage() return end
			local file = ""
			for name, brush in pairs(brushes) do
				if brush.image then
					file = file..name..": "..brush.image.."\n"
				end
			end
			disk.write( arg[3], file )
		else
			for name, brush in pairs(brushes) do
				if brush.image then
					disk.write( arg[2].."/"..name..".png", math.decode64(brush.image) )
				end
			end
		end
	else
		local p = shell.find( arg[1] )
		if loadFile(p) then
			gui.input.read.history[1] = p
		end
	end
end

while running do
	draw( inMenu and obj.menu or obj.paint )
	
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
	
	for _, object in ipairs( inMenu and obj.menu or obj.paint ) do
		if object[ e[1] ] then object[ e[1] ]( object, unpack(e,2) ) end
	end
end