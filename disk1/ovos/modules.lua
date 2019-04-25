local modules = {}





modules.border = {}

function modules.border:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		calc = {
			x = parent.calc.x + (d.x or 0),
			y = parent.calc.y + (d.y or 0)
		},
		
		x = d.x or 0,
		y = d.y or 0,
		w = d.w or 0,
		h = d.h or 0,
		width = d.width or 1,
		color = d.color
	}, {__index = self} )
end

function modules.border:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
end

function modules.border:draw()
	screen.setColor( self.color or screen.color )
	-- Top
	screen.rect( self.calc.x, self.calc.y - self.width, self.w + self.width, self.width )
	-- Right
	screen.rect( self.calc.x + self.w, self.calc.y, self.width, self.h + self.width )
	-- Bottom
	screen.rect( self.calc.x - self.width, self.calc.y + self.h, self.w + self.width, self.width )
	-- Left
	screen.rect( self.calc.x - self.width, self.calc.y - self.width, self.width, self.h + self.width )
end





modules.titleBar = {}

function modules.titleBar:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		objects = {},
		calc = {
			x = parent.calc.x + (d.x or 0),
			y = parent.calc.y + (d.y or 0),
		},
		dragging = false,
		
		x = d.x or 0,
		y = d.y or 0,
		w = d.w or 0,
		h = d.h or screen.font.height + 2,
		color = d.color or "white",
	}, {__index = self} )
end

function modules.titleBar:init(d)
	-- Exit button
	self:addChild("box", {
		x = (d.w or 0) - screen.font.height - 2,
		y = 0,
		w = screen.font.height + 2,
		h = screen.font.height + 2,
		color = "red"
	})
	
	self.objects[1].mouse = function( self, x, y )
		if self:pointInside( x, y ) and self.parent.parent.close then
			self.parent.parent:close()
		end
	end
	
	-- Exit button "x"
	self.objects[1]:addChild("text", {
		x = 1,
		y = 1,
		text = "X",
		color = "white"
	})
	
	-- Title text
	self:addChild("text", {
		x = 0,
		y = 0,
		text = d.title and d.title.text or "Window",
		color = d.title and d.title.color or "black"
	})
end

function modules.titleBar:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	
	-- Update child objects
	for i = #self.objects, 1, -1 do -- Reverse loop
		if self.objects[i].update then self.objects[i]:update() end
	end
end

function modules.titleBar:draw()
	screen.rect( self.calc.x, self.calc.y, self.w, self.h, self.color )
	
	-- Draw child objects
	for i = #self.objects, 1, -1 do -- Reverse loop
		if self.objects[i].draw then self.objects[i]:draw() end
	end
end

function modules.titleBar:drag( dx, dy )
	local x, y = mouse.x, mouse.y
	if self.dragging then
		self.parent.x = self.parent.x + dx
		self.parent.y = self.parent.y + dy
		
		self.parent:update()
	elseif x == mouse.drag.x and y == mouse.drag.y and self:pointInside( x, y ) then
		self.dragging = true
	end
end

function modules.titleBar:mouseUp()
	self.dragging = false
end





modules.shadow = {}

function modules.shadow:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		calc = {
			x = parent.calc.x + (d.x or 0),
			y = parent.calc.y + (d.y or 0)
		},
		
		x = d.x and d.x - (d.size or 0) or 0,
		y = d.y and d.y - (d.size or 0) or 0,
		w = parent.w + 2*(d.size or 0),
		h = parent.h + 2*(d.size or 0),
		color = d.color or "black"
	}, {__index = self} )
end

function modules.shadow:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
end

function modules.shadow:draw()
	for x = 1, self.w do
		for y = 1, self.h do
			if not self.parent:pointInside( self.calc.x + x - 1, self.calc.y + y - 1 ) then
				-- local bg = screen.getPixel( self.calc.x + x - 1, self.calc.y + y - 1 )
				-- screen.pixel( self.calc.x+x-1, self.calc.y+y-1, colors.darker(bg) )
				screen.pixel( self.calc.x+x-1, self.calc.y+y-1, self.color )
			end
		end
	end
