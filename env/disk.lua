--[[
	
	Disk API
	Provides file reading/writing and path manipulation functions
	
]]--

local disk = {}
local args = {...}
local computer = args[1]
local love = args[2]



-- PATH MANIPULATION FUNCTIONS (drive-independent)

function disk.getParts(path)
	expect( path, "string" )
	
	local tPath = {}
	for dir in string.gmatch( path, "[^/]+" ) do
		table.insert( tPath, dir )
	end
	return tPath
end

function disk.getPath(path)
	expect( path, "string" )
	
	local parts = disk.getParts( disk.absolute(path) )
	table.remove( parts, #parts )
	return "/"..table.concat( parts, "/" )
end

function disk.getFilename(path)
	expect( path, "string" )
	
	local parts = disk.getParts( disk.absolute(path) )
	return parts[ #parts ] or ""
end

function disk.getExtension(path)
	expect( path, "string" )
	
	local name = disk.getFilename(path)
	local ext = string.match( name, "(%.[^%.]+)$" )
	return ext
end

function disk.getDrive(path)
	expect( path, "string" )
	
	local drive = disk.getParts( disk.absolute(path) )[1]
	return disk.drives[drive] and drive or "/" -- Return drive or "/" for main
end

function disk.absolute(path)
	expect( path, {"string", "nil"} )
	
	if not path then return "/" end
	local tPath = {}
	for dir in string.gmatch( path, "[^/]+" ) do
		if dir ~= ".." then
			table.insert( tPath, dir )
		else
			table.remove(tPath)
		end
	end
	
	return "/"..table.concat( tPath, "/" )
end

disk.defaults = {}



-- VIEWING FUNCTIONS

function disk.defaults.list( path, showHidden )
	expect( path, "string", 1, "disk.list" )
	expect( showHidden, {"boolean", "nil"}, 2, "disk.list" )
	
	path = disk.absolute(path)
	if not love.filesystem.getInfo( path, "directory" ) then
		error( "No such dir", 2 )
	end
	
	local list = love.filesystem.getDirectoryItems(path)
	
	-- Remove items starting with "."
	if not showHidden then
		for i = #list, 1, -1 do
			if string.sub( disk.getFilename(list[i]), 1, 1 ) == "." then
				table.remove( list, i )
			end
		end
	end
	
	return list
end

function disk.defaults.read(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	if not love.filesystem.getInfo( path, "file" ) then
		error( "No such file", 2 )
	end
	
	return love.filesystem.read(path)
end

function disk.defaults.readLines(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	if not love.filesystem.getInfo( path, "file" ) then
		error( "No such file", 2 )
	end
	
	local file = {}
	for line in love.filesystem.lines(path) do
		table.insert( file, line )
	end
	return file
end

function disk.defaults.info(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return {
			type = (info.type == "directory" and "dir" or "file"),
			size = info.size,
			modified = info.modtime,
		}
	else
		return {
			type = false,
			size = 0,
			modified = 0,
		}
	end
end

function disk.defaults.exists(path)
	expect( path, "string" )
	
	return disk.info(path).type and true or false
end



-- MODIFICATION FUNCTIONS

function disk.defaults.write( path, data )
	expect( path, "string", 1, "disk.write" )
	expect( data, {"string", "nil"}, 2, "disk.write" )
	
	return love.filesystem.write( disk.absolute(path), data )
end

function disk.defaults.append( path, data )
	expect( path, "string", 1, "disk.append" )
	expect( data, {"string", "nil"}, 2, "disk.append" )
	
	return love.filesystem.append( disk.absolute(path), data )
end

function disk.defaults.mkdir(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	if love.filesystem.getInfo(path) then
		error( "Path already exists", 2 )
	end
	
	love.filesystem.createDirectory(path)
end

function disk.defaults.newFile(path)
	expect( path, "string" )
	
	local file = love.filesystem.newFile( disk.absolute(path) )
	file:close()
end

function disk.defaults.remove(path)
	expect( path, "string" )
	
	path = disk.absolute(path)
	if love.filesystem.getInfo( path, "directory" ) and #disk.list(path) > 0 then
		-- TODO: Recursively empty folder
		error( "Can only remove empty folders", 2 )
	end
	love.filesystem.remove(path)
end



-- DRIVES AND FUNCTIONS

disk.drives = {}

disk.drives["/"] = setmetatable( {}, {__index = disk.defaults} )

disk.drives["/"].list = function(path)
	expect( path, "string", 1, "disk.list" )
	
	local drive = disk.getParts( disk.absolute(path) )[1] or "/"
	if not disk.drives[drive] then
		error( "No such drive", 2 )
	end
	local drives = disk.getDrives()
	for i = 1, #drives do
		if drives[i] == "/" then
			table.remove( drives, i )
			break
		end
	end
	return drives
end
disk.drives["/"].info = function(path)
	expect( path, "string" )
	
	if disk.drives[path] then
		return {
			type = "drive",
			size = 0,
			modified = 0,
		}
	else
		return {
			type = false,
			size = 0,
			modified = 0,
		}
	end
end
disk.drives["/"].read = function()
	error( "No such file", 2 )
end
disk.drives["/"].readLines = function()
	error( "No such file", 2 )
end
disk.drives["/"].write = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["/"].append = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["/"].mkdir = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["/"].newFile = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["/"].remove = function()
	error( "Attempt to modify read-only location", 2 )
end

disk.drives["disk1"] = setmetatable( {}, {__index = disk.defaults} )

disk.drives["rom"] = setmetatable( {}, {__index = disk.defaults} )

disk.drives["rom"].write = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["rom"].append = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["rom"].mkdir = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["rom"].newFile = function()
	error( "Attempt to modify read-only location", 2 )
end
disk.drives["rom"].remove = function()
	error( "Attempt to modify read-only location", 2 )
end

function disk.getDrives()
	local d = {}
	for k in pairs(disk.drives) do
		table.insert( d, k )
	end
	return d
end

setmetatable(disk, {
	__index = function( t, k )
		if not disk.defaults[k] then
			return
		end
		return function( path, ... )
			expect( path, {"string", "nil"} )
					
			path = disk.absolute(path)
			local drive = disk.getDrive(path)
			
			if drive and disk.drives[drive] then
				return disk.drives[drive][k]( path, ... )
			else
				return disk.defaults[k]( path, ... )
			end
		end
	end
})



-- RETURN

return disk