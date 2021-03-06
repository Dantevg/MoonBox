--[[
	
	Screen API
	Provides functions and variables for screen drawing
	
]]--

local screen = {}
local args = {...}
local computer = args[1]
local love = args[2]

local swizzle = require "swizzle"



-- HELPER FUNCTIONS

local function getColour(colour)
	local c = colours.rgb(colour)
	if not c then return end
	c.rgb = c.rgb / 255
	return c
end

local function closestColour( r, g, b, a )
	expect( r, {"number", "table"} )
	if type(r) == "number" then
		expect( g, {"number", "nil"} )
		expect( b, {"number", "nil"} )
		expect( a, {"number", "nil"} )
	end
	
	if type(r) == "table" then
		r, g, b, a = r[1]*255, r[2]*255, r[3]*255, r[4]
	end
	
	local minName, minBrightness, minDist
	for name, v in pairs(screen.colours) do
		for brightness, colour in ipairs(v) do
			local dist = (colour[1]-r)^2 + (colour[2]-g)^2 + (colour[3]-b)^2
			if not minDist or dist < minDist then
				minDist = dist
				minName, minBrightness = name, brightness
			end
		end
	end
	
	return screen.colours[minName][minBrightness][1]/255,
		screen.colours[minName][minBrightness][2]/255,
		screen.colours[minName][minBrightness][3]/255,
		a
end

local function blendColours( fg, bg )
	expect( fg, "table" )
	expect( bg, "table" )
	
	local a = fg[4] + bg[4] * (1-fg[4])
	return {
		(fg[1]*fg[4] + bg[1]*bg[4] * (1-fg[4])) / a,
		(fg[2]*fg[4] + bg[2]*bg[4] * (1-fg[4])) / a,
		(fg[3]*fg[4] + bg[3]*bg[4] * (1-fg[4])) / a,
		a
	}
end



-- VARIABLES

screen.colours64 = {
	red    = { {51, 0,  10 }, {102,5,  18 }, {166,15, 23 }, {230,33, 33 }, {255,80, 64 }, {255,128,102}, {255,196,176} },
	orange = { {64, 13, 0  }, {128,36, 0  }, {189,64, 0  }, {230,94, 0  }, {255,135,36 }, {255,166,74 }, {255,212,153} },
	yellow = { {77, 33, 0  }, {153,87, 0  }, {204,135,0  }, {240,194,0  }, {255,237,51 }, {255,255,102}, {245,255,153} },
	green  = { {0,  51, 26 }, {3,  102,36 }, {20, 138,43 }, {51, 204,51 }, {115,230,92 }, {168,255,125}, {204,255,166} },
	cyan   = { {0,  36, 51 }, {0,  84, 102}, {0,  128,138}, {18, 179,179}, {54, 217,201}, {125,255,222}, {176,255,222} },
	blue   = { {26, 18, 64 }, {46, 36, 128}, {56, 56, 189}, {74, 97, 255}, {125,158,255}, {166,201,255}, {204,230,255} },
	purple = { {31, 3,  51 }, {71, 13, 102}, {102,26, 128}, {166,46, 189}, {217,79, 230}, {255,125,255}, {255,189,250} },
	brown  = { {51, 18, 13 }, {87, 28, 18 }, {115,41, 23 }, {153,64, 31 }, {189,107,66 }, {230,163,115}, {255,217,176} },
	gray   = { {0,  0,  0  }, {41, 41, 41 }, {82, 82, 82 }, {128,128,128}, {171,171,171}, {212,212,212}, {255,255,255} },
	black  = { {0,  0,  0  }, {0,  0,  0  }, {0,  0,  0  }, {0,  0,  0  }, {0,  0,  0  }, {0,  0,  0  }, {0,  0,  0  } },
	white  = { {255,255,255}, {255,255,255}, {255,255,255}, {255,255,255}, {255,255,255}, {255,255,255}, {255,255,255} },
}

