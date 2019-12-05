--[[
	
	MoonBox Lua sandbox
	by RedPolygon
	
	VERSION 0.3
	
]]--

sandbox = require "sandbox"

-- CONSTANTS

settings = {
	width = 300,
	height = 200,
	scale = 2,
	fullscreen = false,
	border = 1,
	screenshotScale = 4,
	screenshotBorder = true
}





-- VARIABLES

computer = {}
menu = {}

active = nil





-- FUNCTIONS

-- expect( value (any), expectation (string|table) )
   --> expectation expected, got type(value)
-- expect( value (any), expectation (string|table), n (number), name (string) )
   --> bad argument #n to name (expectation expected, got type(value))
function expect( value, expectation, n, name )
	local function correct( v, e )
		if e == "tonumber" then
			return type(v) == "number" or type(tonumber(v)) == "number"
		else
			return type(v) == e
		end
	end
	
	local function concat(tbl)
		for k, v in pairs(tbl) do
			if v == "tonumber" then
				tbl[k] = "number"
			end
		end
		return table.concat( tbl, " or " )
	end
	
	local function makeError( v, e, n, fnName, argName )
		if n then
			return "bad argument #"..n.." to '"..name.."' (expected "..concat(e," or ")..", got "..type(v)..")"
		else
			return concat(e," or ").." expected, got "..type(v)
		end
	end
	
	if type(expectation) == "string" then
		if not correct( value, expectation ) then
			error( makeError( value, (expectation=="tonumber" and {"number"} or {expectation}), n, name ), 3 )
		end
	elseif type(expectation) == "table" then
		for _, e in ipairs(expectation) do
			if correct( value, e ) then return true end
		end
		error( makeError( value, expectation, n, name ), 3 )
	end
	return true
end

function table.serialize( t, level )
	expect( t, "table" )
	
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

function setWindow(s)
	s = s or {}
	local _, _, window = love.window.getMode()
	
	love.window.setMode(
		s.w and (s.w+2*settings.border) * settings.scale or (settings.width+2*settings.border) * settings.scale,
		s.h and (s.h+2*settings.border) * settings.scale or (settings.height+2*settings.border) * settings.scale,
		{
			fullscreen = s.fullscreen or settings.fullscreen,
			x = s.x or window.x,
			y = s.y or window.y,
			resizable = true,
		}
	)
end

function loadSettings()
	-- package.loaded.settings = nil -- Reset if already loaded
	-- settings = require "settings" -- Load settings file
	
	-- Don't attempt to read settings that aren't there
	if not love.filesystem.getInfo("settings.lua") then return end
	
	-- Read file
	local file, err = love.filesystem.read("settings.lua")
	if not file then error("Could not open settings file: "..err) end
	
	-- Load chunk
	local chunk, err = load(file)
	if not chunk then error("Could not read settings file: "..err) end
	
	-- Execute chunk, get settings
	local user = chunk()
	if not user then error("Malformed settings file") end
	for k, v in pairs(settings) do
		settings[k] = user[k] or settings[k]
	end
end

function love.load()
	loadSettings()
	setWindow()
	
	if not love.filesystem.getInfo("disk1") or love.filesystem.getInfo("disk1").type ~= "directory" then
		firstBoot = true
		love.filesystem.createDirectory("disk1")
	end
	
	love.keyboard.setKeyRepeat(true)
	
	computer = sandbox.new()
	computer:start()
	menu = sandbox.new( _G, false )
	menu:start("/rom/admin.lua")
	active = (firstBoot and menu or computer)
end

