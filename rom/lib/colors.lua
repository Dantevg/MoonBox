--[[
	
	Colors lib
	Provides color conversion and manipulation functions
	
]]--

local colors = {}

local function getColor(color)
	local c = colors.rgb(color)
	if not c then return end
	return {
		c[1]/255,
		c[2]/255,
		c[3]/255,
		c[4]
	}
end



-- CONVERSION FUNCTIONS

-- Convert color to rgba (0-255) value
function colors.rgb(color)
	expect( color, {"string", "table", "nil"} )
	
	if not color then return end
	
	if type(color) == "table" then
		return color
	end
	
	local name, brightness, opacity = colors.getComponents(color)
	
	brightness = tonumber(brightness) or 0
	opacity = tonumber(opacity) or 1
	if screen.colors == screen.colors32 then
		brightness = brightness + 2
	elseif screen.colors == screen.colors64 then
		brightness = brightness + 4
	end
	
	-- Nonexisting color
	if not screen.colors[name] or not screen.colors[name][brightness] then
		return nil
	end
	
	return {
		screen.colors[name][brightness][1],
		screen.colors[name][brightness][2],
		screen.colors[name][brightness][3],
		math.min( math.max( 0, opacity ), 1 )
	}
end

-- Convert color to hsla (0-255) value
function colors.hsl( r, g, b, a )
	expect( r, {"number", "table", "string"}, 1, "colors.hsl" )
	if type(a) == "number" then
		expect( g, "number", 2, "colors.hsl" )
		expect( g, "number", 2, "colors.hsl" )
		expect( a, "number", 4, "colors.hsl" )
	end
	
	if type(r) == "table" then
		r, g, b, a = r[1]/255, r[2]/255, r[3]/255, r[4]
	elseif g and b then
		r, g, b = r/255, g/255, b/255
	else
		local name, brightness = colors.getComponents(r)
	
		brightness = tonumber(brightness) or 0
		if screen.colors == screen.colors32 then
			brightness = brightness + 2
		elseif screen.colors == screen.colors64 then
			brightness = brightness + 4
		end
		
		-- Nonexisting color
		if not screen.colors[name] or not screen.colors[name][brightness] then
			return nil
		end
		
		r, g, b = screen.colors[name][brightness][1]/255, screen.colors[name][brightness][2]/255, screen.colors[name][brightness][3]/255
	end
	
	-- https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, l

	l = (max + min) / 2

	if max == min then
		h, s = 0, 0 -- achromatic
	else
		local d = max - min
		if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
		if max == r then
			h = (g - b) / d
			if g < b then h = h + 6 end
		elseif max == g then h = (b - r) / d + 2
		elseif max == b then h = (r - g) / d + 4
		end
		h = h / 6
	end

	return math.floor(h*255), math.floor(s*255), math.floor(l*255), a
end

-- Convert rgb (0-255) to color
-- colors.color( rgba (table) )
-- colors.color( r (number), g (number), b (number), a (number) )
function colors.color( r, g, b, a )
	expect( r, {"number", "table"}, 1, "colors.hsl" )
	if type(a) == "number" then
		expect( g, "number", 2, "colors.hsl" )
		expect( b, "number", 3, "colors.hsl" )
		expect( a, "number", 4, "colors.hsl" )
	end
	
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
	end
	
	-- Find color in table
	for name, v in pairs(screen.colors) do
		for i = 1, #v do
			if v[i][1] == r*255 and v[i][2] == g*255 and v[i][3] == b*255 then
				-- Same color, return formatted name
				return colors.compose( name, i-4, a )
			end
		end
	end
	
	-- Color not found, find closest color
	local minName, minBrightness, minDist
	for name, v in pairs(screen.colors) do
		for brightness, color in ipairs(v) do
			local dist = (color[1]-r)^2 + (color[2]-g)^2 + (color[3]-b)^2
			if not minDist or dist < minDist then
				minDist = dist
				minName, minBrightness = name, brightness-4
			end
		end
	end
	
	return colors.compose( minName, minBrightness, a )
end



