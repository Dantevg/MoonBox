--[[
	
	Sandbox library for MoonBox
	by RedPolygon
	
]]--

local sandbox = {}

function sandbox:createEnv( env, loadGeneral )
	if not env then
		-- Load standard env
		local vars = {
			"coroutine", "assert", "tostring", "tonumber", "rawget", "xpcall", "pcall", "bit", "getfenv", "rawset", "setmetatable", "package", "getmetatable", "type", "ipairs", "_VERSION", "debug", "table", "collectgarbage", "module", "next", "math", "setfenv", "select", "string", "unpack", "require", "rawequal", "pairs", "error"
		}
		for _, v in ipairs(vars) do
			self.env[v] = _G[v]
		end
	end
	
	-- Load MoonBox APIs and libraries
	setmetatable( self.env, {__index = _G} )
	local function load( path, ... )
		local files = love.filesystem.getDirectoryItems(path)
		for _, name in pairs(files) do
			local chunk, err = loadfile(path.."/"..name)
			if not chunk then error( err, 0 ) end
			setfenv( chunk, self.env )
			self.env[ name:match("^(.+)%.lua") ] = chunk(...)
		end
	end
	
	load( "env", self, love ) -- Load APIs, pass computer and love
	load("rom/lib") -- Load libraries (which don't need special access)
	
	-- Load general MoonBox env
	if loadGeneral ~= false then
		local chunk, err = loadfile("env.lua")
		if not chunk then error( err, 0 ) end
		local general = chunk(self)
		for k, v in pairs(general) do
			self.env[k] = v
		end
	end
	
	-- Set _G and options
	self.env._G = self.env
	self.env.screen.colors = self.env.screen.colors64
	self.env.shell.traceback = false
	
	setmetatable( self.env, env and {__index = env} or nil )
end

function sandbox.new( env, loadGeneral )
	local computer = setmetatable( {}, {__index = sandbox} )
	
	computer.env = {}
	computer.FPS = 20
	computer.version = "0.4"
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
	computer.running = true
	
	computer.screen = {}
	computer.screen.w = math.floor( love.graphics.getWidth() / settings.scale - 2*settings.border )
	computer.screen.h = math.floor( love.graphics.getHeight() / settings.scale - 2*settings.border )
	computer.screen.scale = settings.scale
	computer.screen.canvas = love.graphics.newCanvas( computer.screen.w, computer.screen.h )
	computer.screen.canvas:setFilter( "linear", "nearest" )
	computer.screen.shader = nil
	
	computer:createEnv( env, loadGeneral )
	
	return computer
end

function sandbox:start(bootPath)
	-- Load boot program
	local fn, err = love.filesystem.load( bootPath or "/rom/boot.lua" )
	if err then error(err) end
	
	-- Start boot program
	setfenv( fn, self.env )
	self.co = coroutine.create(fn)
	
	-- Add debug hook to prevent infinite loops without waiting
	function self.hook(trigger)
		if trigger == "count" then
			if love.timer.getTime() - self.chunkTime > 3 then
				error( "Timeout", 0 )
			end
		end
	end
	
	self:resume()
end

function sandbox:resume(...)
	if coroutine.status(self.co) == "dead" then
		-- love.window.close() -- Shutdown
		-- love.load() -- Reboot
		return false
	end
	
	debug.sethook( self.co, self.hook, "", 1000 ) -- Activate infinite loop hook
	self.chunkTime = love.timer.getTime() -- Reset starting time
	local ok, result = coroutine.resume( self.co, ... )
	debug.sethook(self.co) -- Reset hook
	
	if ok then
		self.eventFilter = result
	else
		self.error = self.env.shell.traceback and debug.traceback( self.co, result ) or result
	end
end

return sandbox