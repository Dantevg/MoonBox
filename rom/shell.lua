local history = {"ovos/main.lua"} -- TODO: empty

print(os.version)

while true do
	-- Draw
	screen.setColor("white")
	local dir = #shell.dir > 1 and string.sub(shell.dir, 2) or shell.dir
	screen.write( dir, {color = "yellow+1"} )
	screen.write( "> " )
	
	-- Get input and save history
	local input = read(history)
	if input ~= "" and input ~= history[#history] then
		table.insert( history, input )
	end
	print()
	
	-- Get program params
	local path = string.match( input, "(%S+)" )
	local args = {}
	for arg in string.gmatch( input, "(%S+)" ) do
		table.insert( args, arg )
	end
	args[0] = table.remove( args, 1 )
	
	-- Run file
	if path then
		if path == "exit" then break end
		local file = shell.find( path, "f" ) -- Only check for files
		if file then
			os.run( file, unpack(args) )
		elseif input ~= "" then
			shell.error("No such file")
		end
	end
end