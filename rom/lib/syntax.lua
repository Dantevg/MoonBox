--[[
	
	Lua syntax matching
	
]]--

local syntax = {}

syntax.patterns = {}

local block = "%[(=*)%[.-%]%1%]"
local stringContent = "[^\n]-[^\\]"

syntax.patterns.comment = {
	"%-%-[^\n]*",            -- Single-line comment
	"%-%-"..block,           -- Multiline comment
	unfinished = {
		"%-%-%[(=*)%[.-%]$"    -- Unfinished multiline comment at end of chunk
	}
}

syntax.patterns.string = {
	'"'..stringContent..'"',     -- Single-line string with double quotes ("")
	"'"..stringContent.."'",     -- Single-line string with single quotes ('')
	block,                       -- Multiline string
	unfinished = {
		'".-$',                    -- Unfinished single-line string with "" at end of chunk
		"'.-$",                    -- Unfinished single-line string with '' at end of chunk
		"%[(=*)%[.-$"              -- Unfinished multiline string at end of chunk
	}
}

syntax.patterns.number = {
	"0x%x+",                     -- Hexadecimal number
	"%-?%d-.?%d+[Ee][%+%-]?%d+", -- Number with exponent
	"%-?%d*%.?%d+",              -- Number with optional decimal point
}

syntax.patterns.punctuation = {"%p+"}

syntax.patterns.keyword = {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "if",
	"in", "local", "nil", "not", "or",
	"repeat", "return", "then", "true", "until", "while"
}

syntax.patterns.word = {"[%a_][%w_]*"}

syntax.patterns.whitespace = {"%s+"}

syntax.patternsOrder = {
	"comment",
	"string",
	"number",
	"punctuation",
	"keyword",
	"word",
	"whitespace",
}

function syntax.matchPattern( s, from, patterns )
	from = from or 1
	for _, pattern in ipairs(patterns) do
		local match = string.match( s, "^"..pattern, from )
		if match then return match end
	end
end

function syntax.match( s, from, unfinished )
	from = from or 1
	for _, type in ipairs(syntax.patternsOrder) do
		local match = syntax.matchPattern( s, from, syntax.patterns[type] )
		local complete = true
		if not match and unfinished and syntax.patterns[type].unfinished then
			complete = false
			match = syntax.matchPattern( s, from, syntax.patterns[type].unfinished )
		end
		if match then return match, type, from, from + #match, complete end
	end
end

function syntax.matchAll( s, from )
	from = from or 1
	local matches = {}
	for _, type in ipairs(syntax.patternsOrder) do
		local match = syntax.matchPattern( s, from, syntax.patterns[type] )
		local unfinished = false
		if not match and syntax.patterns[type].unfinished then
			match = syntax.matchPattern( s, from, syntax.patterns[type].unfinished )
			unfinished = true
		end
		if match then
			table.insert( matches, {
				match = match,
				type = type,
				from = from,
				to = from + #match,
				complete = not unfinished,
			})
		end
	end
	return matches
end

function syntax.gmatch( s, unfinished )
	local start = 1
	return function()
		local str, type, from, to = syntax.match( s, start, unfinished )
		if not str then return end
		start = start + to - from
		return str, type, from, to
	end
end

return syntax