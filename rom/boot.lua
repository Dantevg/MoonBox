-- Boot
screen.pos = swizzle(1,1)
screen.colour = "white"
screen.background = "black"
screen.setFont("/rom/fonts/5x5_pxl_round.lua")

-- Startup program
if disk.exists("/disk1/startup.lua") then
	os.run("/disk1/startup.lua")
end

os.run("/rom/shell.lua")