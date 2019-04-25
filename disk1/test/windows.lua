local outer = screen.newWindow( 10, 10, 200, 150 )
local prev1 = getmetatable(screen.window).__index

screen.setWindow(outer)
  screen.rect(0,0,10,10,"red")
  
  local inner = screen.newWindow( 10, 10, 100, 50 )
  local prev2 = getmetatable(screen.window).__index
  
  screen.setWindow(inner)
    screen.rect(0,0,10,10,"purple")
    
    screen.setWindow(prev2)
  screen.drawWindow(inner)
  
  screen.setWindow(prev1)
screen.drawWindow(outer)
