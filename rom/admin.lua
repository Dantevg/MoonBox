-- Boot
screen.setFont("/rom/fonts/5x5_pxl_round.lua")

-- Menu
local menu = {
	main = {
		{name = "Settings", type = "menu", data = "settings"},
		{name = "Lua", type = "fn", data = "lua"},
		{name = "Shell", type = "fn", data = "shell"},
		selected = 1,
	},
	settings = {
		{name = "Back", type = "menu", data = "main"},
		{name = "Width", type = "input.number", source = "width", data = settings.width},
		{name = "Height", type = "input.number", source = "height", data = settings.height},
		{name = "Scale", type = "input.number", source = "scale", data = settings.scale},
		{name = "Fullscreen", type = "input.boolean", source = "fullscreen", data = settings.fullscreen},
		{name = "Border width", type = "input.number", source = "border", data = settings.border},
		{name = "Save", type = "fn", data = "saveSettings"},
		selected = 1
	},
}
local currentMenu = menu.main
local max = 16

-- Menu functions
local fn = {}

function fn.lua()
	screen.clear()
	screen.setPixelPos( 1, 1 )
	os.run("/rom/programs/lua.lua")
end

function fn.shell()
	screen.clear()
	screen.setPixelPos( 1, 1 )
	os.run("/rom/shell.lua")
end

function fn.saveSettings()
	-- Apply
	for i = 1, #menu.settings do
		if menu.settings[i].source then
			local setting = menu.settings[i]
			settings[setting.source] = setting.data
		end
	end
	
	-- Save
	love.filesystem.write( "/settings.lua", "return "..table.serialize(settings) )
	
	-- To main menu
	currentMenu = menu.main
end

-- Program functions
function draw()
	screen.clear()
	screen.setPixelPos( 1, 1 )
	max = 16
	for i = 1, #currentMenu do
		max = math.max( max, #currentMenu[i].name+2 )
	end
	local x = math.floor( (screen.charWidth-max)/2 )+1
	local y = math.floor( (screen.charHeight-#currentMenu)/2 ) + 1
	
	screen.setCharPos( x, y-2 )
	screen.write( "Lua sandbox menu" )
	for i = 1, #currentMenu do
		screen.setCharPos( x, y )
		if i == currentMenu.selected then
			screen.write( "> "..currentMenu[i].name )
		else
			screen.write( "  "..currentMenu[i].name )
		end
		if string.find( currentMenu[i].type, "input", 1, true ) then
			screen.setCharPos( x + max + 1, y )
			screen.write( tostring(currentMenu[i].data), {color="blue+1"} )
		end
		y = y+1
	end
end

-- Run
while true do
	draw()
	local event, key = event.wait()
	if event == "key" then
		if key == "up" then
			currentMenu.selected = (currentMenu.selected-2) % #currentMenu + 1
		elseif key == "down" then
			currentMenu.selected = (currentMenu.selected) % #currentMenu + 1
		elseif key == "enter" then
			local selected = currentMenu[currentMenu.selected]
			if selected.type == "fn" then
				if type( selected.data ) == "function" then
					selected.data()
				elseif type( selected.data ) == "string" then
					fn[selected.data]()
				end
			elseif selected.type == "menu" then
				currentMenu = menu[ selected.data ]
			elseif string.find( selected.type, "input", 1, true ) then
				if selected.type == "input.boolean" then
					selected.data = not selected.data
				else
					screen.setCharPos( math.floor( (screen.charWidth-max)/2 )+max+2, math.floor( (screen.charHeight-#currentMenu)/2 ) + currentMenu.selected )
					selected.data = read()
					if selected.type == "input.number" then
						selected.data = tonumber(selected.data)
					end
				end
			end
		end
	end
end