screen.colours32 = {
  red    = {{170,0,  0  }, {255,68, 68 }, {255,119,119}},
  pink   = {{187,51, 170}, {255,85, 253}, {255,153,255}},
  purple = {{102,17, 153}, {187,102,238}, {204,153,255}},
  blue   = {{0,  71, 132}, {34, 153,255}, {136,204,255}},
  cyan   = {{34, 102,102}, {85, 187,187}, {170,221,221}},
  green  = {{51, 119,51 }, {85, 187,85 }, {136,221,136}},
  yellow = {{153,136,0  }, {238,204,0  }, {255,238,85 }}, -- Dark yellow looks ugly
  orange = {{136,68, 0  }, {221,102,0  }, {255,153,68 }}, -- So does dark orange (or should I say brown?)
  brown  = {{119,85, 68 }, {170,119,85 }, {204,170,136}},
  gray   = {{85, 85, 85 }, {136,136,136}, {204,204,204}},
  black  = {{0,  0,  0  }, {0,  0,  0  }, {0,  0,  0  }},
  white  = {{255,255,255}, {255,255,255}, {255,255,255}},
}



-- DRAWING FUNCTIONS

screen.canvas = {}

function screen.canvas:draw( x, y, scale )
	expect( x, "number", 1, "(Canvas):draw" )
	expect( y, "number", 2, "(Canvas):draw" )
	expect( scale, {"number", "nil"}, 3, "(Canvas):draw" )
	
	computer.screen.canvas:renderTo(function()
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.draw( self.canvas, x-1, y-1, nil, scale ) -- TODO: Check if -1 or -0.5
	end)
end

setmetatable( screen, {
	__index = function( t, k )
		if rawget( screen, k ) then
			return rawget( t, k )
		elseif type(screen.canvas[k]) == "function" then
			return function(...)
				return screen.canvas[k]( computer.screen, ... )
			end
		else
			return computer.screen[k]
		end
	end
} )

function screen.canvas.pixel( canvas, x, y, colour )
	expect( x, "number", 1, "screen.pixel" )
	expect( y, "number", 2, "screen.pixel" )
	expect( colour, {"string", "nil"}, 3, "screen.pixel" )
	
	x, y = x or screen.pos.x, y or screen.pos.y
	if x <= 0 or y <= 0 or x > canvas.width or y > canvas.height then
		return
	end
	
	local rgb = getColour( colour or screen.colour )
	if not rgb then error( "No such colour", 2 ) end
	if rgb.a ~= 1 then -- Partially transparent, blend with background
		colour = colours.blend( colour, rgb.a, screen.canvas.getPixel( canvas, x, y ) )
		rgb = getColour(colour)
	end
	
	canvas.canvas:renderTo(function()
		love.graphics.setColor(rgb)
		love.graphics.points( x-0.5, y-0.5 )
	end)
end

