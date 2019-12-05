--[[
	
	Helium (He) Framework
	by RedPolygon
	
	for MoonBox
	
]]--

local he = {}
he._VERSION = "0.2"



-- HELIUM FRAMEWORK

he.make = {}
function he.make.x( obj, x )
	return function() return x + (obj.parent and obj.parent:x()-1 or 0) end
end
function he.make.y( obj, y )
	return function() return y + (obj.parent and obj.parent:y()-1 or 0) end
end

function he.proxy(...)
	local arg = {...}
	return function() return unpack(arg) end
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

function he:autosize( what, ... )
	local objects = {...}
	
	if string.find( what, "w" ) then
		self.w = function()
			local w = 0
			for i, obj in pairs(objects) do
				w = math.max( w, obj.x() - self.x() + obj.w() - 1 + (self.padding or 0) )
			end
			return w
		end
	end
	if string.find( what, "h" ) then
		self.h = function()
			local h = 0
			for i, obj in pairs(objects) do
				h = math.max( h, obj.y() - self.y() + obj.h() - 1 + (self.padding or 0) )
			end
			return h
		end
	end
end

function he.new( x, y, w, h )
	return setmetatable( {x=he.proxy(x), y=he.proxy(y), w=he.proxy(w), h=he.proxy(h)}, {__index = he} )
end



-- HELIUM ELEMENTS

he.box = {}
function he.box.new( p, x, y, w, h, color )
	local obj = {}
	
	obj.parent = p
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = he.proxy(w)
	obj.h = he.proxy(h)
	obj.color = color
	
	return setmetatable( obj, {__index = he.box} )
end
function he.box:draw(parent)
	self.parent = parent or self.parent
	screen.rect( self.x(), self.y(), self.w(), self.h(), self.color )
end
setmetatable( he.box, {
	__index = he,
	__call = function( _, ... ) return he.box.new(...) end
})

he.text = {}
function he.text.new( p, x, y, text, color )
	local obj = {}
	
	obj.parent = p
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = function()
		return (screen.font.width+1) * #obj.text
	end
	obj.h = he.proxy(screen.font.height)
	obj.text = text
	obj.color = color
	
	return setmetatable( obj, {__index = he.text} )
end
function he.text:draw(parent)
	self.parent = parent or self.parent
	screen.write( self.text, {x = self.x(), y = self.y(), color = self.color} )
end
setmetatable( he.text, {
	__index = he,
	__call = function( _, ... ) return he.text.new(...) end
})

he.input = {}
function he.input.new( p, x, y, w, h, color )
	local obj = {}
	
	obj.parent = p
	obj.x = he.make.x(obj, x)
	obj.y = he.make.y(obj, y)
	obj.w = function()
		return (screen.font.width+1) * #self.read + 2*self.padding
	end
	obj.h = function()
		return h + 2*self.padding
	end
	obj.color = color
	obj.padding = 2
	obj.read = read.new()
	
	return setmetatable( obj, {__index = he.input} )
end
function he.input:draw(parent)
	self.parent = parent or self.parent
	screen.rect( self.x(), self.y(), self.w(), self.h(), self.color )
end
setmetatable( he.input, {
	__index = he,
	__call = function( _, ... ) return he.input.new(...) end
})



-- RETURN

return he