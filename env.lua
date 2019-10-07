--[[
	
	Globals
	
]]--

local args = {...}
local computer = args[1]
local love = args[2]
local env = setmetatable( {}, {__index = computer.env} )



-- FILE / INPUT READING

function env.read(history)
	history = history or {}
	table.insert( history, "" )
	local selected = #history
	local cursor = true
	local x, y = env.screen.pos.x, env.screen.pos.y
	local pos = 1
	local length = 0
	local timer = env.os.startTimer(0.5)
	
	local function draw()
		env.screen.write( string.rep(" ", length+1),
			{x = x, y = y, background = env.screen.background} )
		env.screen.write(
			string.sub( history[selected], 1, pos-1 )
			..( cursor and "_" or string.sub(history[selected], pos, pos) )
			..string.sub( history[selected], pos+1, -1 )
			.." ", x, y )
	end
	
	local function getWords()
		local words = {}
		local length = 1
		for word, separator in string.gmatch( history[selected], "(%w*)(%W*)" ) do
			table.insert( words, { type="word", data=word, s=length, e=length+#word-1 } )
			table.insert( words, { type="separator", data=separator, s=length+#word, e=length+#word+#separator-1 } )
			length = length + #word + #separator
		end
		return words
	end
	
	while true do
		draw()
		length = #history[selected]
		
		-- Update input
		local event, key = env.event.wait()
		if event == "char" then
			history[#history] = string.sub( history[selected], 1, pos-1 )..key..string.sub( history[selected], pos, -1 )
			selected = #history
			pos = pos+1
		elseif event == "key" then
			if key == "enter" then
				cursor = false
				draw()
				if selected == #history then
					return table.remove( history, #history )
				else
					table.remove( history, #history )
					return history[selected]
				end
			elseif key == "backspace" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos > words[i].s and pos <= words[i].e+1 then
							local l = #words[i].data
							words[i].data = string.sub( words[i].data, pos - words[i].s + 1 )
							pos = math.max( 1, pos-(l-#words[i].data) )
							break
						end
					end
					history[selected] = ""
					for i = 1, #words do
						history[selected] = history[selected] .. words[i].data
					end
				else
					history[selected] = string.sub( history[selected], 1, math.max(0,pos-2) )
						..string.sub( history[selected], pos, -1 )
						pos = math.max( 1, pos-1 )
				end
			elseif key == "delete" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos > words[i].s and pos <= words[i].e+1 then
							words[i].data = string.sub( words[i].data, 1, pos - words[i].s )
							break
						end
					end
					history[selected] = ""
					for i = 1, #words do
						history[selected] = history[selected] .. words[i].data
					end
				else
					history[selected] = string.sub( history[selected], 1, pos-1 )
						..string.sub( history[selected], pos+1, -1 )
				end
			elseif key == "up" then
				selected = math.max( 1, selected-1 )
				pos = #history[selected]+1
			elseif key == "down" then
				selected = math.min( selected+1, #history )
				pos = #history[selected]+1
			elseif key == "left" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos > words[i].s and pos <= words[i].e+1 then
							pos = (words[i].type == "word") and (words[i-1] and words[i-1].s) or words[i].s
							break
						end
					end
				else
					pos = math.max( 1, pos-1 )
				end
			elseif key == "right" then
				if env.event.keyDown("ctrl") then
					local words = getWords()
					for i = 1, #words do
						if pos >= words[i].s and pos <= words[i].e then
							pos = (words[i].type == "separator") and words[i+1].e+1 or words[i].e+1
							break
						end
					end
				else
					pos = math.min( pos+1, #history[selected]+1 )
				end
			elseif key == "home" then
				pos = 1
			elseif key == "end" then
				pos = #history[selected]+1
			end
		elseif event == "timer" and key == timer then
			timer = env.os.startTimer(0.5)
			cursor = not cursor
		end
	end
end

function env.tostring(...)
	if select( "#", ... ) == 0 then -- No argument received (not even a nil value)
		return nil
	else
		return tostring(...)
	end
end

function env.load( fn, name, mode, e )
	return load( fn, name, mode or "bt", e or computer.env )
end

function env.loadfile(path)
	return setfenv( love.filesystem.load(env.disk.absolute(path)), computer.env )
end

function env.loadstring( str, name, mode, e )
	return load( str, name, mode or "bt", e or computer.env )
end

function env.require(path)
	local before = {"/", "/disk1/", "/disk1/lib/"}
	local after = {"", ".lua"}
	
	for i = 1, #before do
		for j = 1, #after do
			
			local p = env.disk.absolute( before[i]..env.disk.absolute(path)..after[j] )
			if env.disk.exists(p) then
				local file = env.disk.read(p)
				local fn, err = load( file, "="..env.disk.getFilename(p), "bt", computer.env )
				if not fn then
					error( err, 2 )
				end
				return fn()
			end
			
		end
	end
	
	error( "Couldn't find "..path, 2 )
end



-- LUA EXTENSIONS

env.table = setmetatable( {}, {__index = table} )

function env.table.serialize( t, level )
	level = level or 1
	local s = "{\n"
	if type(t) ~= "table" then error( "Expected table", 2 ) end
	for k, v in pairs(t) do
		local serializable = (type(k) == "string" or type(k) == "number" or type(k) == "boolean")
			and (type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "table")
		
		if type(k) == "string" and not string.find(k, "(%s)") and serializable then
			s = s .. string.rep("  ", level)..k.." = "
		elseif type(k) == "string" and serializable then
			s = s .. string.rep("  ", level).."["..string.format("%q",k).."] = "
		elseif serializable then
			s = s .. string.rep("  ", level).."["..tostring(k).."] = "
		end
		
		if type(v) == "string" and serializable then
			s = s .. string.format("%q",v)..",\n"
		elseif type(v) == "table" and serializable then
			s = s .. env.table.serialize( v, level and level+1 )..",\n"
		elseif serializable then
			s = s .. tostring(v)..",\n"
		end
	end
	return s..string.rep("  ", level-1).."}"
end



-- RETURN

return env