local args = {...}
local path = shell.dir
local showHidden = false
if args[1] then
	path = shell.absolute(args[1])
end

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

-- screen.setColor("green+1")
-- for i = 1, #folders do
-- 	print(folders[i])
-- end
if #folders >= 1 then
	screen.write( table.concat(folders, " ") .. "\n", {overflow = "wrap", color = "green+1"} )
end

for i = 1, #files do
	local ext = disk.getExtension( files[i] )
	local name = string.sub( files[i], 1, -1-(ext and #ext or 0) )
	screen.setColor("white")
	screen.write(name)
	screen.setColor("gray")
	print(ext)
end