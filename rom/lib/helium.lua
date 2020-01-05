--[[
	
	Helium (He) Framework
	by RedPolygon
	
	for MoonBox
	
]]--

local he = {}
he._VERSION = "0.3"



-- HELIUM FRAMEWORK

he.styles = {}

he.make = {}
function he.make.x( obj, x )
	return function() return (x or 0) + (obj.parent and obj.parent:x()-1 or 0) end
end
function he.make.y( obj, y )
	return function() return (y or 0) + (obj.parent and obj.parent:y()-1 or 0) end
end

function he.proxy(...)
	local arg = {...}
	if type(arg[1]) == "function" then
		return arg[1]
	elseif #arg > 0 then
		return function() return unpack(arg) end
	end
end

--[[ function he:getx()
	return self.x() + (self.parent and self.parent:getx() or 0)
end
function he:gety()
	return self.y() + (self.parent and self.parent:gety() or 0)
end ]]

function he:setx(x)
	if type(x) ~= "number" and type(x) ~= "function" then return end
	self.x = (type(x) == "number" and he.make.x(self, x) or x)
end
function he:sety(y)
	if type(y) ~= "number" and type(y) ~= "function" then return end
	self.y = (type(y) == "number" and he.make.y(self, y) or y)
end

function he:set( field, value )
	self[field] = he.proxy(value)
end

--[[ function he:x(x)
	self:setx(x)
	return self:getx()
end
function he:y(y)
	self:sety(y)
	return self:gety()
end ]]

function he:center(what)
	if not self.parent then return end
	if string.find( what, "x" ) then
		self.x = function() return math.floor( self.parent:x() + (self.parent.w() - self.w())/2 ) end
	end
	if string.find( what, "y" ) then
		self.y = function() return math.floor( self.parent:y() + (self.parent.h() - self.h())/2 ) end
	end
end

function he:autosize( what, padding, ... )
	local objects = {...}
	
	if type(padding) ~= "number" then
		table.insert( objects, 1, padding )
		padding = nil
	end
	
	if string.find( what, "w" ) then
		self.w = function()
			local w = 0
			for i, obj in pairs(objects) do
				w = math.max( w, obj.x() - self.x() + obj.w() + (padding or self.padding and self.padding() or 0) )
			end
			return w
		end
	end
	if string.find( what, "h" ) then
		self.h = function()
			local h = 0
			for i, obj in pairs(objects) do
				h = math.max( h, obj.y() - self.y() + obj.h() + (padding or self.padding and self.padding() or 0) )
			end
			return h
		end
	end
end

function he:within( x, y )
	return x >= self.x() and x < self.x() + self.w()
		and y >= self.y() and y < self.y() + self.h()
end

function he:toLocalCoords( x, y )
	return x - self.x() + 1, y - self.y() + 1
end

function he:get(field)
	for k, tag in ipairs(self.tags) do
		if self.styles[tag] and self.styles[tag][field] then
			return he.proxy( self.styles[tag][field] )
		end
	end
	for k, tag in ipairs(self.tags) do
		if self.styles.defaults[tag] and self.styles.defaults[tag][field] then
			return he.proxy( self.styles.defaults[tag][field] )
		end
	end
end

function he:hasTag(tag)
	for i, t in pairs(self.tags) do
		if t == tag then
			return i
		end
	end
	return false
end

function he:addTag(tag)
	if not self:hasTag(tag) then
		table.insert( self.tags, 1, tag )
	end
end

function he:removeTag(tag)
	local pos = self:hasTag(tag)
	if pos then
		table.remove( self.tags, pos )
	end
	return pos
end

function he:toggleTag(tag)
	if not self:removeTag(tag) then self:addTag(tag) end
end

function he.new( x, y, w, h )
	return setmetatable( {
		x=he.proxy(x), y=he.proxy(y), w=he.proxy(w), h=he.proxy(h),
		styles = {defaults = he.styles}
	}, {__index = he} )
end



-- HELIUM ELEMENTS

he.box = {}

function he.box.new( p, x, y, w, h, color )
	local obj = {}
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"box", "*"}
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = he.proxy(w)
	obj.h = he.proxy(h)
	obj.color = he.proxy(color)
	
	return setmetatable( obj, {__index = function(t,k)
		return he.box[k] or he.get( obj, k )
	end} )
end

function he.box:draw(parent)
	self.parent = parent or self.parent
	screen.rect( self:x(), self:y(), self:w(), self:h(), self:color() )
end

setmetatable( he.box, {
	__index = he,
	__call = function( _, ... ) return he.box.new(...) end
})

he.styles.box = {
	color = "white"
}



he.text = {}

function he.text.new( p, x, y, text, color )
	local obj = {}
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"text", "*"}
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = function()
		return (screen.font.width+1) * #obj.text()
	end
	obj.h = he.proxy(screen.font.height)
	obj.text = he.proxy(text)
	obj.color = he.proxy(color)
	
	return setmetatable( obj, {__index = function(t,k)
		return he.get( obj, k ) or he.text[k]
	end} )
end

function he.text:draw(parent)
	self.parent = parent or self.parent
	screen.write( self.text(), {x = self.x(), y = self.y(), color = self.color()} )
end

setmetatable( he.text, {
	__index = he,
	__call = function( _, ... ) return he.text.new(...) end
})

he.styles.text = {
	color = "white"
}



he.input = {}

