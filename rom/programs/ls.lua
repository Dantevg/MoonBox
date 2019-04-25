local args = {...}
local path = shell.dir
if args[1] then
	path = shell.absolute(args[1])
end

local folders = {}
local files = {}
local list = disk.list(path)

for i = 1, #list do
	if disk.info(path.."/"..list[i]).type == "dir" then
		table.insert( folders, list[i] )
	else
		table.insert( files, list[i] )
	end
end

screen.setColor("green+1")
for i = 1, #folders do
	print(folders[i])
end

for i = 1, #files do
	local ext = disk.getExtension( files[i] )
	local name = string.sub( files[i], 1, -1-(ext and #ext or 0) )
	screen.setColor("white")
	screen.write(name)
	screen.setColor("gray")
	print(ext)
end