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
setmetatable( colourPicker, {
	__index = helium,
	__call = function( _, ... ) return colourPicker.new(...) end
})

gui.paint = he:box( 1, 1, nil, nil, "gray-2" )
gui.paint.w = function() return he.w() end
gui.paint.h = function() return he.h() end

gui.menu = he:box( 1, 1 )
gui.menu.w = function() return he.w() end
gui.menu.h = function() return he.h() end

gui.picker = colourPicker( gui.paint, 1, 1, 5, 10 )
gui.picker.h = function() return he.h() - 10 end

gui.primary = gui.picker:box( 1, gui.picker.hColour() * #gui.picker.rainbow + 1, gui.picker.w()/2 - 1, 15, primary )
gui.secondary = gui.picker:box( gui.picker.w()/2+1, gui.picker.hColour() * #gui.picker.rainbow + 1, gui.picker.w()/2 - 1, 15, secondary )



-- HELPER FUNCTIONS

function loadFile()
	
end

function saveFile()
	
end



-- PROGRAM FUNCTIONS

function draw()
	if inMenu then
		gui.menu:draw()
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
	os.sleep()
end