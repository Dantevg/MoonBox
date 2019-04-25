local path = ...

if not path then
	error( "Expected path", 2 )
end

path = shell.absolute(path)
if not disk.exists(path) then
	error( "No such file", 2 )
elseif disk.info(path).type == "dir" and #disk.list(path) > 0 then
	error( "Can't remove filled directories", 2 )
end

disk.remove(path)