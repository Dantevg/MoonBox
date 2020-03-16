local what = ...
if what and disk.exists("/docs/"..what..".md") then
	os.run( "/rom/programs/view.lua", "/docs/"..what..".md", "--highlight" )
else
	print( "Topics:", "green+1" )
	local files = disk.list("/docs")
	for i = 1, #files do
		local path = "/docs/"..files[i]
		if disk.info(path).type == "file" and disk.getFilename(path) ~= "README.md" then
			print( "- "..string.sub( files[i], 1, -#disk.getExtension(path)-1 ) )
		end
	end
end