while true do
  local _, x, y = event.wait("mouse")
  screen.write( mouse.x..", "..mouse.y )
  print( "  "..x..", "..y )
  
  screen.pixel( x, y )
  -- if mouse.drag then
  --   print( mouse.drag.x..", "..mouse.drag.y )
  -- end
end
