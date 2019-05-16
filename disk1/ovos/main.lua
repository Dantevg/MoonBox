--[[
	
	OVOS Oxygen Visual Operating System
	by RedPolygon
	
]]--

-- Variables
local carbon = require "carbon"
local ovos = {}

local windowPos = 20

ovos.GUI = carbon()
ovos.UI = {
	desktop = {},
	windows = {}
}
ovos.focus = false

ovos.running = true

-- Functions
function ovos.main()
	ovos.GUI:draw()
	ovos.GUI:event( event.wait() )
end

function ovos.focus(window)
	for k, w in ipairs(ovos.UI.windows) do
		w.focus = false
	end
	
	if window then
		window.focus = true
		-- window:toFront()
	end
end

function ovos.addWindow( x, y, program )
	table.insert( ovos.UI.windows, ovos.GUI:addChild("window", {
		x = x or windowPos,
		y = y or windowPos,
		w = 250,
		h = 150,
		title = {
			bg = "blue",
			color = "white"
		}
	}) )
	
	if not x then
		windowPos = windowPos+20
	end
	
	local w = ovos.UI.windows[#ovos.UI.windows]
	
	ovos.focus(w)
	
	w:addChild( "program", {
		path = program or "/rom/shell.lua",
		y = screen.font.height + 2,
		h = w.h - screen.font.height - 2
	} )
end

-- Run
carbon.loadModules("/disk1/data/Carbon.lua") -- Load default modules
carbon.loadModules("/disk1/ovos/modules.lua") -- Load OVOS modules

ovos.UI.desktop = ovos.GUI:addChild( "box", {
	x = 0,
	y = 0,
	w = screen.width,
	h = screen.height,
	color = "white"
})

ovos.UI.taskbar = ovos.GUI:addChild( "box", {
	x = 0,
	y = 0,
	w = screen.width,
	h = screen.font.height+2,
	color = "red"
})

ovos.UI.taskbar:addChild( "text", {
	id = "menu",
	x = 1,
	y = 1,
	text = "#",
	color = "white"
})

ovos.UI.taskbar:find("menu").mouse = function( self, x, y )
	if self:pointInside( x, y ) then
		self.bg = "red-1"
		ovos.addWindow()
	end
end
ovos.UI.taskbar:find("menu").mouseUp = function( self, x, y )
	self.bg = nil
end

ovos.addWindow()

function ovos.GUI:resize( w, h )
	ovos.UI.desktop.w, ovos.UI.desktop.h = w, h
	ovos.UI.taskbar.w = w
	ovos.UI.desktop:update()
	screen.width, screen.height = w, h
end

while ovos.running do
	ovos.main()
end