function screen.canvas.char( canvas, char, x, y, colour, scale )
	expect( char, "string", 1, "screen.char" )
	expect( x, {"number", "nil"}, 2, "screen.char" )
	expect( y, {"number", "nil"}, 3, "screen.char" )
	expect( colour, {"string", "nil"}, 4, "screen.char" )
	expect( scale, {"number", "nil"}, 5, "screen.char" )
	scale = scale or 1
	
	x, y = x or screen.pos.x, y or screen.pos.y
	local rgb = getColour(colour) or getColour(screen.colour)
	
	if rgb.a ~= 1 then -- Partially transparent
		-- Update the screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	
	canvas.canvas:renderTo(function()
		love.graphics.setColor(rgb)
		local data
		if screen.font.chars[ string.byte(char) ] then
			data = screen.font.chars[ string.byte(char) ]
		else
			data = screen.font.chars[63]
		end
		
		local height = screen.font.height + screen.font.descender
		local xOff = (screen.font.monospace and math.floor( (screen.font.width-data.w) / 2 ) or 0) * scale - 1
		local yOff = (screen.font.height + screen.font.descender - data.oy) * scale - 1
		
		love.graphics.draw( screen.font.image, data.quad, math.floor(x)+xOff, math.floor(y)+yOff, 0, scale )
		
		-- for h in pairs(data) do
		-- 	for w in pairs(data[h]) do
		-- 		if data[h][w] == 1 then
		-- 			if rgb[4] ~= 1 then -- Partially transparent
		-- 				local bg = { canvas.image:getPixel( x+w-1.5, y+screen.font.height-h-1.5 ) }
		-- 				local finalColour = {
		-- 					rgb[1] * rgb[4] + bg[1] * (1-rgb[4]),
		-- 					rgb[2] * rgb[4] + bg[2] * (1-rgb[4]),
		-- 					rgb[3] * rgb[4] + bg[3] * (1-rgb[4]),
		-- 				}
		-- 				love.graphics.setColor(finalColour)
		-- 			else
		-- 				love.graphics.setColor(rgb)
		-- 			end
		-- 			love.graphics.points( x + w - 1.5, y + screen.font.height - h - 1.5 )
		-- 		end
		-- 	end
		-- end
	end)
end

