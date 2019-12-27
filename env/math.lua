--[[
	
	Math API
	Extends default Lua API with nice functions
	
]]--

local args = {...}
local computer = args[1]
local love = args[2]



-- LOVE2D FUNCTIONS

math.random = love.math.random
math.noise = love.math.noise

function math.hash( algorithm, data )
	expect( algorithm, "string", 1, "math.hash" )
	expect( data, "string", 2, "math.hash" )
	if algorithm ~= "md5" and algorithm ~= "sha256" and algorithm ~= "sha512" then
		error( "Invalid hash function", 2 )
	end
	
	return love.data.encode( "string", "hex", love.data.hash(algorithm, data) )
end

function math.compress( algorithm, data )
	expect( algorithm, "string", 1, "math.compress" )
	expect( data, "string", 2, "math.compress" )
	if algorithm ~= "lz4" and algorithm ~= "zlib" and algorithm ~= "gzip" and algorithm ~= "deflate" then
		error( "Invalid compression function", 2 )
	end
	
	return love.data.compress( "string", algorithm, data )
end

function math.decompress( algorithm, data )
	expect( algorithm, "string", 1, "math.decompress" )
	expect( data, "string", 2, "math.decompress" )
	if algorithm ~= "lz4" and algorithm ~= "zlib" and algorithm ~= "gzip" and algorithm ~= "deflate" then
		error( "Invalid compression function", 2 )
	end
	
	return love.data.decompress( "string", algorithm, data )
end



-- FUNCTIONS

function math.constrain( val, min, max )
	expect( val, "number", 1, "math.constrain" )
	expect( min, "number", 2, "math.constrain" )
	expect( max, "number", 3, "math.constrain" )
	
	return math.min( math.max(min, val), max )
end

function math.map( val, min1, max1, min2, max2 )
	expect( val, "number", 1, "math.map" )
	expect( min1, "number", 2, "math.map" )
	expect( max1, "number", 3, "math.map" )
	expect( min2, "number", 4, "math.map" )
	expect( max2, "number", 5, "math.map" )
	
	return min2 + (val-min1) / (max1-min1) * (max2-min2)
end

function math.lerp( a, b, t )
	expect( a, "number", 1, "math.lerp" )
	expect( b, "number", 2, "math.lerp" )
	expect( t, "number", 3, "math.lerp" )
	
	return a + t * (b-a)
end

function math.round(val) -- Round X.5 towards positive infinity
	expect( val, "number" )
	return val + 0.5 - (val+0.5) % 1 -- equal to math.floor(val+0.5), but faster
end

function math.roundSymm(val) -- Round X.5 away from 0 (roundSymm(-0.5) == -1)
	expect( val, "number" )
	return val>=0 and math.floor(val+0.5) or math.ceil(val-0.5)
end



-- RETURN

return math