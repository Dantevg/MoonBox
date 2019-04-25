local modules = {}

modules.text = {}

function modules.text:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		calc = {
			x = parent.x + (d.x or 0),
			y = parent.y + (d.y or 0),
			w = d.text and #d.text * (screen.font.width+1) or 0,
			h = screen.font.height
		},
		
		x = d.x or 0,
		y = d.y or 0,
		text = d.text or "",
		color = d.color or "white",
		bg = d.bg
	}, {__index = self} )
end

function modules.text:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	self.calc.w = self.text and #self.text * (screen.font.width+1) or 0
end

function modules.text:draw()
	screen.write( self.text, {x = self.calc.x, y = self.calc.y, color = self.color, background = self.bg } )
end





modules.box = {}

function modules.box:new( parent, d )
	return setmetatable( {
		id = d.id,
		parent = parent,
		objects = {},
		calc = {
			x = parent.x + (d.x or 0),
			y = parent.y + (d.y or 0),
		},
		
		x = d.x or 0,
		y = d.y or 0,
		w = d.w or 0,
		h = d.h or 0,
		color = d.color or "white"
	}, {__index = self} )
end

function modules.box:update()
	self.calc.x = self.parent.calc.x + self.x
	self.calc.y = self.parent.calc.y + self.y
	
	-- update child objects
	for i = #self.objects, 1, -1 do -- Reverse loop
		self.objects[i]:update()
	end
end

function modules.box:draw()
	screen.rect( self.calc.x, self.calc.y, self.w, self.h, self.color )
	
	-- Draw child objects
	for i = #self.objects, 1, -1 do -- Reverse loop
		self.objects[i]:draw()
	end
end





return modules