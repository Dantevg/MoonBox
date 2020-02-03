--[[
	
	Colours lib
	Provides colour conversion and manipulation functions
	
]]--

local colours = {}

local function getColour(colour)
	local c = colours.rgb(colour)
	if not c then return end
	c.rgb = c.rgb / 255
	return c
end



-- CONVERSION FUNCTIONS

-- Convert colour to rgba (0-255) value
function colours.rgb(colour)
	expect( colour, {"string", "table", "nil"} )
	
	if not colour then return end
	
	if type(colour) == "table" then
		return colour
	end
	
	local name, brightness, opacity = colours.getComponents(colour)
	
	brightness = tonumber(brightness) or 0
	opacity = tonumber(opacity) or 1
	if screen.colours == screen.colours32 then
		brightness = brightness + 2
	elseif screen.colours == screen.colours64 then
		brightness = brightness + 4
	end
	
	-- Nonexisting colour
	if not screen.colours[name] or not screen.colours[name][brightness] then
		return nil
	end
	
	return swizzle{
		screen.colours[name][brightness][1],
		screen.colours[name][brightness][2],
		screen.colours[name][brightness][3],
		math.min( math.max( 0, opacity ), 1 )
	}
end

-- Convert colour to hsla (0-255) value
function colours.hsl( r, g, b, a )
	expect( r, {"number", "table", "string"}, 1, "colours.hsl" )
	if type(a) == "number" then
		expect( g, "number", 2, "colours.hsl" )
		expect( g, "number", 2, "colours.hsl" )
		expect( a, "number", 4, "colours.hsl" )
	end
	
	if type(r) == "table" then
		r, g, b, a = r[1]/255, r[2]/255, r[3]/255, r[4]
	elseif g and b then
		r, g, b = r/255, g/255, b/255
	else
		local name, brightness = colours.getComponents(r)
	
		brightness = tonumber(brightness) or 0
		if screen.colours == screen.colours32 then
			brightness = brightness + 2
		elseif screen.colours == screen.colours64 then
			brightness = brightness + 4
		end
		
		-- Nonexisting colour
		if not screen.colours[name] or not screen.colours[name][brightness] then
			return nil
		end
		
		r, g, b = screen.colours[name][brightness][1]/255, screen.colours[name][brightness][2]/255, screen.colours[name][brightness][3]/255
	end
	
	-- https://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, l = nil, nil, (max + min) / 2

	if max == min then
		h, s = 0, 0 -- achromatic
	else
		local d = max - min
		s = (l > 0.5) and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g<b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return math.floor(h*255), math.floor(s*255), math.floor(l*255), a
end

-- Convert rgb (0-255) to colour
-- colours.colour( rgba (table) )
-- colours.colour( r (number), g (number), b (number), a (number) )
function colours.colour( r, g, b, a )
	expect( r, {"number", "table"}, 1, "colours.hsl" )
	if type(a) == "number" then
		expect( g, "number", 2, "colours.hsl" )
		expect( b, "number", 3, "colours.hsl" )
		expect( a, "number", 4, "colours.hsl" )
	end
	
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
	end
	
	-- Find colour in table
	for name, v in pairs(screen.colours) do
		for i = 1, #v do
			if v[i][1] == r*255 and v[i][2] == g*255 and v[i][3] == b*255 then
				-- Same colour, return formatted name
				return colours.compose( name, i-4, a )
			end
		end
	end
	
	-- Colour not found, find closest colour
	local minName, minBrightness, minDist
	for name, v in pairs(screen.colours) do
		for brightness, colour in ipairs(v) do
			local dist = (colour[1]-r)^2 + (colour[2]-g)^2 + (colour[3]-b)^2
			if not minDist or dist < minDist then
				minDist = dist
				minName, minBrightness = name, brightness-4
			end
		end
	end
	
	return colours.compose( minName, minBrightness, a )
end



-- COLOUR MANIPULATION FUNCTIONS

