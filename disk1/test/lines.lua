local lines = {}

local i = 1

while true do
  if i % 10 == 0 then
    table.insert( lines, {
      x = 1,
      y = math.random( 1, screen.height),
      b = 3
    } )
  end
  
  for k, line in pairs(lines) do
    for i = line.x, 1, -1 do
      local c = math.max( line.b-i+1, -2 )
      screen.setColor("gray"..c)
      screen.pixel( line.x - i + 1, line.y )
    end
    line.x = line.x+1
  end
  
  i = i+1
  os.sleep()
end
