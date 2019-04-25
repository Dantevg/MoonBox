while true do
  local _, x, y, btn = event.wait("drag")
  if btn == 1 then
    screen.pixel( x, y, "orange" )
  elseif btn == 2 then
    screen.pixel( x, y, "blue" )
  end
end
