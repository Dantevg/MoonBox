print(os.version)

while true do
	-- Draw
	screen.setColor("white")
	screen.write( string.sub(shell.dir, 2), {color = "yellow+1"} )
	screen.write( "> " )
	
	-- Get input and save shell.history
	local input = read(shell.history)
	if input ~= "" and input ~= shell.history[#shell.history] then
		table.insert( shell.history, input )
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
		local file = shell.find( path, "f" ) -- Only check for files
		if file then
			os.run( file, unpack(args) )
		elseif input ~= "" then
			shell.error("No such file")
		end
	end
end