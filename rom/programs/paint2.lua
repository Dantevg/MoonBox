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



-- VARIABLES

local running = true
local inMenu = false
local zoom = 1
local zoomInt = 1
local primary = "white"
local secondary = "blue"
local brush = "pencil" -- "pixel", "pencil", "line", "rect", "circle"

local image
local overlay



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
	if btn == 1 then
		primary = colors.compose( color, brightness )
	elseif btn == 2 then
		secondary = colors.compose( color, brightness )
	end
end
setmetatable( colourPicker, {
	__index = helium,
	__call = function( _, ... ) return colourPicker.new(...) end
})

he.styles.input = {
	padding = 1,
	border = "gray+1",
	background = function(obj) return obj:hasTag("active") and "gray+1" or "gray+2" end,
	mouse = function( self, x, y, btn )
		if self:within( x, y ) then
			self.read.timer = os.startTimer(0.5)
			eachObj( gui.menu, function(obj)
				if obj:hasTag("active") then
					obj:removeTag("active")
					obj.read.cursor = false
				end
			end )
			self:addTag("active")
			self.read.cursor = true
		end
	end
}

he.styles.button = {
	color = "white",
	background = "gray-1",
	activeColor = "white",
	activeBackground = "gray",
}

local function createInput(obj)
	obj.y = function() return obj.parent.obj.title.y() + obj.parent.obj.title.h() + 5 end
	obj.read.cursor = false
end

gui.paint = he:box( 1, 1, nil, nil, "gray-2" )
gui.paint:autosize( "wh", he )
gui.paint.obj = {}

	gui.paint.obj.picker = colourPicker( gui.paint, 1, 1, 5, 10 )
	gui.paint.obj.picker.h = function() return he.h() - 10 end
	gui.paint.obj.picker.obj = {}
	local Picker = gui.paint.obj.picker

		Picker.obj.primary = Picker:box( 1, Picker.hColour() * #Picker.rainbow + 1, Picker.w()/2 - 1, 15, function() return primary end )
		Picker.obj.secondary = Picker:box( Picker.w()/2+1, Picker.hColour() * #Picker.rainbow + 1, Picker.w()/2 - 1, 15, function() return secondary end )
	
		gui.paint.obj.toolbar = gui.paint:box( 1, nil, nil, 10, "black" )
		gui.paint.obj.toolbar.y = function() return screen.height - 9 end
		gui.paint.obj.toolbar.w = function() return screen.width end

gui.menu = he:box( 1, 1, nil, nil, "gray+2" )
gui.menu:autosize( "wh", he )
gui.menu.obj = {}

	gui.menu.obj.open = gui.menu:box( margin, margin, nil, 20, "gray+2" )
	gui.menu.obj.open:autosize( "w", -margin, gui.menu )
	gui.menu.obj.open.obj = {}
	local Open = gui.menu.obj.open

		Open.obj.title = Open:text( 5, 5, "OPEN FILE", "black" )
		Open.obj.input = Open:input( 5, nil, nil, screen.font.height, "black" )
		Open.obj.input:autosize( "w", -5, Open )
		createInput(Open.obj.input)
		Open.obj.input.callback = function( self, input )
			loadFile(input)
			self:removeTag("active")
		end
	
	Open:autosize( "h", 5, Open.obj.title, Open.obj.input )

	gui.menu.obj.create = gui.menu:box( margin, nil, nil, 20, "gray+2" )
	gui.menu.obj.create:autosize( "w", -margin, gui.menu )
	gui.menu.obj.create.y = function() return Open.y() + Open.h() + margin end
	gui.menu.obj.create.obj = {}
	local Create = gui.menu.obj.create

		Create.obj.title = Create:text( 5, 5, "NEW IMAGE", "black" )
		
		Create.obj.widthLabel = Create:text( 5, nil, "Width", "black" )
		Create.obj.widthLabel.y = function() return Create.obj.title.y() + Create.obj.title.h() + 6 end
		Create.obj.width = Create:input( nil, nil, 50, screen.font.height, "black" )
		Create.obj.width.x = function() return Create.obj.widthLabel.x() + Create.obj.widthLabel.w() + 5 end
		createInput(Create.obj.width)
		Create.obj.width.callback = function( self, input )
			createImage(input)
			self:removeTag("active")
		end
		
		Create.obj.heightLabel = Create:text( nil, nil, "Height", "black" )
		Create.obj.heightLabel.x = function() return Create.obj.width.x() + Create.obj.width.w() + 20 end
		Create.obj.heightLabel.y = Create.obj.widthLabel.y
		Create.obj.height = Create:input( nil, nil, 50, screen.font.height, "black" )
		Create.obj.height.x = function() return Create.obj.heightLabel.x() + Create.obj.heightLabel.w() + 5 end
		createInput(Create.obj.height)
		Create.obj.height.callback = function( self, input )
			createImage(input)
			self:removeTag("active")
		end
		
		Create.obj.submit = Create:button( nil, nil, 50, 11, "CREATE" )
		Create.obj.submit.x = function() return Create.w() - Create.obj.submit.w() end
		Create.obj.submit.y = function() return Create.obj.title.y() + Create.obj.title.h() + 4 end
		Create.obj.submit.callback = function(obj)
			
		end
	
	Create:autosize( "h", 5, Create.obj.title, Create.obj.width )



-- HELPER FUNCTIONS

function createImage()
	
end

function loadFile()
	
end

function saveFile()
	
end

local events = {}

function events.key(key)
	if key == "escape" then
		inMenu = not inMenu
	elseif key == "q" and event.keyDown("ctrl") then
		screen.clear()
		screen.pos = {x=1,y=1}
		running = false
	end
end

function events.mouse( x, y, btn )
	-- gui.paint.obj.picker:mouse( x, y, btn )
	eachObj( gui.menu, function(obj)
		if obj:hasTag("active") then
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
	eachObj( obj, function(obj) obj:draw() end )
end



-- RUN

while running do
	draw( inMenu and gui.menu or gui.paint )
	
	local e = {event.wait()}
	if events[ e[1] ] then
		events[ e[1] ]( unpack(e,2) )
	end
	
	propagateEvents( inMenu and gui.menu or gui.paint, unpack(e) )
end