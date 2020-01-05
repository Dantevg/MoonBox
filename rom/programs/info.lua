local path = ...
if not path then error( "Expected path", 2 ) end
path = shell.absolute(path)
if not disk.exists(path) then error( "No such path", 2 ) end

local suffixes = {"B", "kB", "MB", "GB"}

local info = disk.info(path)
local size = info.size
local sizeSuffix = 1
while size > 1000 and sizeSuffix < #suffixes do
	size = size / 1000
	sizeSuffix = sizeSuffix+1
end

print( "Type: "..info.type )
print( "Size: "..string.format( "%.2f ", size )..suffixes[sizeSuffix] )
print( "Timestamp: "..info.modified )