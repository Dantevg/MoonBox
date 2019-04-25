local path = ...
if not path then
	error( "Expected path", 2 )
end

disk.mkdir( shell.absolute(path) )