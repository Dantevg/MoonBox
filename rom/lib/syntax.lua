--[[
	
	Lua syntax matching
	
]]--

local syntax = {}

syntax.patterns = {}

local block = "%[(=*)%[.-%]%1%]"
local stringContent = "([^\n]*[\\\n]?)-[^\\]"

syntax.patterns.comment = {
	"^%-%-[^\n]*",            -- Single-line comment
	"^%-%-"..block,           -- Multiline comment
}

syntax.patterns.string = {
	'^"'..stringContent..'"', -- Single-line comment with double quotes("")
	"^'"..stringContent.."'", -- Single-line comment with single quotes ('')
	block,                    -- Multiline comment
}

syntax.patterns.number = {"^%d+"}

syntax.patterns.punctuation = {"^%p+"}

syntax.patterns.word = {"^[%a_][%w_]*"}

syntax.patterns.keyword = {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "if",
	"in", "local", "nil", "not", "or",
	"repeat", "return", "then", "true", "until", "while"
}

syntax.patterns.whitespace = {"^%s+"}

function syntax.match( s, from )
	from = from or 1
	for type, patterns in pairs(syntax.patterns) do
		for i, pattern in ipairs(patterns) do
			local match = string.match( s, pattern, from )
			if match then return match, type, from, from + #match end
		end
	end
end

function syntax.matchAll( s, from )
	from = from or 1
	local matches = {}
	for type, patterns in pairs(syntax.patterns) do
		for i, pattern in ipairs(patterns) do
			local match = string.match( s, pattern, from )
			table.insert( matches, {
				data = match,
				type = type,
				from = from,
				to = from + #match
			} )
		end
	end
	return matches
end

function syntax.gmatch(s)
	local start = 1
	return function()
		local str, type, from, to = syntax.match( s, start )
		if not str then return end
		start = start + to
		return str, type, from, to
	end
end

return syntax