-- Format colour from name and brightness
function colours.compose( name, brightness, opacity )
	expect( name, "string", 1, "colours.compose" )
	expect( brightness, {"number", "nil"}, 2, "colours.compose" )
	expect( opacity, {"number", "nil"}, 3, "colours.compose" )
	
	if not screen.colours[name] then
		error( "No such colour", 2 )
	end
	
	-- Make sure brightness and opacity are within range
	brightness = math.min( math.max( -3, brightness or 0 ), 3 )
	opacity = math.min( math.max( 0, opacity or 1 ), 1 )
	
	-- Round brightness and opacity
	brightness = math.floor( brightness * 100 ) / 100
	opacity = math.floor( opacity * 100 ) / 100
	
	local colour
	
	if name == "black" or (name == "gray" and brightness == -3) then
		colour = "black"
	elseif name == "white" or (name == "gray" and brightness == 3) then
		colour = "white"
	else
		colour = name .. (brightness >= 0 and "+"..brightness or brightness)
	end
	
	if opacity ~= 1 then
		colour = colour .. " ("..opacity..")"
	end
	
	return colour
end

function colours.getComponents(colour)
	expect( colour, "string" )
	
	return string.match( colour, "(%a+)(%S*)%s*%(*([^%)]*)%)*")
end

-- Get colour name from colour
function colours.getName(colour)
	expect( colour, "string" )
	
	local name = colours.getComponents(colour)
	return name
end

-- Get brightness from colour
function colours.getBrightness(colour)
	expect( colour, "string" )
	
	local _, brightness = colours.getComponents(colour)
	return tonumber(brightness) or 0
end

-- Get opacity from colour
function colours.getOpacity(colour)
	expect( colour, "string" )
	
	local _, _, opacity = colours.getComponents(colour)
	return tonumber(opacity) or 1
end

function colours.darker( colour, amount )
	expect( colour, "string", 1, "colours.darker" )
	expect( amount, {"number", "nil"}, 2, "colours.darker" )
	
	local name, brightness = colours.getComponents(colour)
	if name == "white" then
		name = "gray"
		brightness = "3"
	end
	return colours.compose( name, (tonumber(brightness) or 0) - (amount or 1) )
end

function colours.lighter( colour, amount )
	expect( colour, "string", 1, "colours.lighter" )
	expect( amount, {"number", "nil"}, 2, "colours.lighter" )
	
	local name, brightness = colours.getComponents(colour)
	if name == "black" then
		name = "gray"
		brightness = "-3"
	end
	return colours.compose( name, (tonumber(brightness) or 0) + (amount or 1) )
end

function colours.blend( fg, a, bg )
	expect( fg, "string", 1, "colours.blend" )
	expect( a, "number", 2, "colours.blend" )
	expect( bg, "string", 3, "colours.blend" )
	
	fg = getColour(fg)
	bg = getColour(bg)
	
	if not fg or not bg then
		error( "No such colour", 2 )
	end
	
	local result = fg * a + bg * (1-a)
	
	return colours.colour( result.rgb*255 )
end



-- COLOUR CONVENIENCE FUNCTIONS

function colours.random( brightness, opacity )
	expect( brightness, {"number", "nil"}, 1, "colours.random" )
	expect( opacity, {"number", "nil"}, 2, "colours.random" )
	
	local keys = {}
	for colour in pairs(screen.colours) do
		table.insert( keys, colour )
	end
	
	return colours.compose( keys[ math.random(#keys) ], brightness, opacity )
end

function colours.all(variants)
	expect( variants, {"boolean", "nil"} )
	
	local all = {}
	
	for colour in pairs(screen.colours) do
		if variants and colour ~= "white" and colour ~= "black" then
			for brightness = -3, 3 do
				table.insert( all, colours.compose( colour, brightness ) )
			end
		elseif colour ~= "white" and colour ~= "black" then
			table.insert( all, colour )
		end
	end
	
	return all
end



-- RETURN

return colours