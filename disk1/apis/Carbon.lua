--[[
	
	CARBON FRAMEWORK
	by RedPolygon
	
	Modified for Oxygen
	
--]]

-- VARIABLES

local carbon = {}
carbon.modules = {}
carbon.version = "0.4"





-- FUNCTIONS

function carbon.loadModule( module, name )
	if not module or not name then
		error( "Expected module (table/path), name", 2 )
	end
	if type(module) == "string" then -- Given path instead of table
		module = require(module)
	end
	carbon.modules[name] = setmetatable( module, {__index = carbon} )
end

function carbon.loadModules(modules)
	if not modules then
		error( "Expected modules (table/path)", 2 )
	end
	if type(modules) == "string" then
		modules = require(modules)
	end
	if not modules then return end
	for k, v in pairs(modules) do
		carbon.loadModule( v, k )
	end
end

-- Create new main object
function carbon.new(modules)
	local main = { calc = {} }
	main.objects = {}
	main.x, main.y = 1, 1
	main.w, main.h = screen.width, screen.height
	main.calc.x, main.calc.y = main.x, main.y
	
	return setmetatable( main, {__index = carbon} )
end

-- Add a child object
function carbon:addChild( module, data )
	if type(module) == "string" then -- Create new element and insert it
		if not carbon.modules[module] then
			error( "No such module: "..module, 2 )
		end
		table.insert( self.objects, 1, carbon.modules[module]:new( self, data ) )
		local object = self.objects[1]
		
		-- Add specified child objects
		if object.init then
			object:init(data)
		end
		if data.objects then
			for i = 1, #data.objects do
				object:addChild( data.objects[1][1], data.objects[1][2] )
			end
		end
		
		if object.update then
			object:update()
		end
		
		object.mt = object.mt or {}
		object.mt.__index = object.mt.__index and object.mt.__index(object) or object
		object.mt.__newindex = object.mt.__newindex and object.mt.__newindex(object) or object
		return setmetatable( {}, object.mt )
		
	elseif type(module) == "table" then -- Clone existing element
		table.insert( self.objects, 1, module )
		return setmetatable( {}, {__index = self.objects[1], __newindex = self.objects[1]} )
	end
end

-- Draw child objects
function carbon:drawObjects()
	for i = #self.objects, 1, -1 do -- Reverse loop
		self.objects[i]:draw()
	end
end
carbon.draw = carbon.drawObjects

-- Execute event functions for child objects
-- function carbon:event( event, ... )
-- 	for _, object in ipairs(self.objects) do
-- 		if type( object[event] ) == "function" then
-- 			object[event](object, ...)
-- 		end
-- 		if object.objects then
-- 			object:event( event, ... )
-- 		end
-- 	end
-- end

-- Execute event functions, self first
function carbon:event( event, ... )
	if type( self[event] ) == "function" then
		self[event]( self, ... )
	end
	if self.objects then
		for _, object in ipairs(self.objects) do
			object:event( event, ... )
		end
	end
end

-- Find elements by ID
function carbon:find(id)
	if type(id) == "number" then -- Find by index
		return setmetatable( {}, self.objects[id].mt )
	elseif type(id) == "string" then -- Find by id
		for _, v in ipairs(self.objects) do
			if v.id == id then
				return setmetatable( {}, v.mt )
			end
		end
		return {}
	end
end

function carbon:toFront()
	-- Find self
	local id
	for i = 1, #self.parent.objects do
		if self.parent.objects[i] == self then
			id = i
			break
		end
	end
	
	table.insert( self.parent.objects, 1, table.remove( self.parent.objects, id ) )
end

function carbon:pointInside( x, y )
	return x >= self.calc.x and y >= self.calc.y
		and x <= self.calc.x + (self.calc.w or self.w) - 1
		and y <= self.calc.y + (self.calc.h or self.h) - 1
end





-- RETURN

return setmetatable( carbon, {__call = function(_, ...) return carbon.new(...) end} )