end





modules.window = {}

function modules.window:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		objects = {},
		calc = {
			x = parent.calc.x + (d.x or 0),
			y = parent.calc.y + (d.y or 0),
		},
		
		x = d.x or 0,
		y = d.y or 0,
		w = d.w or 0,
		h = d.h or 0,
		color = d.color or "white",
	}, {__index = self} )
end

function modules.window:init(d)
	self.window = screen.newWindow( self.calc.x, self.calc.y, self.w, self.h )
	
	self:addChild( "titleBar", {
		w = d.w,
		h = d.title and d.title.h,
		color = d.title and d.title.bg or "white",
		title = d.title
	})
	
	-- self:addChild( "shadow", {
	-- 	x = 2,
	-- 	y = 2,
	-- 	size = 1,
	-- 	color = "black (0.2)",
	-- })
	
	self:addChild( "border", {
		w = self.w,
		h = self.h,
		width = 1,
		color = "black"
	})
end

function modules.window:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	
	-- Update child objects
	for i = #self.objects, 1, -1 do -- Reverse loop
		if self.objects[i].update then self.objects[i]:update() end
	end
end

function modules.window:draw()
	screen.rect( self.calc.x, self.calc.y, self.w, self.h, self.color )
	
	-- Draw child objects
	for i = #self.objects, 1, -1 do -- Reverse loop
		if self.objects[i].draw then self.objects[i]:draw() end
	end
end

function modules.window:mouse( x, y )
	if self:pointInside( x, y ) then
		self:toFront()
	end
end

function modules.window:close()
	-- Find self in parent's object table, then remove it
	for i = 1, #self.parent.objects do
		if self.parent.objects[i] == self then
			table.remove( self.parent.objects, i )
		end
	end
end





modules.program = {}

function modules.program:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		calc = {
			x = parent.calc.x + (d.x or 0),
			y = parent.calc.y + (d.y or 0)
		},
		
		x = d.x or 0,
		y = d.y or 0,
		w = d.w or parent.w,
		h = d.h or parent.h,
		
		path = d.path,
		window = screen.newWindow( parent.x + (d.x or 0), parent.y + (d.y or 0),
			d.w or parent.w, d.h or parent.h )
	}, {__index = self} )
end

function modules.program:init()
	if not self.path then return end
	local file = disk.read(self.path)
	if not file then error("Error reading file") end
	local chunk = load(file)
	if not chunk then error("Error loading program") end
	
	self.co = coroutine.create(chunk)
	
	local prevWindow = getmetatable(screen.window).__index
	screen.setWindow(self.window)
	screen.clear("black")
	screen.setWindow(prevWindow)
	
	self:resume()
end

function modules.program:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	
	self.window.x = self.calc.x
	self.window.y = self.calc.y
end

function modules.program:event( event, ... )
	if event == "mouse" or event == "mouseUp" or event == "scroll" then
		-- Convert coordinates
		local param = {...}
		self:resume( event, param[1] - self.calc.x, param[2] - self.calc.y, unpack(param, 3) )
	else
		self:resume( event, ... )
	end
end

function modules.program:draw()
	screen.drawWindow(self.window)
end

-- One step through coroutine
function modules.program:resume( e, ... )
	if not self.co or coroutine.status(self.co) == "dead" then return end
	
	if not self.eventFilter or e == self.eventFilter then
		self.eventFilter = nil
		local prevWindow = getmetatable(screen.window).__index
		screen.setWindow(self.window)
		local ok, result = coroutine.resume( self.co, e, ... )
		screen.setWindow(prevWindow)
		if ok then
			self.eventFilter = result
		else
			error( "Error in program: "..(result or "nil") )
		end
	end
end





return modules