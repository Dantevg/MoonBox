local args = {...}
if not args[1] then
	error("Expected path")
	return
end

local path = shell.absolute(args[1])

if disk.exists(path) and (disk.info(path).type == "dir" or disk.info(path).type == "drive") then
	shell.dir = path
else
	error( "No such path", 2 )
end