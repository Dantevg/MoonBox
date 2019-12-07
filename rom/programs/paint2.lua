--[[
	
	Paint program
	by RedPolygon
	
	for MoonBox
	
]]--

-- CONSTANTS

local he = helium.new( 1, 1, screen.width, screen.height )
local gui = {}
local brushes = {}



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

gui.paint = he:box( 1, 1, nil, nil, "gray-2" )
gui.paint:autosize( "wh", he )

gui.picker = colourPicker( gui.paint, 1, 1, 5, 10 )
gui.picker.h = function() return he.h() - 10 end

gui.primary = gui.picker:box( 1, gui.picker.hColour() * #gui.picker.rainbow + 1, gui.picker.w()/2 - 1, 15, function() return primary end )
gui.secondary = gui.picker:box( gui.picker.w()/2+1, gui.picker.hColour() * #gui.picker.rainbow + 1, gui.picker.w()/2 - 1, 15, function() return secondary end )

gui.menu = he:box( 1, 1, nil, nil, "white" )
gui.menu:autosize( "wh", he )

gui.open = gui.menu:box( 20, 20, nil, 20, "gray+2" )
gui.open:autosize( "w", -20, gui.menu )

gui.open.title = gui.open:text( 5, 5, "OPEN FILE", "black" )

gui.open:autosize( "h", 3, gui.open.title )



-- HELPER FUNCTIONS

function loadFile()
	
end

function saveFile()
	
end

local events = {}

function events.key(key)
	if key == "escape" then
		inMenu = not inMenu
	end
end

function events.mouse( x, y, btn )
	gui.picker:mouse( x, y, btn )
end

function events.scroll( x, y, dir )
	zoom = math.max( 1, zoom + dir/5 )
	zoomInt = math.floor(zoom)
end



-- PROGRAM FUNCTIONS

function draw()
	if inMenu then
		gui.menu:draw()
		gui.open:draw()
		gui.open.title:draw()
	else
		gui.paint:draw()
		gui.picker:draw()
		gui.primary:draw()
		gui.secondary:draw()
	end
end



-- RUN

while running do
	draw()
	local e = {event.wait()}
	if events[ e[1] ] then
		events[ e[1] ]( unpack(e,2) )
	end
end