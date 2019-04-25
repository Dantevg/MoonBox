function f()
  print("hey")
end

local s = "print('hey!')"

f()
load(s)()
