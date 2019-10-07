-- CONSTANTS
local args = {...}
local sizes = {" B", " kB", " MB", " GB"}

-- GATHER INFO
local palette = colors.all(false)
local allColors = colors.all(true)
local colorBits = math.ceil( ({math.frexp(#allColors)})[2] )

local drives = {}

local function count( drive, path )
	local size = 0
	local files = disk.list(path)
	for i = 1, #files do
		local info = disk.info( path.."/"..files[i] )
		if info and info.type == "file" then
			size = size + info.size
		elseif info then
			size = size + count( drive, path.."/"..files[i] )
		end
	end
	return size
end
for drive in pairs(disk.drives) do
	if drive ~= "/" then
		drives[drive] = count( drive, disk.absolute(drive) )
		local magnitude = 1
		while drives[drive] > 1000 do
			drives[drive] = drives[drive] / 1000
			magnitude = magnitude + 1
		end
		drives[drive] = math.floor(drives[drive]*10)/10 .. sizes[magnitude]
	end
end

local elevateSuccess, host, cores
if args[1] == "extended" then
	elevateSuccess, host, cores = os.elevate(
		"return love.system.getOS(), love.system.getProcessorCount()" )
end



-- DISPLAY INFO
screen.clear("cyan-3")
screen.pos.x, screen.pos.y = 1, 1

print()
screen.write( " "..string.upper(os.version).."\n", {color="orange+3"} )
print()
screen.write( " CPU: ", {color="cyan-1"} )
screen.write( _VERSION.."\n" )
screen.write( " GPU: ", {color="cyan-1", x=1} )
screen.write( screen.width.."x"..screen.height.."\n" )
screen.write( colorBits.."-bit color, "..#palette.." color palette\n" )
screen.write( "("..#allColors.." total colors)\n" )
screen.write( os.FPS.." FPS\n" )
screen.write( " FONT: ", {color="cyan-1", x=1} )
screen.write( screen.font.name.."\n" )
screen.write( screen.font.monospace and "monospace, " or "adaptive, " )
screen.write( screen.font.width.."x"..screen.font.height.."\n" )
screen.write( " UPTIME: ", {color="cyan-1", x=1} )
screen.write( math.floor(os.clock()).."s\n" )
if elevateSuccess then
	screen.write( " HOST: ", {color="cyan-1", x=1} )
	screen.write( host..", "..cores.." cores\n" )
end
print()
for drive, size in pairs(drives) do
	screen.write( " Drive "..drive..": ", {color="cyan-1", x=1} )
	screen.write( size.."\n" )
end
print()
screen.write( " ", 1 )

for i = 1, #palette do
	screen.rect( screen.pos.x + (i-1)*10, screen.pos.y, 10, 10, palette[i] )
end

screen.write( "Press any key to continue", {color="cyan-1", y = screen.height - 10} )
screen.write( "(C) RedPolygon", {color="cyan-2", x = screen.width - 15*(screen.font.width+1), y = screen.height - 10} )

event.wait("char")
os.sleep()
screen.clear()
screen.pos.x, screen.pos.y = 1, 1