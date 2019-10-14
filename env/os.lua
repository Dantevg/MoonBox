--[[
	
	OS API
	Provides OS functions for time/timing, shutdown/reboot communication and execution
	
]]--

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
	if h24 then
		return os.date( "%H:%M"..(seconds and ":%S" or "") )
	else
		return os.date("%I:%M"..(seconds and ":%S" or "").." %p")
	end
end

function os.date(yearFirst)
	if yearFirst then
		return os.date("%Y-%m-%d")
	else
		return os.date("%d-%m-%Y")
	end
end

function os.datetime()
	return os.date("*t")
end

function os.startTimer(time)
	time = math.ceil( (time or 0)*computer.FPS ) / computer.FPS
	time = math.max( time, 1/computer.FPS )
	table.insert( computer.timers, computer.timers.n, love.timer.getTime() + time )
	computer.timers.n = computer.timers.n+1
	return computer.timers.n-1
end

function os.sleep(time)
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
	event.wait("elevateRequest")
	coroutine.yield(fn)
	local result = {event.wait("elevateResult")}
	return unpack( result, 2 )
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