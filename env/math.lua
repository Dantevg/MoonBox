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



-- FUNCTIONS

function math.constrain( val, min, max )
	return math.min( math.max(min, val), max )
end

function math.map( val, min1, max1, min2, max2 )
	return min3 + (val-min1) / (max1-min1) * (max2-min2)
end

function math.lerp( a, b, t )
	return a + t * (b-a)
end

function math.round(val) -- Round X.5 towards positive infinity
	return val + 0.5 - (val+0.5) % 1 -- equal to math.floor(val+0.5), but faster
end

function math.roundSymm(val) -- Round X.5 away from 0 (roundSymm(-0.5) == -1)
	return val>=0 and math.floor(val+0.5) or math.ceil(val-0.5)
end



-- RETURN

return math