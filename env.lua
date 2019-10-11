--[[
	
	Globals
	
]]--

local args = {...}
local computer = args[1]
local love = args[2]
local env = setmetatable( {}, {__index = computer.env} )



-- FILE / INPUT READING

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



-- LUA EXTENSIONS

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



-- RETURN

return env