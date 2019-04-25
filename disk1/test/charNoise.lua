local w, h = 7, 7
local colors = {}

for k, v in pairs(screen.colors) do
  table.insert( colors, k )
end

function randomChar()
  return string.char( math.random(32,126) )
end

function randomColor()
  return colors[math.random(#colors)]
end

function randomPrint()
  local x = math.random( 1, screen.width/w )
  local y = math.random( 1, screen.height/h )
  
  local char = randomChar()
  local c = randomColor()
  
  screen.setPixelPos( (x-1)*w + 1, (y-1)*h + 1 )
  
  screen.write( char,
    {color = c, background = "black"} )
end

screen.clear("black")
while true do
  for i = 1, 100 do
    randomPrint()
  end
  os.sleep()
end
