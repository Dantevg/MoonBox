local env = {}
local computer = ...

-- GLOBAL FUNCTIONS

-- function env.color(hex)
-- 	local r, g, b = hex:match("(.)(.)(.)")
-- 	return tonumber(r, 16)/16, tonumber(g, 16)/16, tonumber(b, 16)/16
-- end

function getColor(color)
	local c = env.colors.rgb(color)
	if not c then return end
	return {
		c[1]/255,
		c[2]/255,
		c[3]/255,
		c[4]
	}
end

function closestColor( r, g, b, a )
	if type(r) == "table" then
		r, g, b, a = r[1]*255, r[2]*255, r[3]*255, r[4]
	end
	
	local minName, minBrightness, minDist
	for name, v in pairs(env.screen.colors) do
		for brightness, color in ipairs(v) do
			local dist = math.sqrt( (color[1]-r)^2 + (color[2]-g)^2 + (color[3]-b)^2 )
			if not minDist or dist < minDist then
				minDist = dist
				minName, minBrightness = name, brightness
			end
		end
	end
	
	return env.screen.colors[minName][minBrightness][1]/255,
		env.screen.colors[minName][minBrightness][2]/255,
		env.screen.colors[minName][minBrightness][3]/255,
		a
end

function env.read(history)
	history = history or {}
	table.insert( history, "" )
	local selected = #history
	local cursor = true
	local x, y = env.screen.pos.x, env.screen.pos.y
	local pos = 1
	local length = 0
	local timer = env.os.startTimer(0.5)
	
	local function draw()
		env.screen.write( string.rep(" ", length+1),
			{x = x, y = y, background = env.screen.background} )
		env.screen.write(
			string.sub( history[selected], 1, pos-1 )
			..( cursor and "_" or string.sub(history[selected], pos, pos) )
			..string.sub( history[selected], pos+1, -1 )
			.." ", x, y )
	end
	
	local function getWords()
		local words = {}
		local length = 1
		for word, separator in string.gmatch( history[selected], "(%w*)(%W*)" ) do
			table.insert( words, { type="word", data=word, s=length, e=length+#word-1 } )
			table.insert( words, { type="separator", data=separator, s=length+#word, e=length+#word+#separator-1 } )
			length = length + #word + #separator
		end
		return words
	end
	
	while true do
		draw()
		length = #history[selected]
		
		-- Update input
		local event, key = env.event.wait()
		if event == "char" then
			history[#history] = string.sub( history[selected], 1, pos-1 )..key..string.sub( history[selected], pos, -1 )
			selected = #history
			pos = pos+1
		elseif event == "key" then
			if key == "enter" then
				cursor = false
				draw()
				if selected == #history then
					return table.remove( history, #history )
				else
					table.remove( history, #history )
					return history[selected]
				end
			elseif key == "backspace" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos > words[i].s and pos <= words[i].e+1 then
							local l = #words[i].data
							words[i].data = string.sub( words[i].data, pos - words[i].s + 1 )
							pos = math.max( 1, pos-(l-#words[i].data) )
							break
						end
					end
					history[selected] = ""
					for i = 1, #words do
						history[selected] = history[selected] .. words[i].data
					end
				else
					history[selected] = string.sub( history[selected], 1, math.max(0,pos-2) )
						..string.sub( history[selected], pos, -1 )
						pos = math.max( 1, pos-1 )
				end
			elseif key == "delete" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos > words[i].s and pos <= words[i].e+1 then
							words[i].data = string.sub( words[i].data, 1, pos - words[i].s )
							break
						end
					end
					history[selected] = ""
					for i = 1, #words do
						history[selected] = history[selected] .. words[i].data
					end
				else
					history[selected] = string.sub( history[selected], 1, pos-1 )
						..string.sub( history[selected], pos+1, -1 )
				end
			elseif key == "up" then
				selected = math.max( 1, selected-1 )
				pos = #history[selected]+1
			elseif key == "down" then
				selected = math.min( selected+1, #history )
				pos = #history[selected]+1
			elseif key == "left" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos > words[i].s and pos <= words[i].e+1 then
							pos = (words[i].type == "word") and (words[i-1] and words[i-1].s) or words[i].s
							break
						end
					end
				else
					pos = math.max( 1, pos-1 )
				end
			elseif key == "right" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos >= words[i].s and pos <= words[i].e then
							pos = (words[i].type == "separator") and words[i+1].e+1 or words[i].e+1
							break
						end
					end
				else
					pos = math.min( pos+1, #history[selected]+1 )
				end
			elseif key == "home" then
				pos = 1
			elseif key == "end" then
				pos = #history[selected]+1
			end
		elseif event == "timer" and key == timer then
			timer = env.os.startTimer(0.5)
			cursor = not cursor
		end
	end
end

function env.tostring(...)
	if select( "#", ... ) == 0 then -- No argument received (not even a nil value)
		return nil
	else
		return tostring(...)
	end
end

function env.load( fn, name, mode, e )
	return load( fn, name, mode or "bt", e or computer.env )
end

function env.loadfile(path)
	return setfenv( love.filesystem.load(env.disk.absolute(path)), computer.env )
end

function env.loadstring( str, name, mode, e )
	return load( str, name, mode or "bt", e or computer.env )
end

function env.require(path)
	local before = {"/", "/disk1/", "/disk1/lib/"}
	local after = {"", ".lua"}
	
	for i = 1, #before do
		for j = 1, #after do
			
			local p = env.disk.absolute( before[i]..env.disk.absolute(path)..after[j] )
			if env.disk.exists(p) then
				local file = env.disk.read(p)
				local fn, err = load( file, "="..env.disk.getFilename(p), "bt", computer.env )
				if not fn then
					error( err, 2 )
				end
				return fn()
			end
			
		end
	end
	
	error( "Couldn't find "..path, 2 )
end





-- APIs

env.colors = {}

-- Convert color to rgba (0-255) value
function env.colors.rgb(color)
	if not color then return end
	
	if type(color) == "table" then
		return color
	end
	
	local name, brightness, opacity = env.colors.getComponents(color)
	
	brightness = tonumber(brightness) or 0
	opacity = tonumber(opacity) or 1
	if env.screen.colors == env.screen.colors32 then
		brightness = brightness + 2
	elseif env.screen.colors == env.screen.colors64 then
		brightness = brightness + 4
	end
	
	-- Nonexisting color
	if not env.screen.colors[name] or not env.screen.colors[name][brightness] then
		return nil
	end
	
	return {
		env.screen.colors[name][brightness][1],
		env.screen.colors[name][brightness][2],
		env.screen.colors[name][brightness][3],
		math.min( math.max( 0, opacity ), 1 )
	}
end

-- Convert color to hsla (0-255) value
function env.colors.hsl( r, g, b, a )
	if not r then return end
	
	if type(r) == "table" then
		r, g, b, a = r[1]/255, r[2]/255, r[3]/255, r[4]
	elseif g and b then
		r, g, b = r/255, g/255, b/255
	else
		local name, brightness = env.colors.getComponents(r)
	
		brightness = tonumber(brightness) or 0
		if env.screen.colors == env.screen.colors32 then
			brightness = brightness + 2
		elseif env.screen.colors == env.screen.colors64 then
			brightness = brightness + 4
		end
		
		-- Nonexisting color
		if not env.screen.colors[name] or not env.screen.colors[name][brightness] then
			return nil
		end
		
		r, g, b = env.screen.colors[name][brightness][1]/255, env.screen.colors[name][brightness][2]/255, env.screen.colors[name][brightness][3]/255
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
function env.colors.color( r, g, b, a )
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
	end
	
	-- Find color in table
	for name, v in pairs(env.screen.colors) do
		for i = 1, #v do
			if v[i][1] == r*255 and v[i][2] == g*255 and v[i][3] == b*255 then
				-- Same color, return formatted name
				return env.colors.compose( name, i-4 )
			end
		end
	end
	
	-- Color not found, find closest color
	local minName, minBrightness, minDist
	for name, v in pairs(env.screen.colors) do
		for brightness, color in ipairs(v) do
			local dist = math.sqrt( (color[1]-r)^2 + (color[2]-g)^2 + (color[3]-b)^2 )
			if not minDist or dist < minDist then
				minDist = dist
				minName, minBrightness = name, brightness-4
			end
		end
	end
	
	return env.colors.compose( minName, minBrightness, a )
end

-- Format color from name and brightness
function env.colors.compose( name, brightness, opacity )
	if not env.screen.colors[name] then
		error( "No such color", 2 )
	end
	
	-- Make sure brightness and opacity are within range
	brightness = math.min( math.max( -3, brightness or 0 ), 3 )
	opacity = math.min( math.max( 0, opacity or 1 ), 1 )
	
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

function env.colors.getComponents(color)
	return string.match( color, "(%a+)(%S*)%s*%(*([^%)]*)%)*")
end

-- Get color name from color
function env.colors.getName(color)
	local name = env.colors.getComponents(color)
	return name
end

-- Get brightness from color
function env.colors.getBrightness(color)
	local _, brightness = env.colors.getComponents(color)
	return tonumber(brightness) or 0
end

-- Get opacity from color
function env.colors.getOpacity(color)
	local _, _, opacity = env.colors.getComponents(color)
	return tonumber(opacity) or 1
end

function env.colors.darker( color, amount )
	local name, brightness = env.colors.getComponents(color)
	if name == "white" then
		name = "gray"
		brightness = "3"
	end
	return env.colors.compose( name, (tonumber(brightness) or 0) - (amount or 1) )
end

function env.colors.lighter( color, amount )
	local name, brightness = env.colors.getComponents(color)
	if name == "black" then
		name = "gray"
		brightness = "-3"
	end
	return env.colors.compose( name, (tonumber(brightness) or 0) - (amount or 1) )
end

function env.colors.blend( fg, a, bg )
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
	
	return env.colors.color( result[1]*255, result[2]*255, result[3]*255 )
end

function env.colors.random( brightness, opacity )
	local keys = {}
	for color in pairs(env.screen.colors) do
		table.insert( keys, color )
	end
	
	return env.colors.compose( keys[ math.random(#keys) ], brightness, opacity )
end

function env.colors.all(variants)
	local all = {}
	
	for color in pairs(env.screen.colors) do
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





env.screen = {}

env.screen.pos = {
	x = 1,
	y = 1
}
env.screen.width = computer.screen.w
env.screen.height = computer.screen.h
env.screen.color = "white"
env.screen.background = "black"

env.screen.font = {}

env.screen.colors64 = {
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

env.screen.colors32 = {
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

env.screen.canvas = {}

function env.screen.canvas:draw( x, y, scale )
	computer.screen.canvas:renderTo(function()
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.draw( self.canvas, x-1, y-1, nil, scale ) -- TODO: Check if -1 or -0.5
	end)
end

setmetatable( env.screen, {
	__index = function( t, k )
		if rawget( env.screen, k ) then
			return rawget( t, k )
		elseif type(env.screen.canvas[k]) == "function" then
			return function(...)
				return env.screen.canvas[k]( computer.screen, ... )
			end
		else
			return nil
		end
	end
} )

function env.screen.canvas.pixel( canvas, x, y, color )
	x, y = x or env.screen.pos.x, y or env.screen.pos.y
	if x <= 0 or y <= 0 or x > env.screen.width or y > env.screen.height then
		return
	end
	
	local rgb = getColor( color or env.screen.color )
	if not rgb then error( "No such color", 2 ) end
	if rgb[4] ~= 1 then -- Partially transparent, blend with background
		color = env.colors.blend( color, rgb[4], env.screen.canvas.getPixel( canvas, x, y ) )
		rgb = getColor(color)
	end
	
	canvas.canvas:renderTo(function()
		love.graphics.setColor(rgb)
		love.graphics.points( x-0.5, y-0.5 )
	end)
end

function env.screen.canvas.char( canvas, char, x, y, color )
	x, y = x or env.screen.pos.x, y or env.screen.pos.y
	local rgb = getColor(color) or getColor(env.screen.color)
	
	if rgb[4] ~= 1 then -- Partially transparent
		-- Update the screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	
	canvas.canvas:renderTo(function()
		love.graphics.setColor(rgb)
		local data
		if env.screen.font.data[ string.byte(char) ] then
			data = env.screen.font.data[ string.byte(char) ]
		else
			data = env.screen.font.data[63]
		end
		
		for h in pairs(data) do
			for w in pairs(data[h]) do
				if data[h][w] == 1 then
					if rgb[4] ~= 1 then -- Partially transparent
						local bg = { canvas.image:getPixel( x+w-1.5, y+env.screen.font.height-h-1.5 ) }
						local finalColor = {
							rgb[1] * rgb[4] + bg[1] * (1-rgb[4]),
							rgb[2] * rgb[4] + bg[2] * (1-rgb[4]),
							rgb[3] * rgb[4] + bg[3] * (1-rgb[4]),
						}
						love.graphics.setColor(finalColor)
					else
						love.graphics.setColor(rgb)
					end
					love.graphics.points( x + w - 1.5, y + env.screen.font.height - h - 1.5 )
				end
			end
		end
	end)
end

-- screen.write( text, options )
-- screen.write( text, x, y )
-- Options: x (number), y (number), color (string), background (string),
-- 	max (number), overflow: (string) ["wrap", "ellipsis"], monospace (boolean)
function env.screen.canvas.write( canvas, text, a, b )
	text = text and tostring(text) or ""
	local options = {}
	if type(a) == "number" then
		options.x = a
		options.y = b
	elseif type(a) == "table" then
		options = a
	end
	x, y = options.x or env.screen.pos.x, options.y or env.screen.pos.y
	options.max = options.max or math.floor(
		(env.screen.width - x + 1) / (env.screen.font.width+1) )
	if options.overflow == nil then
		options.overflow = "wrap" -- Set default overflow to wrap
	end
	
	local function nextCharPos()
		if options.monospace == false then
			x = x + env.screen.font.charWidth[ string.sub(text,i,i) ]
		else
			x = x + env.screen.font.width + 1
		end
	end
	
	local function nextLine()
		x = options.x or env.screen.pos.x
		y = y + env.screen.font.height + 1
		while y + env.screen.font.height > env.screen.height do
			env.screen.canvas.move( canvas, 0, -env.screen.font.height-1 )
			y = y - env.screen.font.height-1
		end
	end
	
	if #text > options.max then
		if options.overflow == "ellipsis" then
			text = string.sub( text, 1, options.max-3 ) .. "..."
		elseif options.overflow == "wrap" then
			h = math.ceil( #text / options.max ) * (env.screen.font.height+1)
		else
			text = string.sub( text, 1, options.max )
		end
	end
	
	for i = 1, #text do
		if (x >= env.screen.width or i+1 % options.max == 0) and options.overflow == "wrap" then
			nextLine()
		end
		if options.background then
			env.screen.canvas.rect( canvas, x, y, env.screen.font.width+1, env.screen.font.height, options.background )
		end
		if string.sub(text,i,i) == "\n" then
			nextLine()
		elseif string.sub(text,i,i) == "\t" then
			nextCharPos()
			nextCharPos()
		else
			env.screen.canvas.char( canvas, string.sub(text,i,i), x, y, options.color )
			nextCharPos()
		end
	end
	env.screen.pos.x = x
	env.screen.pos.y = y
end

function env.screen.canvas.print( canvas, text, color )
	env.screen.canvas.write( canvas, text, {color = color} )
	env.screen.pos.x = 1
	env.screen.pos.y = env.screen.pos.y + (env.screen.font.height+1)
	while env.screen.pos.y + env.screen.font.height > env.screen.height do
		env.screen.canvas.move( canvas, 0, -env.screen.font.height-1 )
	end
end

-- Default filled
function env.screen.canvas.rect( canvas, x, y, w, h, color, filled )
	x, y = x or env.screen.pos.x, y or env.screen.pos.y
	w, h = (w or 0), (h or 0)
	
	local rgb = getColor(color) or getColor(env.screen.background)
	
	if rgb[4] == 1 then -- Not transparent, use simple faster method
		canvas.canvas:renderTo(function()
			love.graphics.setColor(rgb)
			if filled ~= false then
				love.graphics.rectangle( "fill", x-0.5, y-0.5, w, h )
			else
				love.graphics.rectangle( "line", x-0.5, y-0.5, w-1, h-1 )
			end
		end)
	elseif rgb[4] ~= 0 and filled ~= false then -- Partially transparent, use slow method
		-- Update the screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
		
		-- Draw rectangle on image
		for i = math.max( x, 1 ), math.min( x+w-1, env.screen.width ) do
			for j = math.max( y, 1 ), math.min( y+h-1, env.screen.height ) do
				local bg = { canvas.image:getPixel(i-0.5, j-0.5) }
				local finalColor = {
					rgb[1] * rgb[4] + bg[1] * (1-rgb[4]),
					rgb[2] * rgb[4] + bg[2] * (1-rgb[4]),
					rgb[3] * rgb[4] + bg[3] * (1-rgb[4]),
				}
				canvas.image:setPixel( i-0.5, j-0.5, closestColor(finalColor) )
			end
		end
		
		-- Draw image on canvas
		canvas.canvas:renderTo(function()
			local image = love.graphics.newImage(canvas.image)
			love.graphics.setColor( 1, 1, 1, 1 )
			love.graphics.draw(image)
		end)
	elseif rgb[4] ~= 0 and filled == false then
		env.screen.canvas.line( canvas, x+1, y, x+w-1, y, color )
		env.screen.canvas.line( canvas, x+w-1, y+1, x+w-1, y+h-1, color )
		env.screen.canvas.line( canvas, x, y+h-1, x+w-2, y+h-1, color )
		env.screen.canvas.line( canvas, x, y, x, y+h-2, color )
	end
end

function env.screen.canvas.line( canvas, x1, y1, x2, y2, color )
	if not x1 or not y1 or not x2 or not y2 then
		error( "Expected coordinates", 2 )
	end
	local rgb = getColor(color) or getColor(env.screen.color)
	
	if rgb[4] ~= 1 then -- Partially transparent, update screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	
	local function point( x, y )
		if rgb[4] ~= 1 then
			local bg = { canvas.image:getPixel(x-0.5, y-0.5) }
			local finalColor = {
				rgb[1] * rgb[4] + bg[1] * (1-rgb[4]),
				rgb[2] * rgb[4] + bg[2] * (1-rgb[4]),
				rgb[3] * rgb[4] + bg[3] * (1-rgb[4]),
			}
			love.graphics.setColor(finalColor)
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
function env.screen.canvas.circle( canvas, xc, yc, r, color, filled )
	xc, yc = xc or env.screen.pos.x, yc or env.screen.pos.y
	if not r then error( "Radius expected", 2 ) end
	local rgb = getColor(color) or getColor(env.screen.color)
	
	if rgb[4] ~= 1 and not filled then -- Partially transparent, update screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	
	local x = r
	local y = 0
	local err = -r
	
	local function pixel( x, y )
		if rgb[4] ~= 1 then
			local bg = { canvas.image:getPixel(x-0.5, y-0.5) }
			local finalColor = {
				rgb[1] * rgb[4] + bg[1] * (1-rgb[4]),
				rgb[2] * rgb[4] + bg[2] * (1-rgb[4]),
				rgb[3] * rgb[4] + bg[3] * (1-rgb[4]),
			}
			love.graphics.setColor(finalColor)
		else
			love.graphics.setColor(rgb)
		end
		
		love.graphics.points( x-0.5, y-0.5 )
	end
	
	local function draw( x, y )
		x, y = math.floor(x), math.floor(y)
		if filled ~= false then
			env.screen.canvas.line( canvas, xc-x, yc-y, xc+x, yc-y, color )
			env.screen.canvas.line( canvas, xc-x, yc+y, xc+x, yc+y, color )
			env.screen.canvas.line( canvas, xc-y, yc-x, xc+y, yc-x, color )
			env.screen.canvas.line( canvas, xc-y, yc+x, xc+y, yc+x, color )
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

function env.screen.canvas.clear( canvas, color )
	color = getColor(color)
	if color then
		color[4] = 1 -- No transparency
	else
		color = {0,0,0,0}
	end
	
	canvas.canvas:renderTo(function()
		love.graphics.clear(color)
	end)
end

function env.screen.canvas.move( canvas, x, y )
	local newCanvas = love.graphics.newCanvas(
		env.screen.width,
		env.screen.height)
		
	newCanvas:renderTo(function()
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.draw( canvas.canvas, x, y )
	end)
	
	canvas.canvas = newCanvas
	canvas.canvas:setFilter( "linear", "nearest" )
	env.screen.pos.x = env.screen.pos.x + x
	env.screen.pos.y = env.screen.pos.y + y
end

function env.screen.canvas.cursor( canvas, x, y, color )
	env.screen.canvas.char( canvas, "_", x, y, color )
end

function env.screen.setPixelPos( x, y )
	env.screen.pos.x, env.screen.pos.y = x, y
end

function env.screen.getPixelPos( x, y )
	if not x or not y then
		return env.screen.pos.x, env.screen.pos.y
	end
	return
		(x-1) * (env.screen.font.width+1) + 1,
		(y-1) * (env.screen.font.height+1) + 1
end

function env.screen.setCharPos( x, y )
	env.screen.pos.x = (x-1) * (env.screen.font.width+1) + 1
	env.screen.pos.y = (y-1) * (env.screen.font.height+1) + 1
end

function env.screen.getCharPos( x, y )
	x, y = x or env.screen.pos.x, y or env.screen.pos.y
	return
		math.floor( x / (env.screen.font.width+1) ) + 1,
		math.floor( y / (env.screen.font.height+1) ) + 1
end

function env.screen.setColor(color)
	env.screen.color = color
end

function env.screen.setBackground(color)
	env.screen.background = color
end

function env.screen.canvas.getPixel( canvas, x, y )
	if x <= 0 or y <= 0 or x > env.screen.width or y > env.screen.height then
		return env.screen.background
	end
	if not canvas.image or canvas.imageFrame < computer.currentFrame then
		-- Update the screen image
		canvas.image = canvas.canvas:newImageData()
		canvas.imageFrame = computer.currentFrame
	end
	local r, g, b = canvas.image:getPixel( x-1, y-1 )
	
	return env.colors.color( r, g, b )
end

function loadFont( path, data )
	local font = {}
	font.name = data.description.family
	font.monospace = true -- Only monospace support for now
	font.width = 0
	font.height = 0
	font.charWidth = {}
	font.data = {}
	
	local image = love.image.newImageData( env.disk.absolute(path.."/"..data.file) )
	if not image then error( "Could not load font resource: "..env.disk.absolute(data.file), 2 ) end
	
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
end

function env.screen.setFont(path)
	path = env.disk.absolute(path)
	if not env.disk.exists(path) then
		error( "No such file: "..path, 2 )
	end
	
	local file = env.disk.read(path)
	if not file then
		error( "Could not read file: "..path, 2 )
	end
	
	local data = loadstring(file)
	if not data then error( "Error loading file", 2 ) end
	data = data()
	
	local font = loadFont( env.disk.getPath(path), data )
	-- local font = loadstring( "return " .. file )() -- Old font file type
	
	if font then
		env.screen.font = font
		env.screen.charWidth = math.floor( env.screen.width / (font.width+1) )
		env.screen.charHeight = math.floor( env.screen.height / (font.height+1) )
		return true
	else
		return false
	end
end

function env.screen.newCanvas( w, h )
	w, h = w or 0, h or 0
	local c = {
		w = w,
		h = h,
		canvas = love.graphics.newCanvas( w, h )
	}
	c.canvas:setFilter( "linear", "nearest" )
	return setmetatable( c, {__index = env.screen.canvas} )
end

function env.screen.newShader(path)
	path = env.disk.absolute(path)
	if not env.disk.exists(path) then
		error( "No such file: "..path, 2 )
	end
	
	local file = env.disk.read(path)
	if not file then
		error( "Could not read file: "..path, 2 )
	end
	
	return love.graphics.newShader(path)
end

function env.screen.setShader(shader)
	computer.screen.shader = shader
end





env.disk = {}

-- Path functions (drive-independent)

function env.disk.getParts(path)
	local tPath = {}
	for dir in string.gmatch( path, "[^/]+" ) do
		table.insert( tPath, dir )
	end
	return tPath
end

function env.disk.getPath(path)
	local parts = env.disk.getParts( env.disk.absolute(path) )
	table.remove( parts, #parts )
	return "/"..table.concat( parts, "/" )
end

function env.disk.getFilename(path)
	local parts = env.disk.getParts( env.disk.absolute(path) )
	return parts[ #parts ]
end

function env.disk.getExtension(path)
	local name = env.disk.getFilename(path)
	local ext = string.match( name, "(%.[^%.]+)$" )
	return ext
end

function env.disk.getDrive(path)
	local drive = env.disk.getParts( env.disk.absolute(path) )[1]
	return env.disk.drives[drive] and drive or "/" -- Return drive or "/" for main
end

function env.disk.absolute(path)
	if not path then return "/" end
	local tPath = {}
	for dir in string.gmatch( path, "[^/]+" ) do
		if dir ~= ".." then
			table.insert( tPath, dir )
		else
			table.remove(tPath)
		end
	end
	
	return "/"..table.concat( tPath, "/" )
end

env.disk.defaults = {}

-- Viewing functions

function env.disk.defaults.list( path, showHidden )
	path = env.disk.absolute(path)
	if not love.filesystem.getInfo( path, "directory" ) then
		error( "No such dir", 2 )
	end
	
	local list = love.filesystem.getDirectoryItems(path)
	
	-- Remove items starting with "."
	if not showHidden then
		for i = #list, 1, -1 do
			if string.sub( env.disk.getFilename(list[i]), 1, 1 ) == "." then
				table.remove( list, i )
			end
		end
	end
	
	return list
end

function env.disk.defaults.read(path)
	path = env.disk.absolute(path)
	if not love.filesystem.getInfo( path, "file" ) then
		error( "No such file", 2 )
	end
	
	return love.filesystem.read(path)
end

function env.disk.defaults.readLines(path)
	path = env.disk.absolute(path)
	if not love.filesystem.getInfo( path, "file" ) then
		error( "No such file", 2 )
	end
	
	local file = {}
	for line in love.filesystem.lines(path) do
		table.insert( file, line )
	end
	return file
end

function env.disk.defaults.info(path)
	path = env.disk.absolute(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return {
			type = (info.type == "directory" and "dir" or "file"),
			size = info.size,
			modified = info.modtime,
		}
	else
		return false
	end
end

function env.disk.defaults.exists(path)
	return env.disk.info(path) and true or false
end

-- Modification functions

function env.disk.defaults.write( path, data )
	return love.filesystem.write( env.disk.absolute(path), data )
end

function env.disk.defaults.append( path, data )
	return love.filesystem.append( env.disk.absolute(path), data )
end

function env.disk.defaults.mkdir(path)
	path = env.disk.absolute(path)
	if love.filesystem.getInfo(path) then
		error( "Path already exists", 2 )
	end
	
	love.filesystem.createDirectory(path)
end

function env.disk.defaults.newFile(path)
	local file = love.filesystem.newFile( env.disk.absolute(path) )
	file:close()
end

function env.disk.defaults.remove(path)
	path = env.disk.absolute(path)
	if love.filesystem.getInfo( path, "directory" ) and #env.disk.list(path) > 0 then
		-- TODO: Recursively empty folder
		error( "Can only remove empty folders", 2 )
	end
	love.filesystem.remove(path)
end

-- Drives and functions

env.disk.drives = {}

env.disk.drives["/"] = setmetatable( {}, {__index = env.disk.defaults} )

env.disk.drives["/"].list = function()
	local drives = env.disk.getDrives()
	for i = 1, #drives do
		if drives[i] == "/" then
			table.remove( drives, i )
			break
		end
	end
	return drives
end
env.disk.drives["/"].info = function(path)
	if env.disk.drives[path] then
		return {
			type = "drive",
			size = 0,
			modified = 0,
		}
	else
		return false
	end
end
env.disk.drives["/"].read = function()
	error( "No such file", 2 )
end
env.disk.drives["/"].readLines = function()
	error( "No such file", 2 )
end
env.disk.drives["/"].write = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["/"].append = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["/"].mkdir = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["/"].newFile = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["/"].remove = function()
	error( "Attempt to modify read-only location", 2 )
end

env.disk.drives["disk1"] = setmetatable( {}, {__index = env.disk.defaults} )

env.disk.drives["rom"] = setmetatable( {}, {__index = env.disk.defaults} )

env.disk.drives["rom"].write = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["rom"].append = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["rom"].mkdir = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["rom"].newFile = function()
	error( "Attempt to modify read-only location", 2 )
end
env.disk.drives["rom"].remove = function()
	error( "Attempt to modify read-only location", 2 )
end

function env.disk.getDrives()
	local d = {}
	for k in pairs(env.disk.drives) do
		table.insert( d, k )
	end
	return d
end

setmetatable(env.disk, {
	__index = function( t, k )
		if not env.disk.defaults[k] then
			return
		end
		return function( path, ... )
			path = env.disk.absolute(path)
			local drive = env.disk.getDrive(path)
			
			if drive and env.disk.drives[drive] then
				return env.disk.drives[drive][k]( path, ... )
			else
				return env.disk.defaults[k]( path, ... )
			end
		end
	end
})





env.os = {}

env.os.FPS = computer.FPS
env.os.version = "Lunar sandbox v"..computer.version

function env.os.clock()
	return math.floor( computer.clock * 1000 ) / 1000
end

function env.os.time( h24, seconds )
	if h24 then
		return os.date( "%H:%M"..(seconds and ":%S" or "") )
	else
		return os.date("%I:%M"..(seconds and ":%S" or "").." %p")
	end
end

function env.os.date(yearFirst)
	if yearFirst then
		return os.date("%Y-%m-%d")
	else
		return os.date("%d-%m-%Y")
	end
end

function env.os.datetime()
	return os.date("*t")
end

function env.os.startTimer(time)
	time = math.ceil( (time or 0)*computer.FPS ) / computer.FPS
	time = math.max( time, 1/computer.FPS )
	table.insert( computer.timers, computer.timers.n, love.timer.getTime() + time )
	computer.timers.n = computer.timers.n+1
	return computer.timers.n-1
end

function env.os.sleep(time)
	local timer = env.os.startTimer(time)
	repeat
		local event, param = env.event.wait("timer")
	until param == timer
end

function env.os.reboot()
	table.insert( computer.eventBuffer, {"reboot"} )
end

function env.os.shutdown()
	love.event.quit()
end

function env.os.run( path, ... )
	if not env.disk.exists(path) then
		error( "No such file", 2 )
	end
	local file = env.disk.read(path)
	local fn, err = load( file, "="..env.disk.getFilename(path) )
	if not fn then
		env.shell.error(err)
		return
	end
	
	setfenv( fn, getfenv(2) )
	
	local success, err = pcall( fn, ... )
	if not success then
		env.shell.error(err)
	end
end

function env.os.elevate(fn)
	env.event.wait("elevateRequest")
	coroutine.yield(fn)
	local result = {env.event.wait("elevateResult")}
	return unpack( result, 2 )
end





env.event = {}

function env.event.wait(event)
	local e = { coroutine.yield(event) }
	if e[1] == "terminate" then
		error( "Terminated", 0 )
	else
		return unpack(e)
	end
end

function env.event.push( event, ... )
	table.insert( computer.eventBuffer, {event, ...} )
end

function env.event.keyDown(key)
	if key == "shift" then
		return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	elseif key == "ctrl" or key == "control" then
		return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
	elseif key == "gui" then
		return love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui")
	else
		return love.keyboard.isDown(key)
	end
end





env.mouse = {}

function env.mouse.isDown(button)
	return love.mouse.isDown(button)
end

setmetatable( env.mouse, {__index = function(t,k)
	if k == "x" then
		return computer.mouse.x
	elseif k == "y" then
		return computer.mouse.y
	elseif k == "pos" then
		return computer.mouse.x, computer.mouse.y
	elseif k == "drag" then
		if computer.mouse.drag then
			return {
				x = computer.mouse.drag.x,
				y = computer.mouse.drag.y
			}
		end
	end
end})





env.shell = {}

env.shell.path = {
	"",
	"/rom/programs/"
}
env.shell.extensions = {
	"",
	".lua"
}

env.shell.dir = "/disk1"

-- Type: "f", "d", "fd", "df" (file/dir, in specified order)
function env.shell.find( path, type )
	if not path then error( "Expected path [,type]", 2 ) end
	
	local found = {}
	table.insert( env.shell.path, env.shell.dir.."/" ) -- Add current dir to the list
	
	-- Find all matching files
	for _, prefix in ipairs(env.shell.path) do
		for _, suffix in ipairs(env.shell.extensions) do
			if env.disk.exists(prefix..path..suffix) then
				table.insert( found, prefix..path..suffix )
			end
		end
	end
	
	table.remove( env.shell.path, #env.shell.path ) -- Remove previously added current dir
	
	-- Return (type unspecified, any type)
	if not type then
		return found[1]
	end
	
	-- Return (type specified)
	for t in string.gmatch( type,"(.?)" ) do
		for i = 1, #found do
			if string.sub( env.disk.info(found[i]).type, 1, 1 ) == t then
				return env.disk.absolute(found[i])
			end
		end
	end
end

function env.shell.absolute(path)
	if not path or string.sub( path, 1, 1 ) == "/" then -- Absolute
		return env.disk.absolute(path)
	else -- Relative
		return env.disk.absolute( env.shell.dir.."/"..path )
	end
end

function env.shell.error( msg, level )
	env.screen.write( (env.shell.traceback and debug.traceback(msg, level) or msg) .. "\n",
		{color = "red+1", background = env.screen.background} )
end





env.net = {}

local http = require "socket.http"
local ltn12 = require "ltn12"

function env.net.request(url)
	local response = {}
	local body, code, headers, status = http.request{
		url = url,
		sink = ltn12.sink.table(response)
	}
	
	return {
		body = table.concat(response),
		code = code
	}
end





-- EXTENSIONS OF STANDARD LUA APIs

env.table = setmetatable( {}, {__index = table} )

function env.table.serialize( t, level )
	level = level or 1
	local s = "{\n"
	if type(t) ~= "table" then error( "Expected table", 2 ) end
	for k, v in pairs(t) do
		local serializable = (type(k) == "string" or type(k) == "number" or type(k) == "boolean")
			and (type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "table")
		
		if type(k) == "string" and not string.find(k, "(%s)") and serializable then
			s = s .. string.rep("  ", level)..k.." = "
		elseif type(k) == "string" and serializable then
			s = s .. string.rep("  ", level).."["..string.format("%q",k).."] = "
		elseif serializable then
			s = s .. string.rep("  ", level).."["..tostring(k).."] = "
		end
		
		if type(v) == "string" and serializable then
			s = s .. string.format("%q",v)..",\n"
		elseif type(v) == "table" and serializable then
			s = s .. env.table.serialize( v, level and level+1 )..",\n"
		elseif serializable then
			s = s .. tostring(v)..",\n"
		end
	end
	return s..string.rep("  ", level-1).."}"
end





env.print = env.screen.print





-- RETURN

return env