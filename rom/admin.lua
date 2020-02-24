-- Boot
screen.pos = require "swizzle" (1,1)
screen.colour = "white"
screen.background = "black"
screen.setFont("/rom/fonts/5x5_pxl_round.lua")

-- Menu
local menu = {
	main = {
		{name = "Moonbox menu", type = "text"},
		{name = "Press both [ctrl]s to switch", type = "text"},
		{name = "", type = "text"},
		{name = "Settings", type = "menu", data = "settings"},
		{name = "Lua", type = "fn", data = "lua"},
		{name = "Shell", type = "fn", data = "shell"},
		{name = "Screenshot", type = "fn", data = "screenshot"},
		{name = "Clipboard", type = "menu", data = "clipboard"},
		{name = "Reboot", type = "fn", data = "reboot"},
		selected = 1,
	},
	settings = {
		{name = "Moonbox menu", type = "text"},
		{name = "Press both [ctrl]s to switch", type = "text"},
		{name = "", type = "text"},
		{name = "Back", type = "menu", data = "main"},
		{name = "------", type = "text"},
		{name = "Width", type = "input.number", source = "width", data = settings.width},
		{name = "Height", type = "input.number", source = "height", data = settings.height},
		{name = "Scale", type = "input.number", source = "scale", data = settings.scale},
		{name = "Fullscreen", type = "input.boolean", source = "fullscreen", data = settings.fullscreen},
		{name = "Border width", type = "input.number", source = "border", data = settings.border},
		{name = "Screenshot scale", type = "input.number", source = "screenshotScale", data = settings.screenshotScale},
		{name = "Screenshot border", type = "input.boolean", source = "screenshotBorder", data = settings.screenshotBorder},
		{name = "------", type = "text"},
		{name = "Save", type = "fn", data = "saveSettings"},
		selected = 1,
	},
	clipboard = {
		{name = "Moonbox menu", type = "text"},
		{name = "Press both [ctrl]s to switch", type = "text"},
		{name = "", type = "text"},
		{name = "Back", type = "menu", data = "main"},
		{name = "------", type = "text"},
		{name = "Copy from sandbox", type = "fn", data = "copy"},
		{name = "Paste to sandbox", type = "fn", data = "paste"},
		selected = 1,
	},
}
local currentMenu = menu.main
local max = 16
local status

-- Menu functions
local fn = {}

function fn.lua()
	clearScreen()
	os.run("/rom/programs/lua.lua")
end

function fn.shell()
	clearScreen()
	os.run("/rom/shell.lua")
end

function fn.screenshot()
	if not disk.exists("/screenshots") or disk.info("/screenshots").type ~= "dir" then
		love.filesystem.createDirectory("/screenshots") -- Bypass read-only restriction applied for sandbox
	end
	local d = os.datetime()
	local filename = d.year.."_"..d.month.."_"..d.day.." "..d.hour.."_"..d.min.."_"..d.sec
	
	computer.screen.image = computer.screen.canvas:newImageData()
	computer.screen.imageFrame = computer.currentFrame
	local scale = settings.screenshotScale
	local border = settings.screenshotBorder and settings.border or 0
	local w = (computer.screen.image:getWidth() + 2*border) * math.ceil(scale)
	local h = (computer.screen.image:getHeight() + 2*border) * math.ceil(scale)
	
	local screenshot = love.image.newImageData( w, h )
	screenshot:mapPixel(function(x,y,r,g,b,a)
		if x/scale < border or x/scale >= w/scale - border
			or y/scale < border or y/scale >= h/scale - border then
			return 0, 0, 0, 1
		else
			local r, g, b, a = computer.screen.image:getPixel( x/scale - border, y/scale - border )
			return r, g, b, 1
		end
	end)
	
	screenshot:encode( "png", "/screenshots/"..filename..".png" )
	
	status = {
		text = "Screnshot taken",
		time = os.clock()
	}
	os.startTimer(2)
end

function fn.copy()
	love.system.setClipboardText(computer.clipboard)
	status = {
		text = "Copied",
		time = os.clock()
	}
	os.startTimer(2)
end

function fn.paste()
	computer.clipboard = love.system.getClipboardText()status = {
		text = "Pasted",
		time = os.clock()
	}
	os.startTimer(2)
end

function fn.reboot()
	os.reboot()
end

function fn.saveSettings()
	-- Apply
	local s = {}
	
	for k, v in pairs(settings) do
		s[k] = v
	end
	
	for i = 1, #menu.settings do
		if menu.settings[i].source then
			local setting = menu.settings[i]
			s[setting.source] = setting.data
		end
	end
	
	-- Save
	love.filesystem.write( "/settings.lua", "return "..table.serialize(s) )
	
	loadSettings()
	setWindow()
	love.resize( love.graphics.getWidth(), love.graphics.getHeight() )
	
	-- To main menu
	currentMenu = menu.main
end

-- Program functions
function clearScreen()
	screen.background = "black"
	screen.colour = "white"
	screen.clear()
	screen.setPixelPos( 1, 1 )
end

function draw()
	screen.background = "white"
	screen.colour = "gray-1"
	screen.clear("white")
	max = 0
	for i = 1, #currentMenu do
		if currentMenu[i].type == "text" then
			max = math.max( max, #currentMenu[i].name )
		else
			max = math.max( max, #currentMenu[i].name+2 )
		end
	end
	local x = math.floor( (screen.charWidth-max)/2 )+1
	local y = math.floor( (screen.charHeight-#currentMenu)/2 )
	
	for i = 1, #currentMenu do
		screen.setCharPos( x, y )
		if i == currentMenu.selected then
			screen.write( "> "..currentMenu[i].name )
		elseif currentMenu[i].type == "text" then
			screen.write( currentMenu[i].name )
		else
			screen.write( "  "..currentMenu[i].name )
		end
		if string.find( currentMenu[i].type, "input", 1, true ) then
			screen.setCharPos( x + max + 1, y )
			screen.write( tostring(currentMenu[i].data), {colour="blue"} )
		end
		y = y+1
	end
	
	if status and status.time+2 > os.clock() then
		local x = (screen.width - #status.text*(screen.font.width+1)) / 2
		screen.write( status.text, {x = x, y = screen.height - 20, colour = "blue"} )
	end
end

-- Run
while true do
	while currentMenu[currentMenu.selected].type == "text" do
		currentMenu.selected = (currentMenu.selected) % #currentMenu + 1
	end
	
	draw()
	local event, key = event.wait()
	
	if event == "key" then
		if key == "up" then
			repeat
				currentMenu.selected = (currentMenu.selected-2) % #currentMenu + 1
			until currentMenu[currentMenu.selected].type ~= "text"
		elseif key == "down" then
			repeat
				currentMenu.selected = (currentMenu.selected) % #currentMenu + 1
			until currentMenu[currentMenu.selected].type ~= "text"
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
					screen.setCharPos( math.floor( (screen.charWidth-max)/2 )+max+2, math.floor( (screen.charHeight-#currentMenu)/2 ) + currentMenu.selected - 1 )
					selected.data = read()
					if selected.type == "input.number" then
						selected.data = tonumber(selected.data)
					end
				end
			end
		end
	end
end