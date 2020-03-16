local syntax = require("syntax")( require("luasyntax") )

local args = {...}
local running = true
local history = {}

local mt = {__index = _G}
if args[1] == "-G" or args[1] == "--global" then
	mt = {__index = _G, __newindex = _G}
end
local env = setmetatable( {exit = function() running = false end}, mt )

print( "Call exit() to exit", "yellow+1" )

while running do
	-- Draw
	screen.setColour("white")
	screen.write("lua> ")
	
	-- Get input and save history
	local input = read( history, false, function(input) return syntax.autocomplete(input,env) end )
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