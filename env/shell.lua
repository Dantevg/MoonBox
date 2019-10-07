local shell = {}

shell.path = {
	"",
	"/rom/programs/"
}
shell.extensions = {
	"",
	".lua"
}

shell.dir = "/disk1"

-- Type: "f", "d", "fd", "df" (file/dir, in specified order)
function shell.find( path, type )
	if not path then error( "Expected path [,type]", 2 ) end
	
	local found = {}
	table.insert( shell.path, shell.dir.."/" ) -- Add current dir to the list
	
	-- Find all matching files
	for _, prefix in ipairs(shell.path) do
		for _, suffix in ipairs(shell.extensions) do
			if disk.exists(prefix..path..suffix) then
				table.insert( found, prefix..path..suffix )
			end
		end
	end
	
	table.remove( shell.path, #shell.path ) -- Remove previously added current dir
	
	-- Return (type unspecified, any type)
	if not type then
		return found[1]
	end
	
	-- Return (type specified)
	for t in string.gmatch( type,"(.?)" ) do
		for i = 1, #found do
			if string.sub( disk.info(found[i]).type, 1, 1 ) == t then
				return disk.absolute(found[i])
			end
		end
	end
end

function shell.absolute(path)
	if not path or string.sub( path, 1, 1 ) == "/" then -- Absolute
		return disk.absolute(path)
	else -- Relative
		return disk.absolute( shell.dir.."/"..path )
	end
end

function shell.error( msg, level )
	screen.write( (shell.traceback and debug.traceback(msg, level) or msg) .. "\n",
		{color = "red+1", background = screen.background} )
end

return shell