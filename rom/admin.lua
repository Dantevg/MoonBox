-- Boot
screen.setFont("/rom/fonts/5x5_pxl_round.lua")

-- Menu functions
function settings()
	
end

function shell()
	screen.clear()
	screen.setPixelPos( 1, 1 )
	os.run("/rom/shell.lua")
end

-- Menu
local menu = {
	{name = "Settings", type = "fn", data = settings},
	{name = "Shell", type = "fn", data = shell},
	selected = 1,
}

-- Program functions
function draw()
	screen.clear()
	screen.setPixelPos( 1, 1 )
	for i = 1, #menu do
		if i == menu.selected then
			print( "> "..menu[i].name )
		else
			print( "  "..menu[i].name )
		end
	end
end

while true do
	draw()
	local event, key = event.wait("key")
	if key == "up" then
		menu.selected = (menu.selected-2) % #menu + 1
	elseif key == "down" then
		menu.selected = (menu.selected) % #menu + 1
	elseif key == "enter" then
		if menu[menu.selected].type == "fn" then
			menu[menu.selected].data()
		end
	end
end