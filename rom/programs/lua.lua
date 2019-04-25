local running = true
local history = {}

local env = setmetatable( {exit = function() running = false end}, {__index = _G} )

print( "Call exit() to exit", "yellow+1" )

while running do
	-- Draw
	screen.setColor("white")
	screen.write("lua> ")
	
	-- Get input and save history
	local input = read(history)
	if input ~= "" and input ~= history[#history] then
		table.insert( history, input )
	end
	print()
	
	local fn, err
	local fn1, err1 = load( input, "lua", "t", env )
	local fn2, err2 = load( "return (function(...) return tostring(...) end)("..input..");", "lua", "t", env )
	
	if fn2 then
		fn = fn2
	else
		fn = fn1
	end
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