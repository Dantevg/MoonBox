--[[
	
	Lua language syntax, for use with syntax lib
	
]]--

local luasyntax = {}

luasyntax.patterns = {}

local block = "%[(=*)%[.-%]%1%]"

luasyntax.patterns.comment = {
	"%-%-[^\n]*",                -- Single-line comment
	"%-%-"..block,               -- Multiline comment
	unfinished = {
		"%-%-%[(=*)%[.-%]$",       -- Unfinished multiline comment at end of chunk
	}
}

luasyntax.patterns.string = {
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

luasyntax.patterns.number = {
	"0x%x+",                     -- Hexadecimal number
	"%-?%d-%.?%d+[Ee][%+%-]?%d+",-- Number with exponent
	"%-?%d*%.?%d+",              -- Number with optional decimal point
}

luasyntax.patterns.punctuation = {"%p"}

luasyntax.patterns.keyword = {
	"and", "break", "do", "else", "elseif",
	"end", "false", "for", "function", "if",
	"in", "local", "nil", "not", "or",
	"repeat", "return", "then", "true", "until", "while",
	after = "%f[^%w_]",
}

luasyntax.patterns.word = {"[%a_][%w_]*"}

luasyntax.patterns.whitespace = {"%s+"}

luasyntax.patterns.other = {"."}  -- Match any character, to avoid getting stuck

luasyntax.patternsOrder = {
	"comment",
	"string",
	"number",
	"punctuation",
	"keyword",
	"word",
	"whitespace",
	"other",
}

function luasyntax.autocomplete( input, env )
	expect( input, "string", 1, "luasyntax.autocomplete" )
	expect( env, {"table", "nil"}, 2, "luasyntax.autocomplete" )
	
	local path = {}
	
	-- Get path
	local str = input:match("%.$") or input:match("%."..luasyntax.patterns.word[1].."$")
	while str do
		table.insert( path, 1, str:sub(2) )
		input = string.sub( input, 1, -#str-1 )
		str = input:match("%."..luasyntax.patterns.word[1].."$") -- Match ".word"
	end
	local str = input:match(luasyntax.patterns.word[1].."$") -- Match "word"
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
		for _, keyword in ipairs(luasyntax.patterns.keyword) do
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

return luasyntax