--[[
	
	Shell lib
	Helper for shell program, provides smarter path functions
	
]]--

local shell = {}



-- VARIABLES / CONSTANTS

shell.path = {
	"",
	"/rom/programs/"
}
shell.extensions = {
	"",
	".lua"
}

shell.dir = "/disk1"



-- SMARTER PATH FUNCTIONS

-- Type: "f", "d", "fd", "df" (file/dir, in specified order)
function shell.find( path, type )
	expect( path, "string", 1, "shell.find" )
	expect( type, {"string", "nil"}, 2, "shell.find" )
	
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
	expect( path, {"string", "nil"} )
	
	if not path or string.sub( path, 1, 1 ) == "/" then -- Absolute
		return disk.absolute(path)
	else -- Relative
		return disk.absolute( shell.dir.."/"..path )
	end
end

function shell.autocomplete(input)
	expect( input, "string" )
	
	local path = disk.getPath( shell.absolute(input) )
	local search = disk.getFilename( shell.absolute(input) )
	if string.sub( input, -1 ) == "/" then -- Peek into dir
		path = path.."/"..search
		search = ""
	end
	
	if not disk.exists(path) or disk.info(path).type == "file" then
		return false
	end
	
	local files = disk.list(path)
	for k, file in ipairs(files) do
		if string.sub( file, 1, #search ) == search then
			local isFile = (disk.info( path.."/"..file ).type == "file")
			return string.sub( isFile and file or file.."/", #search+1, -1 )
		end
	end
end

function shell.getRunningProgram()
	local info = debug.getinfo(2)
	return info and info.short_src
end



-- OTHER FUNCTIONS

function shell.error( msg, level, file )
	expect( msg, {"string", "nil"}, 1, "shell.error" )
	expect( level, {"number", "nil"}, 2, "shell.error" )
	expect( file, {"boolean", "nil"}, 3, "shell.error" )
	msg = msg or ""
	level = level or 1
	
	if file then
		msg = string.gsub( msg, "^([^:]+)", disk.getFilename ) -- Only display filename, don't display full path
	end
	
	screen.write( (shell.traceback and debug.traceback(msg, level+1) or msg) .. "\n",
		{colour = "red+1", background = screen.background} )
	screen.pos.x = 1
end



-- RETURN

return shell