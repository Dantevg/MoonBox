--[[
	
	Oxygen Lua emulator
	by RedPolygon
	
	VERSION 0.1
	
]]--

-- VARIABLES

computer = {}





-- FUNCTIONS

function computer.start()
	computer.env = {}
	computer.FPS = 20
	computer.version = "0.1"
	computer.nextFrame = 0
	computer.clock = 0
	computer.currentFrame = 0
	
	computer.mouse = {
		x = 0,
		y = 0,
	}
	computer.timers = {n=1}
	computer.eventFilter = nil
	computer.eventBuffer = {}
	computer.error = nil
	computer.reboot = false
	computer.terminate = false
	
	computer.screen = {}
	computer.screen.w = math.floor( love.graphics.getWidth() / settings.scale )
	computer.screen.h = math.floor( love.graphics.getHeight() / settings.scale )
	computer.screen.scale = settings.scale
	computer.screen.canvas = love.graphics.newCanvas( computer.screen.w, computer.screen.h )
	computer.screen.canvas:setFilter( "linear", "nearest" )
	
	-- Load standard env
	local env = {
		"coroutine", "assert", "tostring", "tonumber", "rawget", "xpcall", "pcall", "bit", "getfenv", "rawset", "setmetatable", "package", "getmetatable", "type", "ipairs", "_VERSION", "debug", "table", "collectgarbage", "module", "next", "math", "setfenv", "select", "string", "unpack", "require", "rawequal", "pairs", "error"
	}
	for _, v in ipairs(env) do
		computer.env[v] = _G[v]
	end
	
	-- Load Oxygen env
	package.loaded.env = nil -- Reset if already loaded
	local env = require "env"
	for k, v in pairs(env) do
		computer.env[k] = v
	end
	
	computer.env._G = computer.env
	
	-- Load boot program
	local fn, err = love.filesystem.load("rom/boot.lua")
	if err then error(err) end
	
	-- Start boot program
	setfenv( fn, computer.env )
	co = coroutine.create(fn)
	computer.resume()
end

function computer.resume(...)
	if coroutine.status(co) == "dead" then
		-- love.window.close() -- Shutdown
		-- love.load() -- Reboot
		return false
	end
	local ok, result = coroutine.resume( co, ... )
	if ok then
		computer.eventFilter = result
	else
		computer.error = result
	end
end

function setWindow(s)
	s = s or {}
	love.window.setMode(
		s.w and s.w * settings.scale or settings.width * settings.scale,
		s.h and s.h * settings.scale or settings.height * settings.scale,
		{
			fullscreen = s.fullscreen or settings.fullscreen,
			x = s.x,
			y = s.y,
			resizable = true,
		}
	)
end

function love.load()
	settings = require "settings" -- Load settings file
	
	setWindow()
	
	if not love.filesystem.getInfo("disk1") or love.filesystem.getInfo("disk1").type ~= "folder" then
		love.filesystem.createDirectory("disk1")
	end
	
	love.keyboard.setKeyRepeat(true)
	
	computer.start()
end

function love.update(dt)
	if computer.error then return end
	
	computer.currentFrame = computer.currentFrame + 1
	computer.clock = computer.clock + dt
	
	-- Ctrl-r detection
	if love.keyboard.isDown("lctrl") and love.keyboard.isDown("r") then
		if not computer.reboot then
			computer.reboot = love.timer.getTime()
		end
		if computer.reboot + 2 < love.timer.getTime() then
			love.load() -- Reboot
		end
	else
		computer.reboot = false
	end
	
	-- Ctrl-t detection
	if love.keyboard.isDown("lctrl") and love.keyboard.isDown("t") then
		if not computer.terminate then
			computer.terminate = love.timer.getTime()
		end
		if computer.terminate + 2 < love.timer.getTime() then
			table.insert( computer.eventBuffer, {"terminate"} )
			computer.terminate = false
		end
	else
		computer.terminate = false
	end
	
	-- Queue timer events
  for n, time in pairs(computer.timers) do
    if love.timer.getTime() >= time and type(n) == "number" then
      table.insert( computer.eventBuffer, {"timer", n} )
      computer.timers[n] = nil
    end
  end
  
  -- Return events
	for i = 1, #computer.eventBuffer do
		if computer.eventBuffer[1][1] == "reboot" then
			love.load()
			return
		end
		
		if computer.eventFilter == nil or computer.eventFilter == computer.eventBuffer[1][1] then
			computer.resume( unpack(computer.eventBuffer[1]) )
    end
    table.remove( computer.eventBuffer, 1 )
  end
end