function he.input.new( p, x, y, w, h, color, background )
	local obj = {}
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"input", "*"}
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = he.proxy(w)
	obj.h = function()
		return h + 2 * obj.padding()
	end
	obj.color = he.proxy(color)
	obj.background = he.proxy(background)
	obj.read = read.new( nil, true )
	obj.read.cursor = false
	obj.input = ""
	
	return setmetatable( obj, {__index = function(t,k)
		return he.get( obj, k ) or he.input[k]
	end} )
end

function he.input:draw(parent)
	self.parent = parent or self.parent
	self.read.x = self.x() + self.padding()
	self.read.y = self.y() + self.padding()
	screen.rect( self:x(), self:y(), self:w(), self:h(), self:background() )
	
	local prevBg, prevColor = screen.background, screen.color
	screen.background = self:background()
	screen.color = self:color()
	self.read:draw()
	screen.background = prevBg
	screen.color = prevColor
	
	if self.border then
		screen.rect( self:x()-1, self:y()-1, self:w()+2, self:h()+2, self:border(), false )
	end
end

function he.input:update( e, param )
	if not self:hasTag("active") then return end
	
	self.read.length = #self.read.history[self.read.selected]
	local result = self.read:update( e, param )
	if result then
		self.input = result
		if type(self.callback) == "function" then
			self:callback(result)
		end
	end
end

function he.input:key(key) self:update( "key", key ) end
function he.input:char(char) self:update( "char", char ) end
function he.input:timer(id) self:update( "timer", id ) end

setmetatable( he.input, {
	__index = he,
	__call = function( _, ... ) return he.input.new(...) end
})

he.styles.input = {
	color = "white",
	background = "black"
}



he.button = {}

function he.button.new( p, x, y, w, h, title, callback )
	local obj = {}
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"button", "*"}
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = he.proxy(w)
	obj.h = he.proxy(h)
	
	obj.title = he.proxy(title)
	obj.callback = callback
	
	return setmetatable( obj, {__index = function(t,k)
		return he.get( obj, k ) or he.button[k]
	end} )
end

function he.button:draw(parent)
	self.parent = parent or self.parent
	
	screen.rect( self:x(), self:y(), self:w(), self:h(),
		self:hasTag("active") and self:activeBackground() or self:background() )
	screen.write( self.title(), {x = self:x() + self.padding(), y = self:y() + self.padding(),
		color = self:hasTag("active") and self:activeColor() or self:color(),
		background = self:hasTag("active") and self:activeBackground() or self:background()} )
end

function he.button:mouse( x, y, btn )
	if not self:within( x, y ) then return end
	self:addTag("active")
end

function he.button:mouseUp( x, y, btn )
	self:removeTag("active")
	if self:within( x, y ) and type(self.callback) == "function" then self:callback() end
end

setmetatable( he.button, {
	__index = he,
	__call = function( _, ... ) return he.button.new(...) end
})

he.styles.button = {
	color = "black",
	background = "white",
	activeColor = "white",
	activeBackground = "black",
	padding = 3,
	title = "button"
}



he.image = {}

function he.image.new( p, x, y, image, scale )
	local obj = {}
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"image", "*"}
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = function() return image.w * obj.scale() end
	obj.h = function() return image.h * obj.scale() end
	obj.image = image
	obj.scale = he.proxy(scale)
	
	return setmetatable( obj, {__index = function(t,k)
		return he.image[k] or he.get( obj, k )
	end} )
end

function he.image:draw(parent)
	self.parent = parent or self.parent
	screen.drawImage( self.image, self.x(), self.y(), self.scale() )
end

setmetatable( he.image, {
	__index = he,
	__call = function( _, ... ) return he.image.new(...) end
})

he.styles.image = {
	scale = 1
}



he.slider = {}

function he.slider.new( p, x, y, w, h, min, max, init )
	local obj = {}
	
	obj.parent = p
	obj.styles = obj.parent.styles
	obj.tags = {"slider", "*"}
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = he.proxy(w)
	obj.h = he.proxy(h)
	obj.min = min
	obj.max = max
	obj.value = init
	
	return setmetatable( obj, {__index = function(t,k)
		return he.slider[k] or he.get( obj, k )
	end} )
end

function he.slider:draw(parent)
	self.parent = parent or self.parent
	screen.rect( self.x(), self.y(), self.w(), self.h(), self.background() )
	local x = math.map( self.value or 0, self.min or 0, self.max or 1, 0, self.w() )
	screen.rect( self.x() + x - self.sliderWidth()/2, self.y(), self.sliderWidth(), self.h(), self.color() )
end

function he.slider:mouse( x, y, btn )
	if not self:within( x, y ) then return end
	x, y = self:toLocalCoords( x, y )
	self.value = math.map( x, 1, self.w(), self.min or 0, self.max or 1 )
	if self.callback then self:callback(self.value) end
end
function he.slider:drag( dx, dy, btn )
	if not self:within( mouse.x, mouse.y ) then return end
	x, y = self:toLocalCoords( mouse.x, mouse.y )
	self.value = math.map( x, 1, self.w(), self.min or 0, self.max or 1 )
	if self.callback then self:callback(self.value) end
end

setmetatable( he.slider, {
	__index = he,
	__call = function( _, ... ) return he.slider.new(...) end
})

he.styles.slider = {
	background = "white",
	color = "black",
	sliderWidth = 5,
}



-- RETURN

return he