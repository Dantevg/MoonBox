--[[
	
	Markdown language syntax, for use with syntax lib
	
]]--

local mdsyntax = {}

mdsyntax.patterns = {}

mdsyntax.patterns.comment = {"<!%-%-.-%-%->"}

mdsyntax.patterns.heading = {"#+ [^\n]+"}

mdsyntax.patterns.hline = {
	"%-%-%-+$",
	"%*%*%*+$",
	"___+$",
}

mdsyntax.patterns.code = {
	"`[^`]+`",        -- Inline code
	"```.-```",       -- Code block
	unfinished = {
		"```.-$",
	}
}

mdsyntax.patterns.bold = {
	"%*[^%*]+%*",
	"_[^_]^"
}

mdsyntax.patterns.italic = {
	"%*%*[^%*]+%*%*",
	"__[^_]+__"
}

mdsyntax.patterns.word = {"[%w_]+"}

mdsyntax.patterns.whitespace = {"%s+"}

mdsyntax.patterns.other = {"."}  -- Match any character, to avoid getting stuck

mdsyntax.patternsOrder = {
	"comment",
	"heading",
	"hline",
	"code",
	"bold",
	"italic",
	"word",
	"whitespace",
	"other",
}

function mdsyntax.autocomplete()
	return ""
end

return setmetatable( require("syntax"), {__index = mdsyntax} )