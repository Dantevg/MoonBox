--[[
	
	Globals
	
]]--

local args = {...}
local computer = args[1]
local love = args[2]
local env = setmetatable( {}, {__index = computer.env} )



-- FILE / INPUT READING

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
	expect( path, "string" )
	
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



-- LUA EXTENSIONS / MODIFICATIONS

function env.getfenv(level)
	expect( level, {"number", "nil"} )
	
	level = level or 1
	if level == 0 then
		return env._G
	elseif level >= 1 then
		local e = getfenv(level+1)
		if e == _G then
			return env._G
		else
			return e
		end
	else
		error( "bad agrument #1 to 'getfenv' (invalid level)", 2 ) -- Mimic standard lua error
	end
end

env.expect = expect



-- RETURN

return env