function love.update(dt)
	if active.error then return end
	
	if active.running then
		active.currentFrame = active.currentFrame + 1
		active.clock = active.clock + dt
	end
	
	-- Ctrl-r detection (reboot)
	if love.keyboard.isDown("lctrl") and love.keyboard.isDown("r") then
		if not active.reboot then
			active.reboot = love.timer.getTime()
		end
		if active.reboot + 2 < love.timer.getTime() then
			love.load() -- Reboot
		end
	else
		active.reboot = false
	end
	
	-- Ctrl-t detection (terminate)
	if love.keyboard.isDown("lctrl") and love.keyboard.isDown("t") and active.running then
		if not active.terminate then
			active.terminate = love.timer.getTime()
		end
		if active.terminate + 2 < love.timer.getTime() then
			table.insert( active.eventBuffer, {"terminate"} )
			active.terminate = false
		end
	else
		active.terminate = false
	end
	
	-- Queue timer events
	for n, time in pairs(active.timers) do
		if love.timer.getTime() >= time and type(n) == "number" then
			table.insert( active.eventBuffer, {"timer", n} )
			active.timers[n] = nil
		end
	end
	
	-- Return events
	-- if #active.eventBuffer > 0 then table.insert( active.events, {} ) end -- For event debugging
	while #active.eventBuffer > 0 do
		-- table.insert( active.events[#active.events], active.eventBuffer[1][1] ) -- For event debugging
		if active.eventBuffer[1][1] == "reboot" then
			love.load()
			return
		elseif active.eventFilter == "elevateRequest" then
			elevated = sandbox.new()
			elevated:start( setmetatable( _G, {__index = computer.env} ), "/rom/elevate.lua" )
			local _, fn = coroutine.resume( active.co, true )
			table.insert( elevated.eventBuffer, {"elevateFunction", fn} )
			active = elevated
			return
		elseif active.eventBuffer[1][1] == "elevateReturn" then
			computer.eventFilter = nil
			table.insert( computer.eventBuffer, {"elevateResult", unpack(active.eventBuffer[1], 2)} )
			active = computer
			elevated = nil
			return
		elseif active.eventFilter == nil or active.eventFilter == active.eventBuffer[1][1] or active.eventBuffer[1][1] == "terminate" then
			active:resume( unpack(active.eventBuffer[1]) )
		end
		table.remove( active.eventBuffer, 1 )
	end
end

function love.draw()
	if active.error then
		local w, h = love.graphics.getDimensions()
		love.graphics.setBackgroundColor( 1, 0.267, 0.267 ) -- #F44
		love.graphics.setColor( 1, 1, 1 )
		love.graphics.setBlendMode("alpha")
		love.graphics.printf( "Error:", 50, math.floor( h/2-95 ), w-100, "center" )
		love.graphics.printf( active.error, 50, math.floor( h/2-75 ), w-100, "center" )
	else
		local border = settings.border*settings.scale
		love.graphics.setColor( 1,1,1,1 )
		if active == menu then
			love.graphics.draw( menu.screen.canvas, border, border, 0, settings.scale )
			-- Draw borders
			local w, h = love.graphics.getDimensions()
			love.graphics.rectangle( "fill", 0, 0, w, border )
			love.graphics.rectangle( "fill", w-border, 0, border, h )
			love.graphics.rectangle( "fill", 0, h-border, w, border )
			love.graphics.rectangle( "fill", 0, 0, border, h )
		else
			if computer.screen.shader then
				love.graphics.setShader(computer.screen.shader)
			end
			love.graphics.draw( active.screen.canvas, border, border, 0, settings.scale )
			love.graphics.setShader() -- Reset shader
		end
	end
	
	
	--[[love.graphics.print( active.currentFrame%100, love.graphics.getWidth()-60, 10 )
	love.graphics.print( love.timer.getFPS(), love.graphics.getWidth()-30, 10 )
	for i = 1, #active.events do
		local y = 20 + (#active.events-i+1) * 15
		for j = 1, #active.events[i] do
			local x = love.graphics.getWidth() - 60*j
			love.graphics.print( active.events[i][j], x, y )
		end
	end]]-- For event debugging
end

function love.run() -- Modified v11.0 from https://love2d.org/wiki/love.run
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end
 
		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
 
			if love.draw then love.draw() end
 
			love.graphics.present()
		end
		
		-- MODIFIED (custom FPS cap)
		if love.timer then
			computer.nextFrame = computer.nextFrame + 1/computer.FPS
			local current = love.timer.getTime()
			if computer.nextFrame <= current then
				computer.nextFrame = current
				return
			end
			love.timer.sleep( computer.nextFrame - current )
		end
	end
end

function love.keypressed(key)
	-- if key == "ralt" then debug.debug() end
	-- Menu detection
	if love.keyboard.isDown("lctrl") and key == "rctrl"
		or love.keyboard.isDown("rctrl") and key == "lctrl" then
		active.running = false
		active.reboot = false
		active.terminate = false
		active = (active == menu) and computer or menu
		active.running = true
	end
	
	local keyDown = active.env.event.keyDown
	if key == "return" then
		key = "enter" -- Replace "return" with "enter"
	elseif key == "lshift" or key == "rshift" then
		key = "shift"
	elseif key == "lctrl" or key == "rctrl" then
		key = "ctrl"
	elseif key == "lalt" or key == "ralt" then
		key = "alt"
	elseif key == "lgui" or key == "rgui" then
		key = "gui"
	end
	table.insert( active.eventBuffer, { "key", key } )
end
function love.keyreleased(key)
	if key == "return" then
		key = "enter" -- Replace "return" with "enter"
	elseif key == "lshift" or key == "rshift" then
		key = "shift"
	elseif key == "lctrl" or key == "rctrl" then
		key = "ctrl"
	elseif key == "lalt" or key == "ralt" then
		key = "alt"
	elseif key == "lgui" or key == "rgui" then
		key = "gui"
	end
	table.insert( active.eventBuffer, { "keyUp", key } )
end

function love.textinput(char)
	table.insert( active.eventBuffer, { "char", char } )
end

local function getCoordinates( x, y )
	return math.floor( x / settings.scale ) - settings.border + 1,
		math.floor( y / settings.scale ) - settings.border + 1
end

function love.mousepressed( x, y, btn )
	x, y = getCoordinates( x, y )
	if x >= 1 and x <= settings.width and y >= 1 and y <= settings.height then
		table.insert( active.eventBuffer, { "mouse", x, y, btn } )
	end
end
function love.mousereleased( x, y, btn )
	x, y = getCoordinates( x, y )
	table.insert( active.eventBuffer, { "mouseUp", x, y, btn } )
	
	active.mouse.drag = false
end

function love.wheelmoved( _, amount )
	local x, y = getCoordinates( love.mouse.getPosition() )
	table.insert( computer.eventBuffer, { "scroll", x, y, amount } )
end

function love.mousemoved( x, y )
	x, y = getCoordinates( x, y )
	if math.abs( x - active.mouse.x ) >= 1 or math.abs( y - active.mouse.y ) >= 1 then
		local dx, dy = x - active.mouse.x, y - active.mouse.y
		if love.mouse.isDown(1) then
			table.insert( active.eventBuffer, { "drag", dx, dy, 1 } )
			if not active.mouse.drag then active.mouse.drag = {x=x, y=y} end
		elseif love.mouse.isDown(2) then
			table.insert( active.eventBuffer, { "drag", dx, dy, 2 } )
			if not active.mouse.drag then active.mouse.drag = {x=x, y=y} end
		end
	end
	active.mouse.x, active.mouse.y = math.min(math.max(x, 1), active.screen.w), math.min(math.max(y, 1), active.screen.h)
end

function love.resize( w, h )
	local function resize(which)
		which.screen.w = math.floor( w / settings.scale ) - 2*settings.border
		which.screen.h = math.floor( h / settings.scale ) - 2*settings.border
		
		which.env.screen.width = which.screen.w
		which.env.screen.height = which.screen.h
		
		if which.env.screen.font then
			which.env.screen.charWidth = math.floor( which.screen.w / (which.env.screen.font.width+1) )
			which.env.screen.charHeight = math.floor( which.screen.h / (which.env.screen.font.height+1) )
		end
		
		-- Save canvas to image
		local image = love.graphics.newImage( which.screen.canvas:newImageData() )
		
		-- Copy image to canvas
		local newCanvas = love.graphics.newCanvas( which.screen.w, which.screen.h )
		newCanvas:renderTo(function()
			love.graphics.setColor( 1, 1, 1, 1 )
			love.graphics.draw( image, 0, 0 )
		end)
		
		which.screen.canvas = newCanvas
		which.screen.canvas:setFilter( "linear", "nearest" )
		
		table.insert( which.eventBuffer, { "resize", which.screen.w, which.screen.h } )
	end
	resize(computer)
	resize(menu)
end