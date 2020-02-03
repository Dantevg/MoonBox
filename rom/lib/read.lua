--[[
	
	Read lib / hybrid function
	Gets keyboard input from the user
	
	This lib acts like a function, so
		- read() just works like before, the traditional way. It halts the program until enter is pressed
		- read( _, true ) returns a read object, which can be called in a loop, just like the original read function does
	
]]--

local read = {}



-- INTERNAL FUNCTIONS

function read:draw(autocomplete)
	local input = self.history[self.selected]
	
	-- Background
	local bgLength = math.max( self.length + #self.completion, #input )
	self.y = self.y - (screen.font.height+1) * screen.write( string.rep(" ", bgLength+1),
		{x = self.x, y = self.y, background = screen.background, overflow = false} )
	
	-- Input
	local maxLength = math.floor( (screen.width-self.x+1) / (screen.font.width+1) ) - 1
	screen.write( string.sub( input, 1, self.pos-1 ), {x=self.x, y=self.y, overflow = "scroll", max = maxLength} )
	screen.write( self.cursor and "_" or string.sub(input, self.pos, self.pos), {overflow = false} )
	screen.write( string.sub( input, self.pos+1, -1 ), {overflow = false} )
	
	-- Autocompletion
	if self.autocomplete and autocomplete ~= false then
		local words = self:getWords("(%S*)(%s*)")
		self.completion = #words[#words-1].data > 0 and self.autocomplete( words[#words-1].data ) or ""
		if self.cursor and self.pos > #input then
			screen.write( string.sub( self.completion, 2, -1 ), {colour="gray-1", overflow = false} )
		else
			screen.write( self.completion, {colour="gray-1", overflow = false} )
		end
	end
end

function read:getWords(regex)
	local words = {}
	local length = 1
	for word, separator in string.gmatch( self.history[self.selected], regex or "(%w*)(%W*)" ) do
		table.insert( words, { type="word", data=word, s=length, e=length+#word-1 } )
		table.insert( words, { type="separator", data=separator, s=length+#word, e=length+#word+#separator-1 } )
		length = length + #word + #separator
	end
	if #words > 2 then
		table.remove( words, #words )
		table.remove( words, #words )
	end
	return words
end

function read:char(char)
	expect( char, "string" )
	
	self.history[#self.history] = string.sub( self.history[self.selected], 1, self.pos-1 )..char..string.sub( self.history[self.selected], self.pos, -1 )
	self.selected = #self.history
	self.pos = self.pos+1
end

function read:key(key)
	expect( key, "string" )
	
	if key == "enter" then
		self.cursor = false
		self:draw(false)
		os.cancelTimer(self.timer)
		local h = self.history
		h[#h] = h[self.selected]
		if (h[#h] == "" or h[#h] == h[#h-1]) and #h > 1 then
			return table.remove( h, #h )
		else
			return h[#h]
		end
	elseif key == "backspace" then
		if event.keyDown("ctrl") then
			local words = self:getWords()
			for i = 1, #words do
				if self.pos > words[i].s and self.pos <= words[i].e+1 then
					local l = #words[i].data
					words[i].data = string.sub( words[i].data, self.pos - words[i].s + 1 )
					self.pos = math.max( 1, self.pos-(l-#words[i].data) )
					break
				end
			end
			self.history[#self.history] = ""
			for i = 1, #words do
				self.history[#self.history] = self.history[self.selected] .. words[i].data
			end
			self.selected = #self.history
		else
			self.history[#self.history] = string.sub( self.history[self.selected], 1, math.max(0,self.pos-2) )
				..string.sub( self.history[self.selected], self.pos, -1 )
				self.pos = math.max( 1, self.pos-1 )
			self.selected = #self.history
		end
	elseif key == "delete" then
		if event.keyDown("ctrl") then
			local words = self:getWords()
			for i = 1, #words do
				if self.pos > words[i].s and self.pos <= words[i].e+1 then
					words[i].data = string.sub( words[i].data, 1, self.pos - words[i].s )
					break
				end
			end
			self.history[#self.history] = ""
			for i = 1, #words do
				self.history[#self.history] = self.history[self.selected] .. words[i].data
			end
			self.selected = #self.history
		else
			self.history[#self.history] = string.sub( self.history[self.selected], 1,self. self.pos-1 )
				..string.sub( self.history[self.selected], self.pos+1, -1 )
			self.selected = #self.history
		end
	elseif key == "up" then
		self.selected = math.max( 1, self.selected-1 )
		self.pos = #self.history[self.selected]+1
	elseif key == "down" then
		self.selected = math.min( self.selected+1, #self.history )
		self.pos = #self.history[self.selected]+1
	elseif key == "left" then
		if event.keyDown("ctrl") then
			local words = self:getWords()
			for i = 1, #words do
				if self.pos > words[i].s and self.pos <= words[i].e+1 then
					self.pos = (words[i].type == "word") and (words[i-1] and words[i-1].s) or words[i].s
					break
				end
			end
		else
			self.pos = math.max( 1, self.pos-1 )
		end
	elseif key == "right" then
		if event.keyDown("ctrl") then
			local words = self:getWords()
			for i = 1, #words do
				if self.pos >= words[i].s and self.pos <= words[i].e then
					self.pos = (words[i].type == "separator") and words[i+1].e+1 or words[i].e+1
					break
				end
			end
		else
			self.pos = math.min( self.pos+1, #self.history[self.selected]+1 )
		end
	elseif key == "home" then
		self.pos = 1
	elseif key == "end" then
		self.pos = #self.history[self.selected]+1
	elseif key == "tab" then
		self.history[#self.history] = self.history[self.selected] .. self.completion
		self.selected = #self.history
		self.pos = #self.history[self.selected] + 1
	end
end



-- INTERNAL / READ OBJECT FUNCTIONS

function read:update( e, param )
	expect( e, "string", 1, "(Read):update" )
	
	if e == "char" then
		return self:char(param)
	elseif e == "key" then
		return self:key(param)
	elseif e == "timer" and param == self.timer then
		self.timer = os.startTimer(0.5)
		self.cursor = not self.cursor
	end
end

-- read.new( [history [,async [,autocomplete]]] )
-- Note: for async, history doesn't need to be specified
function read.new( history, async, autocomplete )
	expect( history, {"table", "nil"}, 1, "read" )
	expect( async, {"boolean", "nil"}, 2, "read" )
	expect( autocomplete, {"function", "nil"}, 3, "read" )
	
	local r = {}
	r.history = history or {}
	table.insert( r.history, "" )
	r.selected = #r.history
	r.cursor = true
	r.x, r.y = screen.pos.x, screen.pos.y
	r.pos = 1
	r.length = 0
	r.timer = os.startTimer(0.5)
	r.autocomplete = autocomplete
	r.completion = ""
	
	if async then
		return setmetatable( r, {
			__index = read,
			__call = r.update
		} )
	else -- Wait for input. Stalls program until enter pressed (traditional)
		setmetatable( r, {__index = read} )
		while true do
			r:draw()
			r.length = #r.history[r.selected]
			local result = r:update( event.wait() )
			if result then return result end
		end
	end
end



-- RETURN

return setmetatable( read, {
	__call = function( _, ... )
		return read.new(...)
	end
})