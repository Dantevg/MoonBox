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
			local chunk, err = love.filesystem.load(path.."/"..name)
			if not chunk then error( err, 0 ) end
			setfenv( chunk, self.env )
			self.env[ name:match("^(.+)%.lua") ] = chunk(...)
		end
	end
	
	load( "env", self, love ) -- Load APIs, pass computer and love
	load("rom/lib") -- Load libraries (which don't need special access)
	
	-- Load general MoonBox env
	if loadGeneral ~= false then
		local chunk, err = love.filesystem.load("env.lua")
		if not chunk then error( err, 0 ) end
		local general = chunk(self)
		for k, v in pairs(general) do
			self.env[k] = v
		end
	end
	
	-- Set shortcuts, _G and options
	self.env.log = print
	self.env.print = self.env.screen.print
	self.env._G = self.env
	self.env.screen.colours = self.env.screen.colours64
	self.env.shell.traceback = false
	
	setmetatable( self.env, env and {__index = env} or nil )
	
	log( "Created sandbox env", 3 )
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
	computer.screen.width = math.floor( love.graphics.getWidth() / settings.scale - 2*settings.border )
	computer.screen.height = math.floor( love.graphics.getHeight() / settings.scale - 2*settings.border )
	computer.screen.scale = settings.scale
	computer.screen.canvas = love.graphics.newCanvas( computer.screen.width, computer.screen.height )
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
	
	function self.loghook(trigger)
		local info = trigger.." "
		local caller = debug.getinfo(2)
		if not caller then return end
		if caller.source == "@main.lua" then -- Filter out expect function, as it will fill the log
			if caller.name == "expect" or caller.name == "correct" or caller.name == "concat" or caller.name == "makeError" then
				return
			end
		end
		
		info = info .. caller.what.."\t"
		if caller.what == "C" then
			info = info .. "\t"..caller.namewhat.." "..(caller.name or "[no name]")
		else
			if string.sub( caller.source, 1, 1 ) == "@" then -- File source
				info = info .. caller.short_src..":"..caller.currentline
			else -- Non-file source
				info = info .. caller.short_src..":"..caller.currentline
			end
			info = info .. ": "..caller.namewhat.." "..(caller.name or "[no name]")
			info = info .. " ("..caller.linedefined.." - "..caller.lastlinedefined..")"
		end
		
		log( info, trigger=="line" and 0 or 1 )
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
	if settings.logLevel == 1 then
		debug.sethook( self.co, self.loghook, "cr", 0 ) -- Activate log hook without line
	elseif settings.logLevel <= 0 then
		debug.sethook( self.co, self.loghook, "crl", 0 ) -- Activate log hook
	end
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