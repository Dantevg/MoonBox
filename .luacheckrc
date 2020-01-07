-- Prevent luacheck unused globals warning in this file (because of allow_defined_top)
-- luacheck: no global
ignore = {"611"}
allow_defined_top = true
globals = {
	"disk", "event", "mouse", "net", "os", "screen",
	"colors", "helium", "shell", "socket", "math",
	"read", "expect", "table.serialize"
}
std = "+love"

files["rom/*.lua"].globals = {"settings", "computer"}