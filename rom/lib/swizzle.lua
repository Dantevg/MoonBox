--[[
	
	Swizzle lib
	Provides swizzling functionality like in GLSL
	(eg. colour[1] == colour.r, pos.xy = pos.yx)
	
	I tried to make this lib as adaptive as possible, combining all coding styles
	to make everybody happy :)
	- swizzle.new and swizzle.set can both be called with a table as data
		or with individual arguments as data
	- swizzle() is alias for swizzle.new()
	- swizzled tables have their own .set() function, but you can also use the general :set()
	
	Usage:
	- These all do exactly the same:
		swizzle.new(...), swizzle.new({...}), swizzle.new{...},
		swizzle(...), swizzle({...}), swizzle{...}
	- To replace a swizzled table: (these also do exactly the same)
		swizzle.set( t, ... ), swizzle.set( t, {...} ),
		t:set(...), t:set({...}), t:set{...},
		t.set(...), t.set({...}), t.set{...}
	- Attempts to replace parts of a swizzled table with a different number of values results in an error:
		t.rgb = t.rgba --> Swizzle count mismatch
	
]]--

local swizzle = {}

swizzle.mask = {
	r = 1, g = 2, b = 3, a = 4, -- RGBA colour
	h = 1, s = 2, l = 3, a = 4, -- HSLA colour
	x = 1, y = 2, z = 3,        -- XYZ coordinates
	w = 1, h = 2                -- W/H sizes
}



-- HELPER FUNCTIONS

local function mtFn( a, b, fn )
	if type(a) == "number" then
		a, b = b, a
	end
	
	local t = {}
	if type(b) == "table" then
		if #a ~= #b then error( "Tables must be of same length", 3 ) end
		for i = 1, #a do
			table.insert( t, fn(a[i], b[i]) )
		end
	else
		for i = 1, #a do
			table.insert( t, fn(a[i], b) )
		end
	end
	
	return setmetatable( t, swizzle.mt )
end



-- METATABLE FUNCTIONS

swizzle.mt = {}
swizzle.mt.swizzle = true

function swizzle.mt.__index( t, k )
	if k == "set" then
		return swizzle.set
	end
	
	if type(k) ~= "string" then return nil end
	
	if #k == 1 then
		local index = swizzle.mask[k]
		if index then
			return t[index]
		end
	else
		local r = {}
		for i = 1, #k do
			local index = swizzle.mask[ string.sub(k,i,i) ]
			if index then
				r[i] = t[index]
			else
				error( "Invalid swizzle mask", 2 )
			end
		end
		return setmetatable( r, swizzle.mt )
	end
end

function swizzle.mt.__newindex( t, k, v )
	if #k == 1 then
		local index = swizzle.mask[k]
		if index then
			t[index] = v
		end
	else
		if type(v) ~= "table" or #k ~= #v then error( "Swizzle count mismatch", 2 ) end
		for i = 1, #k do
			local index = swizzle.mask[ string.sub(k,i,i) ]
			if index then
				t[index] = v[i]
			end
		end
	end
end

function swizzle.mt.__add( a, b )
	return mtFn( a, b, function(a,b) return a+b end )
end

function swizzle.mt.__sub( a, b )
	return mtFn( a, b, function(a,b) return a-b end )
end

function swizzle.mt.__mul( a, b )
	return mtFn( a, b, function(a,b) return a*b end )
end

function swizzle.mt.__div( a, b )
	return mtFn( a, b, function(a,b) return a/b end )
end

function swizzle.mt.__mod( a, b )
	return mtFn( a, b, function(a,b) return a%b end )
end

function swizzle.mt.__pow( a, b )
	return mtFn( a, b, function(a,b) return a^b end )
end

function swizzle.mt.__unm(a)
	return mtFn( a, nil, function(a) return -a end )
end

function swizzle.mt.__eq( a, b )
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

function swizzle.mt.__tostring(t)
	return "("..table.concat( t, "," )..")"
end



-- FUNCTIONS

function swizzle.new(...)
	local arg = {...}
	if #arg > 1 or type( arg[1] ) ~= "table" then
		arg.set = function(...) return swizzle.set(arg,...) end
		return setmetatable( arg, swizzle.mt )
	else
		arg[1].set = function(...) return swizzle.set(arg,...) end
		return setmetatable( arg[1], swizzle.mt )
	end
end

function swizzle.set( t, ... )
	local arg = {...}
	local data = arg[1]
	if #arg > 1 or type( arg[1] ) ~= "table" then
		data = arg
	end
	
	for i = 1, math.max( #data, #t ) do
		t[i] = data[i]
	end
end



-- RETURN

return setmetatable( swizzle, {
	__call = function(_,...)
		return swizzle.new(...)
	end
} )