-- COLOR MANIPULATION FUNCTIONS

-- Format color from name and brightness
function colors.compose( name, brightness, opacity )
	expect( name, "string", 1, "colors.compose" )
	expect( brightness, {"number", "nil"}, 2, "colors.compose" )
	expect( opacity, {"number", "nil"}, 3, "colors.compose" )
	
	if not screen.colors[name] then
		error( "No such color", 2 )
	end
	
	-- Make sure brightness and opacity are within range
	brightness = math.min( math.max( -3, brightness or 0 ), 3 )
	opacity = math.min( math.max( 0, opacity or 1 ), 1 )
	
	-- Round brightness and opacity
	brightness = math.floor( brightness * 100 ) / 100
	opacity = math.floor( opacity * 100 ) / 100
	
	local color
	
	if name == "black" or (name == "gray" and brightness == -3) then
		color = "black"
	elseif name == "white" or (name == "gray" and brightness == 3) then
		color = "white"
	else
		color = name .. (brightness >= 0 and "+"..brightness or brightness)
	end
	
	if opacity ~= 1 then
		color = color .. " ("..opacity..")"
	end
	
	return color
end

function colors.getComponents(color)
	expect( color, "string" )
	
	return string.match( color, "(%a+)(%S*)%s*%(*([^%)]*)%)*")
end

-- Get color name from color
function colors.getName(color)
	expect( color, "string" )
	
	local name = colors.getComponents(color)
	return name
end

-- Get brightness from color
function colors.getBrightness(color)
	expect( color, "string" )
	
	local _, brightness = colors.getComponents(color)
	return tonumber(brightness) or 0
end

-- Get opacity from color
function colors.getOpacity(color)
	expect( color, "string" )
	
	local _, _, opacity = colors.getComponents(color)
	return tonumber(opacity) or 1
end

function colors.darker( color, amount )
	expect( color, "string", 1, "colors.darker" )
	expect( amount, {"number", "nil"}, 2, "colors.darker" )
	
	local name, brightness = colors.getComponents(color)
	if name == "white" then
		name = "gray"
		brightness = "3"
	end
	return colors.compose( name, (tonumber(brightness) or 0) - (amount or 1) )
end

function colors.lighter( color, amount )
	expect( color, "string", 1, "colors.lighter" )
	expect( amount, {"number", "nil"}, 2, "colors.lighter" )
	
	local name, brightness = colors.getComponents(color)
	if name == "black" then
		name = "gray"
		brightness = "-3"
	end
	return colors.compose( name, (tonumber(brightness) or 0) + (amount or 1) )
end

function colors.blend( fg, a, bg )
	expect( fg, "string", 1, "colors.blend" )
	expect( a, "number", 2, "colors.blend" )
	expect( bg, "string", 3, "colors.blend" )
	
	fg = getColor(fg)
	bg = getColor(bg)
	
	if not fg or not bg then
		error( "No such color", 2 )
	end
	
	local result = {
		fg[1] * a + bg[1] * (1-a),
		fg[2] * a + bg[2] * (1-a),
		fg[3] * a + bg[3] * (1-a),
	}
	
	return colors.color( result[1]*255, result[2]*255, result[3]*255 )
end



-- COLOR CONVENIENCE FUNCTIONS

function colors.random( brightness, opacity )
	expect( brightness, {"number", "nil"}, 1, "colors.random" )
	expect( opacity, {"number", "nil"}, 2, "colors.random" )
	
	local keys = {}
	for color in pairs(screen.colors) do
		table.insert( keys, color )
	end
	
	return colors.compose( keys[ math.random(#keys) ], brightness, opacity )
end

function colors.all(variants)
	expect( variants, {"boolean", "nil"} )
	
	local all = {}
	
	for color in pairs(screen.colors) do
		if variants and color ~= "white" and color ~= "black" then
			for brightness = -3, 3 do
				table.insert( all, colors.compose( color, brightness ) )
			end
		elseif color ~= "white" and color ~= "black" then
			table.insert( all, color )
		end
	end
	
	return all
end



-- RETURN

return colors