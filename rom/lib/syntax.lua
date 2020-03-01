--[[
	
	Lua syntax matching
	
]]--

local syntax = {}

syntax.patterns = {}

local block = "%[(=*)%[.-%]%1%]"

syntax.patterns.comment = {
	"%-%-[^\n]*",                -- Single-line comment
	"%-%-"..block,               -- Multiline comment
	unfinished = {
		"%-%-%[(=*)%[.-%]$",       -- Unfinished multiline comment at end of chunk
	}
}

syntax.patterns.string = {
	'"[^\n"]-[^\\\n]"',          -- Single-line string with double quotes ("")
	"'[^\n']-[^\\\n]'",          -- Single-line string with single quotes ('')
	'""',                        -- Empty single-line string with double quotes ("")
	"''",                        -- Empty single-line string with single quites ('')
	block,                       -- Multiline string
	unfinished = {
		'".-$',                    -- Unfinished single-line string with "" at end of chunk
		"'.-$",                    -- Unfinished single-line string with '' at end of chunk
		"%[(=*)%[.-$",             -- Unfinished multiline string at end of chunk
	}
}

syntax.patterns.number = {
	"0x%x+",                     -- Hexadecimal number
	"%-?%d-%.?%d+[Ee][%+%-]?%d+",-- Number with exponent
	"%-?%d*%.?%d+",              -- Number with optional decimal point
}

syntax.patterns.punctuation = {"%p"}

syntax.patterns.keyword = {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "if",
	"in", "local", "nil", "not", "or",
	"repeat", "return", "then", "true", "until", "while",
	after = "%f[^%w_]",
}

syntax.patterns.word = {"[%a_][%w_]*"}

syntax.patterns.whitespace = {"%s+"}

syntax.patterns.other = {"."}  -- Match any character, to avoid getting stuck

syntax.patternsOrder = {
	"comment",
	"string",
	"number",
	"punctuation",
	"keyword",
	"word",
	"whitespace",
	"other",
}

function syntax.matchPattern( s, from, patterns )
	expect( s, "string", 1, "syntax.matchPattern" )
	expect( from, {"number", "nil"}, 2, "syntax.matchPattern" )
	expect( patterns, "table", 3, "syntax.matchPattern" )
	
	from = from or 1
	for _, pattern in ipairs(patterns) do
		local match = string.match( s, "^"..pattern..(patterns.after or ""), from )
		if match then return match end
	end
end

function syntax.match( s, from, unfinished )
	expect( s, "string", 1, "syntax.match" )
	expect( from, {"number", "nil"}, 2, "syntax.match" )
	expect( unfinished, {"boolean", "nil"}, 3, "syntax.match" )
	
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
	expect( s, "string", 1, "syntax.matchAll" )
	expect( from, {"number", "nil"}, 2, "syntax.matchAll" )
	
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
	expect( s, "string", 1, "syntax.gmatch" )
	expect( unfinished, {"boolean", "nil"}, 2, "syntax.gmatch" )
	
	local start = 1
	return function()
		local str, type, from, to = syntax.match( s, start, unfinished )
		if not str then return end
		start = start + to - from
		return str, type, from, to
	end
end

function syntax.autocomplete( input, env )
	expect( input, "string", 1, "syntax.autocomplete" )
	expect( env, {"table", "nil"}, 2, "syntax.autocomplete" )
	
	local path = {}
	
	-- Get path
	local str = input:match("%.$") or input:match("%."..syntax.patterns.word.."*$")
	while str do
		table.insert( path, 1, str:sub(2) )
		input = string.sub( input, 1, -#str-1 )
		str = input:match("%."..syntax.patterns.word.."*$") -- Match ".word"
	end
	local str = input:match(syntax.patterns.word.."*$") -- Match "word"
	if not str then return end
	table.insert( path, 1, str )
	
	-- Get variable
	local t = env or getfenv(2)
	for i = 1, #path-1 do
		if type(t) == "table" and t[ path[i] ] then
			t = t[ path[i] ]
		else
			return ""
		end
	end
	
	local name = path[#path]
	
	-- Find keyword
	if #path == 1 then
		for _, keyword in ipairs(syntax.patterns.keyword) do
			if keyword:sub( 1, #name )  == name then
				return keyword:sub( #name + 1 )
			end
		end
	end
	
	-- Find autocompletion
	while t do
		for k, v in pairs(t) do
			if type(k) == "string" and k:sub( 1, #name ) == name then
				local after = (type(v) == "table" and "." or (type(v) == "function" and "(" or ""))
				return k:sub( #name + 1 )..after
			end
		end
		t = getmetatable(t) and getmetatable(t).__index or nil
		if type(t) ~= "table" then return "" end
	end
	
	return ""
end

return syntax