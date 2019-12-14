local running = true
local history = {}

local env = setmetatable( {exit = function() running = false end}, {__index = _G} )

local keywords = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["self"] = true,
	["then"] = true,
	["true"] = true,
	["until"]= true,
	["while"] = true,
}

local function autocomplete(input)
	local start = string.find( input, "[a-zA-Z0-9%.]+$" )
	input = string.sub( input, start or 1 )
	start = 1
	
	-- Traverse through environment tables to get to input destination
	local t = _G
	local dot = string.find( input, ".", start, true )
	while dot do
		local part = string.sub( input, start, dot-1 )
		if type( t[part] ) == "table" then
			t = t[part]
			start = dot + 1
			dot = string.find( input, ".", start, true )
		else
			return ""
		end
	end
	
	-- Find element in keywords
	local part = string.sub( input, start )
	if t == _G then
		for k, v in pairs(keywords) do
			if string.sub( k, 1, #part ) == part then
				return string.sub( k, #part+1 )
			end
		end
	end
	
	-- Find element in table
	for k, v in pairs(t) do
		if string.sub( k, 1, #part ) == part and type(k) == "string" then
			local suffix = type(v) == "table" and "." or (type(v) == "function" and "(" or "")
			return string.sub( k..suffix, #part+1 )
		end
	end
end

print( "Call exit() to exit", "yellow+1" )

while running do
	-- Draw
	screen.setColor("white")
	screen.write("lua> ")
	
	-- Get input and save history
	local input = read( history, false, autocomplete )
	print()
	
	local fn, err
	local fn1, err1 = load( input, "lua", "t", env ) -- Just execute
	local fn2, err2 = load( [[ -- Print values
			return (function(...)
				local a = {...}
				for i = 1, select("#",...) do a[i] = tostring(a[i]) end
				return unpack(a)
			end)(]]..input..");", "lua", "t", env )
	
	fn = fn2 or fn1
	err = err1
	
	if not fn then
		shell.error(err)
	else
		local result = {pcall(fn)}
		if not result[1] then
			shell.error(result[2])
		else
			for i = 2, #result do
				print( tostring(result[i]) )
			end
		end
	end
end