function love.draw()
	if computer.error then
		local w, h = love.graphics.getDimensions()
		love.graphics.setBackgroundColor( 1, 0.267, 0.267 ) -- #F44
		love.graphics.setColor( 1, 1, 1 )
		love.graphics.setBlendMode("alpha")
    love.graphics.printf( "Error:", 50, math.floor( h/2-95 ), w-100, "center" )
    love.graphics.printf( computer.error, 50, math.floor( h/2-75 ), w-100, "center" )
	else
		love.graphics.setColor( 1,1,1,1 )
		love.graphics.setBlendMode( "alpha", "premultiplied" )
		love.graphics.draw( computer.screen.canvas, 0, 0, 0, computer.screen.scale )
		love.graphics.setBlendMode( "alpha" ) -- Reset blendMode
	end
end

function love.run() -- Modified v1.10 from https://love2d.org/wiki/love.run
	if love.math then
		love.math.setRandomSeed(os.time())
	end
	
	if love.load then love.load(arg) end
	
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
	
	local dt = 0
	
	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
		
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end
		
		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
		
		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end
		
		-- MODIFIED!
		if love.timer then
			local current = love.timer.getTime()
      if current < computer.nextFrame then
        love.timer.sleep( computer.nextFrame - current )
      end
      computer.nextFrame = current + 1/computer.FPS
		end
	end
	
end

function love.keypressed(key)
	-- if key == "ralt" then debug.debug() end
	local keyDown = computer.env.event.keyDown
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
	table.insert( computer.eventBuffer, { "key", key } )
	
	if key == "'" and keyDown("shift") then
		table.insert( computer.eventBuffer, { "char", '"' } )
	elseif key == "'" and not keyDown("shift") then
		table.insert( computer.eventBuffer, { "char", "'" } )
	end
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
	table.insert( computer.eventBuffer, { "keyUp", key } )
end

function love.textinput(char)
	if char ~= "'" and char ~= '"' then
		table.insert( computer.eventBuffer, { "char", char } )
	end
end

local function getCoordinates( x, y )
	return math.floor( x / computer.screen.scale ) + 1,
		math.floor( y / computer.screen.scale ) + 1
end

function love.mousepressed( x, y, btn )
	x, y = getCoordinates( x, y )
	table.insert( computer.eventBuffer, { "mouse", x, y, btn } )
end
function love.mousereleased( x, y, btn )
	x, y = getCoordinates( x, y )
	table.insert( computer.eventBuffer, { "mouseUp", x, y, btn } )
	
	computer.mouse.drag = false
end

function love.wheelmoved(dir)
	local x, y = getCoordinates( love.mouse.getPosition() )
  table.insert( computer.eventBuffer, { "scroll", x, y, dir } )
end

function love.mousemoved( x, y )
	x, y = getCoordinates( x, y )
	if math.abs( x - computer.mouse.x ) >= 1 or math.abs( y - computer.mouse.y ) >= 1 then
		local dx, dy = x - computer.mouse.x, y - computer.mouse.y
		if love.mouse.isDown(1) then
			table.insert( computer.eventBuffer, { "drag", dx, dy, 1 } )
			if not computer.mouse.drag then computer.mouse.drag = {x=x, y=y} end
		elseif love.mouse.isDown(2) then
			table.insert( computer.eventBuffer, { "drag", dx, dy, 2 } )
			if not computer.mouse.drag then computer.mouse.drag = {x=x, y=y} end
		end
		computer.mouse.x, computer.mouse.y = x, y
	end
end

function love.resize( w, h )
	computer.screen.w = math.floor( w / settings.scale )
	computer.screen.h = math.floor( h / settings.scale )
	
	computer.env.screen.width = computer.screen.w
	computer.env.screen.height = computer.screen.h
	
	if computer.env.screen.font then
		computer.env.screen.charWidth = math.floor( computer.screen.w / (computer.env.screen.font.width+1) )
		computer.env.screen.charHeight = math.floor( computer.screen.h / (computer.env.screen.font.height+1) )
	end
	
	-- Save canvas to image
	local image = love.graphics.newImage( computer.screen.canvas:newImageData() )
	
	-- Copy image to canvas
	local newCanvas = love.graphics.newCanvas( computer.screen.w, computer.screen.h )
	newCanvas:renderTo(function()
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.draw( image, 0, 0 )
	end)
	
	computer.screen.canvas = newCanvas
	computer.screen.canvas:setFilter( "linear", "nearest" )
	
	table.insert( computer.eventBuffer, { "resize", computer.screen.w, computer.screen.h } )
end