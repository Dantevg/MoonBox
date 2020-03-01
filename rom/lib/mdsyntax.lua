--[[
	
	Markdown language syntax, for use with syntax lib
	
]]--

local mdsyntax = {}

mdsyntax.patterns = {}

mdsyntax.patterns.heading = {"#- [^\n]+"}

mdsyntax.patterns.comment = {"<!%-%-.-%-%->"}

mdsyntax.patterns.word = {"[%a_][%w_]*"}

mdsyntax.patterns.whitespace = {"%s+"}

mdsyntax.patterns.other = {"."}  -- Match any character, to avoid getting stuck

mdsyntax.patternsOrder = {
	"heading",
	"comment",
	"word",
	"whitespace",
	"other",
}

function mdsyntax.autocomplete()
	return ""
end

return mdsyntax