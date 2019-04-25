local n = tostring(...)

function isPattern( s, pattern )
  return string.find( s, pattern.."0+"..pattern )
end

function find(n)
  local pattern = ""
  
  for i = 1, #n do
    local sub = string.sub(n,i,i)
    if sub == "0" and isPattern( n, pattern ) then
      if pattern ~= "" then
        return pattern
      end
    else
      pattern = pattern..sub
    end
  end
end

local p
local i = 1
while not p and i <= 10 do
  local s = tostring( 1 / tonumber("0."..string.rep(n,i)) )
  s = string.sub(s,1,1)..string.sub(s,3) -- Remove comma
  print( "Searching in "..s.." with "..string.rep(n,i) )
  p = find(s)
  i = i+1
end

if p then
  print(p)
end
