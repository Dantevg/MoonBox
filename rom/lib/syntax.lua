--[[
	
	Syntax matching
	
]]--

local syntax = {}

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

return syntax