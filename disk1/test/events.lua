while true do
  local event, param = event.wait()
  print( event.." "..param )
end
