--[[
	
	Sandbox library for MoonBox
	by RedPolygon
	
]]--

local sandbox = {}

function sandbox.new()
	local computer = {}
	
	computer.env = {}
	computer.FPS = 20
	computer.version = "0.3"
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
	
	return setmetatable( computer, {__index = sandbox} )
end

function sandbox:start( env, bootPath )
	if env then
		self.env = setmetatable( {}, {__index = env} )
	else
		-- Load standard env
		local vars = {
			"coroutine", "assert", "tostring", "tonumber", "rawget", "xpcall", "pcall", "bit", "getfenv", "rawset", "setmetatable", "package", "getmetatable", "type", "ipairs", "_VERSION", "debug", "table", "collectgarbage", "module", "next", "math", "setfenv", "select", "string", "unpack", "require", "rawequal", "pairs", "error"
		}
		for _, v in ipairs(vars) do
			self.env[v] = _G[v]
		end
	end
	
	-- Load general MoonBox env
	local env = loadfile("env.lua")(self)
	for k, v in pairs(env) do
		self.env[k] = v
	end
	
	-- Load MoonBox APIs and libraries
	local function load( path, ... )
		local files = love.filesystem.getDirectoryItems(path)
		for _, name in pairs(files) do
			local chunk = loadfile(path.."/"..name)
			setfenv( chunk, setmetatable({}, {__index = self.env}) )
			self.env[ name:match("^(.+)%.lua") ] = chunk(...)
		end
	end
	
	load( "env", self, love, _G ) -- Load APIs, pass computer and love
	load("rom/lib") -- Load libraries (which don't need special access)
	
	-- Set shortcuts, _G and options
	self.env.print = self.env.screen.print
	self.env._G = self.env
	self.env.screen.colors = self.env.screen.colors64
	self.env.shell.traceback = false
	
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