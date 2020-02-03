local args = {...}
local path = shell.dir
local showHidden = false
if args[1] then
	path = shell.absolute(args[1])
end

if not disk.exists(path) then error( "No such path", 0 ) end

for i = 1, #args do
	if args[i] == "-h" then
		showHidden = true
		break
	end
end

local folders = {}
local files = {}
local list = disk.list( path, showHidden )

for i = 1, #list do
	if disk.info(path.."/"..list[i]).type == "dir" then
		table.insert( folders, list[i] )
	else
		table.insert( files, list[i] )
	end
end

if #folders >= 1 then
	screen.setColour("green+1")
	screen.tabulate(folders)
end

if #files >= 1 then
	screen.tabulate( files, nil, false, function(file)
		local ext = disk.getExtension(file)
		local name = string.sub( file, 1, -1-(ext and #ext or 0) )
		screen.setColour("white")
		screen.write(name)
		screen.setColour("gray")
		screen.write(ext)
	end )
end