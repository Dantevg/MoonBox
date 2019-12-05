--[[
	
	OS API
	Provides OS functions for time/timing,
		shutdown/reboot communication, execution and threads
	
]]--

local osOld = os
local os = {}
local args = {...}
local computer = args[1]
local love = args[2]



-- VARIABLES / CONSTANTS

os.FPS = computer.FPS
os.version = "MoonBox v"..computer.version



-- TIME FUNCTIONS

function os.clock()
	return math.floor( computer.clock * 1000 ) / 1000
end

function os.time( h24, seconds )
	expect( h24, {"boolean", "nil"}, 1, "os.time" )
	expect( seconds, {"number", "nil"}, 2, "os.time" )
	
	if h24 then
		return osOld.date( "%H:%M"..(seconds and ":%S" or "") )
	else
		return osOld.date("%I:%M"..(seconds and ":%S" or "").." %p")
	end
end

function os.date(yearFirst)
	expect( yearFirst, {"boolean", "nil"} )
	
	if yearFirst then
		return osOld.date("%Y-%m-%d")
	else
		return osOld.date("%d-%m-%Y")
	end
end

function os.datetime()
	return osOld.date("*t")
end

function os.startTimer(time)
	expect( time, {"number","nil"} )
	
	time = math.ceil( (time or 0)*computer.FPS ) / computer.FPS
	time = math.max( time, 1/computer.FPS )
	table.insert( computer.timers, computer.timers.n, love.timer.getTime() + time )
	computer.timers.n = computer.timers.n+1
	return computer.timers.n-1
end

function os.cancelTimer(id)
	computer.timers[id] = nil
end

function os.sleep(time)
	expect( time, {"number", "nil"} )
	
	local timer = os.startTimer(time)
	repeat
		local event, param = event.wait("timer")
	until param == timer
end



-- REBOOT / SHUTDOWN COMMUNICATION

function os.reboot()
	table.insert( computer.eventBuffer, {"reboot"} )
end

function os.shutdown()
	love.event.quit()
end



-- EXECUTION FUNCTIONS

function os.run( path, ... )
	expect( path, "string", 1, "os.run" )
	
	if not disk.exists(path) then
		error( "No such file", 2 )
	end
	local file = disk.read(path)
	local fn, err = load( file, "="..disk.getFilename(path) )
	if not fn then
		shell.error(err)
		return
	end
	
	setfenv( fn, getfenv(2) )
	
	local success, err = pcall( fn, ... )
	if not success then
		shell.error(err)
	end
end

function os.elevate(fn)
	expect( fn, "function" )
	
	event.wait("elevateRequest")
	coroutine.yield(fn)
	local result = {event.wait("elevateResult")}
	return unpack( result, 2 )
end



-- THREAD FUNCTIONS

local thread = {}

-- os.newThread( source (string) [,immediate (boolean)] )
-- source: path to file, or string of code when immediate == true
function os.newThread( source, immediate )
	expect( source, "string", 1, "os.newThread" )
	expect( immediate, {"boolean", "nil"}, 2, "os.newThread" )
	
	if immediate then
		source = source.."\n" -- For love.thread.newThread() to recognize as a code string
	elseif not disk.exists(source) then
		error( "No such file", 2 )
	end
	
	return setmetatable(
		{
			source = immediate and source or disk.read(source),
			thread = love.thread.newThread("/rom/programs/thread.lua"),
			channel = love.thread.newChannel()
		},
		{__index = function(t,k)
			if k == "running" then
				return t.thread:isRunning()
			elseif k == "error" then
				return t.thread:getError()
			elseif thread[k] then
				return thread[k]
			else
				return rawget(t,k)
			end
		end}
	)
end

function thread:start(...)
	self.thread:start( self.channel, self.source, ... )
end

function thread:wait()
	self.thread:wait()
end

-- Thread:send( data (any) [,wait (number|boolean)] )
-- wait:	- true: wait until message accepted
-- 				-    0: don't wait
-- 				-   >0: wait until message accepted or until timeout reached
function thread:send( data, wait )
	expect( wait, {"tonumber", "nil"}, 2, "(Thread):send" )
	
	if not data then return end
	wait = tonumber(wait) or 0
	
	if wait == true then -- Wait until message accepted
		return self.channel:supply(data)
	elseif wait > 0 then -- Wait until message accepted or specific timeout
		return self.channel:supply( data, wait )
	else -- Don't wait
		self.channel:push(value)
		return true
	end
end

-- Thread:receive( [type (string)] )
-- type:	- "peek" (don't remove message from queue)
-- 				- "wait" (wait until message is available)
function thread:receive(type)
	expect( type, {"string", "nil"} )
	
	if type == "peek" then
		return self.channel:peek()
	elseif type == "wait" then
		return self.channel:demand()
	else
		return self.channel:pop()
	end
end

function os.newWindow()
	return setmetatable(
		{
			thread = love.thread.newThread(
				'os.execute("C:/program files/LOVE/love.exe" '..love.filesystem.getSource()..')\n'
			),
			channel = love.thread.newChannel()
		},
		{__index = function(t,k)
			if k == "active" then
				return self.thread:isRunning()
			elseif k == "error" then
				return self.thread:getError()
			elseif thread[k] then
				return thread[k]
			else
				return rawget(t,k)
			end
		end}
	)
end

--[[os.blacklists = {}

function os.runSandboxed( path, blacklist, ... )
	-- Read file
	if not disk.exists(path) then
		error( "No such file", 2 )
	end
	local file = disk.read(path)
	
	-- Prepare blacklist and env
	blacklist = blacklist or {
		os = {
			run = true,
		},
		load = true,
		loadstring = true,
		loadfile = true,
		require = true,
	}
	
	local function blacklistEnv( environment, realEnv, blacklistElement, trace )
		setmetatable( environment, {
			__index = function( T, K )
				for k in pairs(blacklistElement) do
					if type(k) ~= "table" and K == k then
						return nil
					end
				end
				return realEnv[K]
			end
		} )
		
		for k, element in pairs(blacklistElement) do
			if type(element) == "table" then
				environment[k] = {}
				add( environment[k], realEnv[k], element, trace..k.."." )
			end
		end
	end
	
	local sandboxEnv = {}
	add( sandboxEnv, _G, blacklist, "" )
	
	os.blacklists[ debug.getinfo(2).short_src ] = blacklist
	
	-- Run
	local fn, err = load( file, "="..disk.getFilename(path) )
	if not fn then
		shell.error(err)
		return
	end
	setfenv( fn, sandboxEnv )
	
	local success, err = pcall( fn, ... )
	if not success then
		shell.error(err)
	end
end

function os.askPermission(fn)
	local programName = debug.getinfo(2).short_src
	print( programName .. " wants permission to use "..fn )
	
	local blacklistPath = 
	for k in pairs
	os.blacklists[programName]
end]]--



-- RETURN

return os