local args = {...}
if #args < 2 then
	error( "Expected string, string", 2 )
end

local from = shell.absolute(args[1])
local toPath = shell.absolute(args[2])
local name

if not disk.exists(from) then
	error( "No such file", 2 )
elseif disk.info(from).type == "dir" then
	error( "Can only copy files", 2 )
elseif disk.exists(toPath) and disk.info(toPath).type == "file" then
	error( "File already exists", 2 )
elseif disk.exists(toPath) and disk.info(toPath).type == "dir" then
	name = disk.getFilename(fromPath)
elseif not disk.exists(toPath) then
	name = disk.getFilename(toPath)
	toPath = disk.getPath(toPath)
end

local file = disk.read(fromPath)
disk.write( toPath.."/"..name, file )