local disk = {}
local args = {...}
local computer = args[1]
local love = args[2]

-- Path functions (drive-independent)

function disk.getParts(path)
	local tPath = {}
	for dir in string.gmatch( path, "[^/]+" ) do
		table.insert( tPath, dir )
	end
	return tPath
end

function disk.getPath(path)
	local parts = disk.getParts( disk.absolute(path) )
	table.remove( parts, #parts )
	return "/"..table.concat( parts, "/" )
end

function disk.getFilename(path)
	local parts = disk.getParts( disk.absolute(path) )
	return parts[ #parts ]
end

function disk.getExtension(path)
	local name = disk.getFilename(path)
	local ext = string.match( name, "(%.[^%.]+)$" )
	return ext
end

function disk.getDrive(path)
	local drive = disk.getParts( disk.absolute(path) )[1]
	return disk.drives[drive] and drive or "/" -- Return drive or "/" for main
end

function disk.absolute(path)
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

-- Viewing functions

function disk.defaults.list( path, showHidden )
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
	path = disk.absolute(path)
	if not love.filesystem.getInfo( path, "file" ) then
		error( "No such file", 2 )
	end
	
	return love.filesystem.read(path)
end

function disk.defaults.readLines(path)
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
	path = disk.absolute(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return {
			type = (info.type == "directory" and "dir" or "file"),
			size = info.size,
			modified = info.modtime,
		}
	else
		return false
	end
end

function disk.defaults.exists(path)
	return disk.info(path) and true or false
end

-- Modification functions

function disk.defaults.write( path, data )
	return love.filesystem.write( disk.absolute(path), data )
end

function disk.defaults.append( path, data )
	return love.filesystem.append( disk.absolute(path), data )
end

function disk.defaults.mkdir(path)
	path = disk.absolute(path)
	if love.filesystem.getInfo(path) then
		error( "Path already exists", 2 )
	end
	
	love.filesystem.createDirectory(path)
end

function disk.defaults.newFile(path)
	local file = love.filesystem.newFile( disk.absolute(path) )
	file:close()
end

function disk.defaults.remove(path)
	path = disk.absolute(path)
	if love.filesystem.getInfo( path, "directory" ) and #disk.list(path) > 0 then
		-- TODO: Recursively empty folder
		error( "Can only remove empty folders", 2 )
	end
	love.filesystem.remove(path)
end

-- Drives and functions

disk.drives = {}

disk.drives["/"] = setmetatable( {}, {__index = disk.defaults} )

disk.drives["/"].list = function()
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
	if disk.drives[path] then
		return {
			type = "drive",
			size = 0,
			modified = 0,
		}
	else
		return false
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

return disk