-- screen.write( text, options )
-- screen.write( text, x, y )
-- Options: x (number), y (number), colour (string), background (string),
-- 	max (number), overflow: (string/boolean) ["wrap", "ellipsis", "scroll", false], monospace (boolean)
function screen.canvas.write( canvas, text, a, b )
	expect( a, {"number", "table", "nil"}, 2, "screen.write" )
	expect( b, {"number", "nil"}, 3, "screen.write" )
	
	text = text and tostring(text) or ""
	local options = {}
	if type(a) == "number" then
		options.x = a
		options.y = b
	elseif type(a) == "table" then
		options = a
	end
	local x, y = options.x or screen.pos.x, options.y or screen.pos.y
	options.max = options.max or math.floor(
		(canvas.width - x + 1) / (screen.font.width+1) )
	if options.overflow == nil then
		options.overflow = "wrap" -- Set default overflow to wrap
	end
	options.scale = options.scale or 1
	local scroll = 0
	
	local function nextCharPos()
		if options.monospace == false then
			x = x + screen.font.charWidth[ string.sub(text,i,i) ] * options.scale
		else
			x = x + (screen.font.width+1)*options.scale
		end
	end
	
	local function nextLine()
		local incr = (screen.font.height+1) * options.scale
		x = options.x or screen.pos.x
		y = y + incr
		while y + incr > canvas.height do
			screen.canvas.move( canvas, 0, -incr )
			y = y - incr
			scroll = scroll+1
		end
	end
	
	if #text > options.max then
		if options.overflow == "ellipsis" then
			text = string.sub( text, 1, options.max-3 ) .. "..."
		elseif options.overflow == "wrap" then
			h = math.ceil( #text / options.max ) * (screen.font.height+1)
		elseif options.overflow == "scroll" then
			text = string.sub( text, -options.max )
		else
			text = string.sub( text, 1, options.max )
		end
	end
	
	for i = 1, #text do
		if (x >= canvas.width or i+1 % options.max == 0) and options.overflow == "wrap" then
			nextLine()
		end
		if options.background then
			screen.canvas.rect( canvas, x, y, (screen.font.width+1)*options.scale, screen.font.height*options.scale, options.background )
		end
		if string.sub(text,i,i) == "\n" then
			nextLine()
		elseif string.sub(text,i,i) == "\t" then
			nextCharPos()
			nextCharPos()
		else
			screen.canvas.char( canvas, string.sub(text,i,i), x, y, options.colour, options.scale )
			nextCharPos()
		end
	end
	screen.pos.set(x,y)
	
	return scroll
end

function screen.canvas.print( canvas, text, colour )
	expect( colour, {"string", "nil"}, 2, "screen.print" )
	
	screen.canvas.write( canvas, text, {colour = colour} )
	screen.pos.x = 1
	screen.pos.y = screen.pos.y + (screen.font.height+1)
	while screen.pos.y + screen.font.height > canvas.height do
		screen.canvas.move( canvas, 0, -screen.font.height-1 )
	end
end

-- Default filled
function screen.canvas.rect( canvas, x, y, w, h, colour, filled )
	expect( x, {"number", "nil"}, 1, "screen.rect" )
	expect( y, {"number", "nil"}, 2, "screen.rect" )
	expect( w, {"number", "nil"}, 3, "screen.rect" )
	expect( h, {"number", "nil"}, 4, "screen.rect" )
	expect( colour, {"string", "nil"}, 5, "screen.rect" )
	expect( filled, {"boolean", "nil"}, 6, "screen.rect" )
	
	x, y = x or screen.pos.x, y or screen.pos.y
	w, h = (w or 0), (h or 0)
	
	local rgb = getColour(colour) or getColour(screen.background)
	
	if rgb.a == 1 then -- Not transparent, use simple faster method
		canvas.canvas:renderTo(function()
			love.graphics.setColor(rgb)
			if filled ~= false then
				love.graphics.rectangle( "fill", x-0.5, y-0.5, w, h )
			else
				love.graphics.rectangle( "line", x-0.5, y-0.5, w-1, h-1 )
			end
		end)
	elseif rgb.a ~= 0 and filled ~= false then -- Partially transparent, use slow method
		-- Update the screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
		
		-- Draw rectangle on image
		for i = math.max( x, 1 ), math.min( x+w-1, canvas.width ) do
			for j = math.max( y, 1 ), math.min( y+h-1, canvas.height ) do
				local finalColour = blendColours( rgb, {canvas.image:getPixel(i-0.5, j-0.5)} )
				canvas.image:setPixel( i-0.5, j-0.5, closestColour(finalColour) )
			end
		end
		
		-- Draw image on canvas
		canvas.canvas:renderTo(function()
			local image = love.graphics.newImage(canvas.image)
			love.graphics.setColor( 1, 1, 1, 1 )
			love.graphics.draw(image)
		end)
	elseif rgb.a ~= 0 and filled == false then
		screen.canvas.line( canvas, x+1, y, x+w-1, y, colour )
		screen.canvas.line( canvas, x+w-1, y+1, x+w-1, y+h-1, colour )
		screen.canvas.line( canvas, x, y+h-1, x+w-2, y+h-1, colour )
		screen.canvas.line( canvas, x, y, x, y+h-2, colour )
	end
end

function screen.canvas.line( canvas, x1, y1, x2, y2, colour )
	expect( x1, "number", 1, "screen.line" )
	expect( y1, "number", 2, "screen.line" )
	expect( x2, "number", 3, "screen.line" )
	expect( y2, "number", 4, "screen.line" )
	expect( colour, {"string", "nil"}, 5, "screen.line" )
	
	local rgb = getColour(colour) or getColour(screen.colour)
	
	if rgb.a ~= 1 then -- Partially transparent, update screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	
	local function point( x, y )
		if x < 1 or y < 1 or x > canvas.width or y > canvas.height then return end
		if rgb.a ~= 1 then
			local finalColour = blendColours( rgb, {canvas.image:getPixel(x-0.5, y-0.5)} )
			love.graphics.setColor(finalColour)
		else
			love.graphics.setColor(rgb)
		end
		love.graphics.points( x-0.5, y-0.5 )
	end
	
	local function low( x1, y1, x2, y2 )
		local dx = x2 - x1
		local dy = y2 - y1
		local yi = 1
		if dy < 0 then
			yi = -1
			dy = -dy
		end
		local D = 2*dy - dx
		local y = y1
		canvas.canvas:renderTo(function()
			for x = x1, x2 do
				point( x, y )
				if D > 0 then
					y = y + yi
					D = D - 2*dx
				end
				D = D + 2*dy
			end
		end)
	end
	
	local function high( x1, y1, x2, y2 )
		local dx = x2 - x1
		local dy = y2 - y1
		local xi = 1
		if dx < 0 then
			xi = -1
			dx = -dx
		end
		local D = 2*dx - dy
		local x = x1
		canvas.canvas:renderTo(function()
			for y = y1, y2 do
				point( x, y )
				if D > 0 then
					x = x + xi
					D = D - 2*dy
				end
				D = D + 2*dx
			end
		end)
	end
	
	if math.abs( y2-y1 ) < math.abs( x2-x1 ) then
		if x1 > x2 then
			low( x2, y2, x1, y1 )
		else
			low( x1, y1, x2, y2 )
		end
	else
		if y1 > y2 then
			high( x2, y2, x1, y1 )
		else
			high( x1, y1, x2, y2 )
		end
	end
end

-- Default filled
function screen.canvas.circle( canvas, xc, yc, r, colour, filled )
	expect( xc, {"number", "nil"}, 1, "screen.circle" )
	expect( yc, {"number", "nil"}, 2, "screen.circle" )
	expect( r, "number", 3, "screen.circle" )
	expect( colour, {"string", "nil"}, 4, "screen.circle" )
	expect( filled, {"boolean", "nil"}, 5, "screen.circle" )
	
	xc, yc = xc or screen.pos.x, yc or screen.pos.y
	local rgb = getColour(colour) or getColour(screen.colour)
	
	if rgb.a ~= 1 and not filled then -- Partially transparent, update screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	
	local x = r
	local y = 0
	local err = -r
	
	local function pixel( x, y )
		if x < 1 or y < 1 or x > canvas.width or y > canvas.height then return end
		if rgb.a ~= 1 then
			local finalColour = blendColours( rgb, {canvas.image:getPixel(x-0.5, y-0.5)} )
			love.graphics.setColor(finalColour)
		else
			love.graphics.setColor(rgb)
		end
		
		love.graphics.points( x-0.5, y-0.5 )
	end
	
	local function draw( x, y )
		x, y = math.floor(x), math.floor(y)
		if filled ~= false then
			screen.canvas.line( canvas, xc-x, yc-y, xc+x, yc-y, colour )
			screen.canvas.line( canvas, xc-x, yc+y, xc+x, yc+y, colour )
			screen.canvas.line( canvas, xc-y, yc-x, xc+y, yc-x, colour )
			screen.canvas.line( canvas, xc-y, yc+x, xc+y, yc+x, colour )
		else
			canvas.canvas:renderTo(function()
				pixel( xc+x, yc+y )
				pixel( xc-x, yc+y )
				pixel( xc+x, yc-y )
				pixel( xc-x, yc-y )
				pixel( xc+y, yc+x )
				pixel( xc-y, yc+x )
				pixel( xc+y, yc-x )
				pixel( xc-y, yc-x )
			end)
		end
	end
	
	while x >= y do
		draw( x, y )
		y = y+1
		if err < 0 then
			err = err + 2*y + 1
		else
			x = x-1
			err = err + 2*(y-x) + 1
		end
	end
end

function screen.canvas.drawImage( canvas, image, x, y, scale )
	expect( image, {"string", "table"}, 1, "screen.drawImage" )
	expect( x, {"number", "nil"}, 2, "screen.drawImage" )
	expect( y, {"number", "nil"}, 3, "screen.drawImage" )
	expect( scale, {"number", "nil"}, 4, "screen.drawImage" )
	
	if type(image) == "string" then
		image = screen.loadImage(image)
	end
	image = image.image
	
	x, y, scale = x or 1, y or 1, scale or 1
	
	-- Update the canvas image
	canvas.image = canvas.canvas:newImageData()
	canvas.imageFrame = computer.currentFrame
	
	-- Scale image down
	if scale < 1 then
		local oldImage = image
		local w = math.floor( oldImage:getWidth()*scale )
		local h = math.floor( oldImage:getHeight()*scale )
		image = love.image.newImageData( w, h )
		image:mapPixel(function( ox, oy, r, g, b, a )
			local colour = swizzle(r,g,b,a)
			for i = 1, math.floor(1/scale) do
				for j = 1, math.floor(1/scale) do
					big = swizzle{ oldImage:getPixel( (ox/scale)+i-1, (oy/scale)+j-1 ) }
					colour = colour + big
				end
			end
			return unpack( colour * scale^2 )
		end)
		scale = 1
	end
	
	-- Draw image on canvas image
	image:mapPixel(function( ox, oy, r, g, b, a )
		for px = 1, math.max(1, scale) do
			for py = 1, math.max(1, scale) do
				local screenX = x + ox*scale + (px-1) - 0.5
				local screenY = y + oy*scale + (py-1) - 0.5
				if screenX >= 0 and screenY >= 0 and screenX <= canvas.width and screenY <= canvas.height then
					local finalColour = blendColours( {r,g,b,a}, {canvas.image:getPixel(screenX, screenY)} )
					canvas.image:setPixel( screenX, screenY, closestColour(finalColour) )
				end
			end
		end
		
		return r, g, b, a -- mapPixel expects a return colour, so return original colour
	end)
	
	-- Draw image on canvas
	canvas.canvas:renderTo(function()
		local image = love.graphics.newImage(canvas.image)
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.draw(image)
	end)
end

function screen.canvas.tabulate( canvas, elements, nColumns, vertical, fn )
	expect( elements, "table", 1, "screen.tabulate" )
	expect( nColumns, {"number", "nil"}, 2, "screen.tabulate" )
	expect( vertical, {"boolean", "nil"}, 3, "screen.tabulate" )
	expect( fn, {"function", "nil"}, 4, "screen.tabulate" )
	
	local columnWidth = 0
	for k, v in pairs(elements) do
		columnWidth = math.max( columnWidth, #v )
	end
	nColumns = nColumns or math.floor( canvas.width / (screen.font.width+1) / (columnWidth+2) )
	nRows = math.ceil(#elements / nColumns)
	
	local x, y = screen.pos.x, screen.pos.y
	for k, v in pairs(elements) do
		if vertical then
			screen.pos.x = x + (screen.font.width+1) * math.floor((k-1)/nRows) * (columnWidth+2)
			screen.pos.y = y + (screen.font.height+1) * math.floor((k-1) % nRows)
		else
			screen.pos.x = x + (screen.font.width+1) * ((k-1) % nColumns) * (columnWidth+2)
			screen.pos.y = y + (screen.font.height+1) * math.floor((k-1)/nColumns)
		end
		while screen.pos.y + screen.font.height > canvas.height do
			screen.canvas.move( canvas, 0, -screen.font.height-1 )
			y = y - screen.font.height - 1
		end
		if fn then
			fn(v)
		else
			screen.canvas.write( canvas, v )
		end
	end
	
	screen.canvas.print(canvas)
	if vertical and nColumns > 1 and (#elements / nRows) % 1 ~= 0 then
		screen.canvas.print(canvas)
	end
end

function screen.canvas.clear( canvas, colour )
	expect( colour, {"string", "nil"} )
	
	colour = getColour(colour) or {0,0,0,0} -- Default to transparent black
	
	canvas.canvas:renderTo(function()
		love.graphics.clear(colour)
	end)
end

function screen.canvas.move( canvas, x, y )
	expect( x, "number", 1, "screen.move" )
	expect( y, "number", 2, "screen.move" )
	
	local newCanvas = love.graphics.newCanvas(
		canvas.width,
		canvas.height)
		
	newCanvas:renderTo(function()
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.draw( canvas.canvas, x, y )
	end)
	
	canvas.canvas = newCanvas
	canvas.canvas:setFilter( "linear", "nearest" )
	screen.pos = screen.pos + {x,y}
end

function screen.canvas.cursor( canvas, x, y, colour )
	expect( x, {"number", "nil"}, 1, "screen.cursor" )
	expect( y, {"number", "nil"}, 2, "screen.cursor" )
	expect( colour, {"string", "nil"}, 3, "screen.cursor" )
	
	screen.canvas.char( canvas, "_", x, y, colour )
end



-- GET, SET, LOAD, NEW

function screen.setPixelPos( x, y )
	expect( x, "number" )
	expect( y, "number" )
	
	screen.pos.set(x,y)
end

function screen.getPixelPos( x, y )
	expect( x, {"number", "nil"} )
	expect( y, {"number", "nil"} )
	
	if not x or not y then
		return screen.pos.x, screen.pos.y
	end
	return
		(x-1) * (screen.font.width+1) + 1,
		(y-1) * (screen.font.height+1) + 1
end

function screen.setCharPos( x, y )
	expect( x, "number" )
	expect( y, "number" )
	
	screen.pos.x = (x-1) * (screen.font.width+1) + 1
	screen.pos.y = (y-1) * (screen.font.height+1) + 1
end

function screen.getCharPos( x, y )
	expect( x, {"number", "nil"} )
	expect( y, {"number", "nil"} )
	
	x, y = x or screen.pos.x, y or screen.pos.y
	return
		math.floor( x / (screen.font.width+1) ) + 1,
		math.floor( y / (screen.font.height+1) ) + 1
end

function screen.setColour(colour)
	expect( colour, "string" )
	
	screen.colour = colour
end

function screen.setBackground(colour)
	expect( colour, "string" )
	
	screen.background = colour
end

function screen.canvas.getPixel( canvas, x, y )
	expect( x, "number" )
	expect( y, "number" )
	
	if x <= 0 or y <= 0 or x > canvas.width or y > canvas.height then
		return screen.background
	end
	if not canvas.image or canvas.imageFrame < computer.currentFrame then
		-- Update the screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	local r, g, b = canvas.image:getPixel( x-1, y-1 )
	
	return colours.colour( r, g, b )
end

function screen.loadImage(source)
	expect( source, "string" )
	
	local imageData
	if string.sub( source, 1, 8 ) == "\137PNG\r\n\26\n" then -- Detect PNG header
		imageData = love.image.newImageData( love.data.newByteData(source) )
	else
		local path = disk.absolute(source)
		if not disk.exists(path) then
			error( "No such file: "..path, 2 )
		end
		imageData = love.image.newImageData(path)
	end
	
	-- Convert colours
	imageData:mapPixel(function( x, y, r, g, b, a )
		return closestColour({r,g,b,a})
	end)
	
	return {
		width = imageData:getWidth(),
		height = imageData:getHeight(),
		image = imageData
	}
end

--[[ local function loadFont( path, data )
	expect( path, "string" )
	expect( data, "table" )
	
	local font = {}
	font.name = data.description.family
	font.monospace = true -- Only monospace support for now
	font.width = 0
	font.height = 0
	font.charWidth = {}
	font.data = {}
	
	local image = love.image.newImageData( disk.absolute(path.."/"..data.file) )
	if not image then error( "Could not load font resource: "..disk.absolute(data.file), 2 ) end
	
	-- Get font width
	for i = 1, #data.chars do
		font.width = math.max( font.width, data.chars[i].w ) -- Set font monospace width
		font.height = math.max( font.height, data.chars[i].h ) -- Set font monospace width
		font.charWidth[ data.chars[i].char ] = data.chars[i].width
	end
	
	-- Get characters
	for i = 1, #data.chars do
		local charData = data.chars[i]
		local char = {}
		
		-- Get pixels
		for y = charData.oy - charData.h, charData.oy do
			char[y+1] = {}
			for x = charData.ox, charData.ox + charData.w do
				local xPixel = charData.x + x
				local yPixel = charData.y + charData.oy - y
				-- Center monospaced narrow characters like "." and "!"
				local xChar, yChar = (font.monospace and x+1 + math.floor( (font.width-charData.w) / 2 ) or x+1), y+1
				if ({ image:getPixel(xPixel, yPixel) })[4] == 1 then
					char[yChar][xChar] = 1
				else
					char[yChar][xChar] = 0
				end
			end
		end
		
		font.data[ string.byte(charData.char) ] = char
	end
	
	return font
end ]]

local function loadFont( path, data )
	expect( path, "string" )
	expect( data, "table" )
	
	local font = {}
	font.name = data.description.family
	font.monospace = true -- Only monospace support for now
	font.width = 0
	font.height = 0
	font.ascender = data.metrics.ascender
	font.descender = data.metrics.descender
	-- font.charWidth = {}
	font.chars = {}
	
	local image = love.image.newImageData( disk.absolute(path.."/"..data.file) )
	if not image then error( "Could not load font resource: "..disk.absolute(data.file), 2 ) end
	
	font.image = love.graphics.newImage(image)
	font.image:setFilter( "linear", "nearest" )
	
	-- Get font width
	for i = 1, #data.chars do
		font.chars[ string.byte(data.chars[i].char) ] = data.chars[i]
		font.width = math.max( font.width, data.chars[i].w ) -- Set font monospace width
		font.height = math.max( font.height, data.chars[i].h ) -- Set font monospace width
		-- font.charWidth[ data.chars[i].char ] = data.chars[i].width
	end
	
	-- Get characters
	for k, char in pairs(font.chars) do
		font.chars[k].quad = love.graphics.newQuad(
			char.x, char.y, char.w, char.h, font.image:getDimensions()
		)
	end
	
	--[[ for i = 1, #data.chars do
		local charData = data.chars[i]
		-- local height = font.height+data.metrics.descender
		-- local xOff = (font.monospace and math.floor( (font.width-charData.w) / 2 ) or 0)
		-- font.chars[ string.byte(charData.char) ] = love.graphics.newQuad(
		-- 	charData.x - xOff, charData.y + charData.oy - height,
		-- 	charData.w + xOff, charData.h - charData.oy + height,
		-- 	font.image:getDimensions()
		-- )
		
		font.chars[ string.byte(charData.char) ].quad = love.graphics.newQuad(
			charData.x, charData.y, charData.w, charData.h, font.image:getDimensions()
		)
	end ]]
	
	return font
end

function screen.setFont(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	if not disk.exists(path) then
		error( "No such file: "..path, 2 )
	end
	
	local file = disk.read(path)
	if not file then
		error( "Could not read file: "..path, 2 )
	end
	
	local data = loadstring(file)
	if not data then error( "Error loading file", 2 ) end
	data = data()
	
	local font = loadFont( disk.getPath(path), data )
	-- local font = loadstring( "return " .. file )() -- Old font file type
	
	if font then
		screen.font = font
		screen.charWidth = math.floor( computer.screen.width / (font.width+1) )
		screen.charHeight = math.floor( computer.screen.height / (font.height+1) )
		return true
	else
		return false
	end
end

function screen.newCanvas( w, h )
	expect( w, "number" )
	expect( h, "number" )
	
	w, h = math.max( 1, math.floor(w) ), math.max( 1, math.floor(h) )
	local c = {
		w = w,
		h = h,
		width = w,
		height = h,
		canvas = love.graphics.newCanvas( w, h )
	}
	c.canvas:setFilter( "linear", "nearest" )
	return setmetatable( c, {__index = screen.canvas} )
end

function screen.newShader(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	if not disk.exists(path) then
		error( "No such file: "..path, 2 )
	end
	
	local file = disk.read(path)
	if not file then
		error( "Could not read file: "..path, 2 )
	end
	
	return love.graphics.newShader(path)
end

function screen.setShader(shader)
	expect( shader, {"userdata", "nil"} )
	
	computer.screen.shader = shader
end

function screen.getFPS()
	return love.timer.getFPS()
end



-- RETURN

return screen