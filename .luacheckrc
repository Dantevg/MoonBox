-- Prevent luacheck unused globals warning in this file (because of allow_defined_top)
-- luacheck: no global
ignore = {"611"}
allow_defined_top = true
globals = {
	"disk", "event", "mouse", "net", "os", "screen",
	"colours", "helium", "shell", "socket", "math", "swizzle",
	"read", "expect", "table.serialize", "log"
}
std = "+love"

files["rom/*.lua"].globals = {"settings", "computer"}
files["sandbox.lua"].globals = {"settings", "computer"}