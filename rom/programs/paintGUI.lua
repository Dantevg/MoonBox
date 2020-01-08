gui.paint = he:box( 1, 1, nil, nil, "black (0)" )
gui.paint:autosize( "wh", he )
table.insert( obj, gui.paint )
	
	gui.paint.obj.sidebar = gui.paint:box( 1, 1, 65, nil, "black" )
	gui.paint.obj.sidebar.h = function() return gui.paint.h() - 10 end
	gui.paint.obj.sidebar.obj = {}

	gui.paint.obj.sidebar.obj.picker = colourPicker( gui.paint.obj.sidebar, 1, 1 )
	-- gui.paint.obj.sidebar.obj.picker.h = function() return he.h() - 10 end
	gui.paint.obj.sidebar.obj.picker.obj = {}
	local Picker = gui.paint.obj.sidebar.obj.picker

		Picker.obj.primary = Picker:box( 1, Picker.x() + Picker.h() + 1, Picker.w()/2 - 1, 10, function() return colors.compose( colors.getName(primary), colors.getBrightness(primary) ) end )
		Picker.obj.secondary = Picker:box( Picker.w()/2+1, Picker.x() + Picker.h() + 1, Picker.w()/2 - 1, 10, function() return colors.compose( colors.getName(secondary), colors.getBrightness(secondary) ) end )
		
		Picker.obj.primaryOpacity = Picker:slider( 1, Picker.obj.primary.y() + Picker.obj.primary.h() + 1, Picker.w()/2 - 1, 10 )
		Picker.obj.primaryOpacity.callback = function( self, value )
			primary = colors.compose( colors.getName(primary), colors.getBrightness(primary), value )
		end
		Picker.obj.primaryOpacity.value = 1
		
		Picker.obj.secondaryOpacity = Picker:slider( Picker.w()/2+1, Picker.obj.primary.y() + Picker.obj.primary.h() + 1, Picker.w()/2 - 1, 10 )
		Picker.obj.secondaryOpacity.callback = function( self, value )
			secondary = colors.compose( colors.getName(secondary), colors.getBrightness(secondary), value )
		end
		Picker.obj.secondaryOpacity.value = 1
		
		local xOff, yOff = 1, 1
		for b in pairs(brushes) do
			if brushes[b].image then
				local y = yOff
				local img = screen.loadImage( math.decode64(brushes[b].image) )
				Picker.obj[b] = Picker:image( xOff, nil, img )
				Picker.obj[b].y = function() return Picker.obj.primaryOpacity.y() + Picker.obj.primaryOpacity.h() + y end
				Picker.obj[b].mouse = function( self, x, y, btn )
					if self:within( x, y ) then brush = b end
				end
				xOff = xOff + img.w + 1
				if xOff + img.w > Picker.w() then
					xOff = 1
					yOff = yOff + img.h + 1
				end
			end
		end
		
	gui.paint.obj.toolbar = gui.paint:box( 1, nil, nil, 10, "black" )
	gui.paint.obj.toolbar.y = function() return screen.height - 9 end
	gui.paint.obj.toolbar.w = function() return screen.width end
	gui.paint.obj.toolbar.obj = {}
	local Toolbar = gui.paint.obj.toolbar
		
		Toolbar.obj.file = Toolbar:text( 1, nil, function() return path or "no file opened" end, function() return path and "gray" or "gray-2" end )
		Toolbar.obj.file:center("y")
		
		Toolbar.obj.brush = Toolbar:text( nil, nil, function() return brush end, "gray" )
		Toolbar.obj.brush.x = function() return Toolbar.obj.file.x() + Toolbar.obj.file.w() + 10 end
		Toolbar.obj.brush:center("y")
		Toolbar.obj.brush.mouseUp = function( self, x, y, btn )
			if not self:within( x, y ) then return end
			local b = {}
			for k in pairs(brushes) do
				table.insert( b, k )
			end
			for i = 1, #b do
				if b[i] == brush then
					brush = b[ i % #b + 1 ]
					return
				end
			end
		end
		
		Toolbar.obj.zoom = Toolbar:text( nil, nil, function() return zoomInt.."x" end, "gray" )
		Toolbar.obj.zoom.x = function() return Toolbar.obj.brush.x() + Toolbar.obj.brush.w() + 10 end
		Toolbar.obj.zoom:center("y")

gui.menu = he:box( 1, 1, nil, nil, "gray+2" )
gui.menu:autosize( "wh", he )
gui.menu.obj = {}

	gui.menu.obj.path = gui.menu:box( margin, margin, nil, 20, "gray+2" )
	gui.menu.obj.path:autosize( "w", -margin, gui.menu )
	gui.menu.obj.path.obj = {}
	local Path = gui.menu.obj.path

		Path.obj.title = Path:text( 1, 1, "OPEN/SAVE", "black" )
		
		Path.obj.input = Path:input( 1, nil, nil, screen.font.height, "black" )
		Path.obj.input.y = function() return Path.obj.title.y() + Path.obj.title.h() + 5 end
		Path.obj.input:autosize( "w", Path )
		Path.obj.input.border = function(obj)
			if #obj.read.history[obj.read.selected] == 0 then
				return "gray+1"
			else
				return disk.info( obj.read.history[obj.read.selected] ).type == "file" and "blue" or "orange"
			end
		end
		Path.obj.input.background = function(obj)
			if #obj.read.history[obj.read.selected] == 0 or not obj:hasTag("active") then
				return "white"
			else
				return disk.info( obj.read.history[obj.read.selected] ).type == "file" and "blue+3" or "orange+3"
			end
		end
		Path.obj.input.callback = function( self, input )
			self:removeTag("active")
		end
		
		local buttonWidth = function() return (Path.w() - margin)/2
		end
		
		Path.obj.open = Path:button( 1, nil, nil, 11, "OPEN" )
		Path.obj.open.y = function() return Path.obj.input.y() + Path.obj.input.h() + 5 end
		Path.obj.open.w = buttonWidth
		Path.obj.open.callback = function()
			if loadFile( Path.obj.input.read.history[Path.obj.input.read.selected] ) then
				inMenu = false
			end
		end
		
		Path.obj.save = Path:button( nil, nil, nil, 11, "SAVE" )
		Path.obj.save.x = function() return Path.x() + Path.w() - buttonWidth() end
		Path.obj.save.y = function() return Path.obj.input.y() + Path.obj.input.h() + 5 end
		Path.obj.save.w = buttonWidth
		Path.obj.save.callback = function()
			if saveFile( Path.obj.input.read.history[Path.obj.input.read.selected] ) then
				inMenu = false
			end
		end
	
	Path:autosize( "h", 5, Path.obj.title, Path.obj.input, Path.obj.open, Path.obj.save )

	gui.menu.obj.create = gui.menu:box( margin, nil, nil, 20, "gray+2" )
	gui.menu.obj.create:autosize( "w", -margin, gui.menu )
	gui.menu.obj.create.y = function() return Path.y() + Path.h() + margin end
	gui.menu.obj.create.obj = {}
	local Create = gui.menu.obj.create

		Create.obj.title = Create:text( 1, 1, "NEW IMAGE", "black" )
		
		Create.obj.widthLabel = Create:text( 1, nil, "Width", "black" )
		Create.obj.widthLabel.y = function() return Create.obj.title.y() + Create.obj.title.h() + 6 end
		Create.obj.width = Create:input( nil, nil, 50, screen.font.height-1, "black" )
		Create.obj.width.x = function() return Create.obj.widthLabel.x() + Create.obj.widthLabel.w() + 5 end
		Create.obj.width.y = function() return Create.obj.width.parent.obj.title.y() + Create.obj.width.parent.obj.title.h() + 5 end
		Create.obj.width.char = function( self, char )
			if string.find( char, "%d" ) then
				self:update( "char", char )
			end
		end
		Create.obj.width.key = function( self, key )
			self:update( "key", key )
			if key == "tab" and self:hasTag("active") then
				self:removeTag("active")
				self.read.cursor = false
				Create.obj.height:addTag("active")
				Create.obj.height.read.timer = os.startTimer(0.5)
				Create.obj.height.read.cursor = true
			end
		end
		Create.obj.width.callback = function(self)
			self:removeTag("active")
			Create.obj.submit:callback()
		end
		
		Create.obj.heightLabel = Create:text( nil, nil, "Height", "black" )
		Create.obj.heightLabel.x = function() return Create.obj.width.x() + Create.obj.width.w() + 20 end
		Create.obj.heightLabel.y = Create.obj.widthLabel.y
		Create.obj.height = Create:input( nil, nil, 50, screen.font.height-1, "black" )
		Create.obj.height.x = function() return Create.obj.heightLabel.x() + Create.obj.heightLabel.w() + 5 end
		Create.obj.height.y = function() return Create.obj.height.parent.obj.title.y() + Create.obj.height.parent.obj.title.h() + 5 end
		Create.obj.height.char = function( self, char )
			if string.find( char, "%d" ) then
				self:update( "char", char )
			end
		end
		Create.obj.height.callback = function(self)
			self:removeTag("active")
			Create.obj.submit:callback()
		end
		
		Create.obj.submit = Create:button( nil, nil, 50, 11, "CREATE" )
		Create.obj.submit.x = function() return Create.x() + Create.w() - Create.obj.submit.w() end
		Create.obj.submit.y = function() return Create.obj.title.y() + Create.obj.title.h() + 4 end
		Create.obj.submit.callback = function(obj)
			local width = Create.obj.width.read.history[ Create.obj.width.read.selected ]
			local height = Create.obj.height.read.history[ Create.obj.height.read.selected ]
			if not tonumber(width) or not tonumber(height) then return end
			createImage( tonumber(width), tonumber(height) )
			inMenu = false
		end
	
	Create:autosize( "h", 5, Create.obj.title, Create.obj.width )