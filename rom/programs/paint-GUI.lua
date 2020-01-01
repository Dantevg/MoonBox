box{id="menu", color="white", w=screen.width, h=screen.height}{
	box{id="new", x=20, y=20, w=screen.width-40, h=40}{
		box{x=-20, w=80, h=screen.font.height+2, color="gray-2"}{
			text{x=20, y=2, text="NEW IMAGE"}
		},
		
		text{id="label.width", y=15, text="Width", color="black"},
		input{id="input.width", x=40, y=id"label.width".y-1, w=50, color="black", bg="gray+2", constraint="%d+"},
		
		text{id="label.height", y=id"label.width".y+10, text="Height", color="black"},
		input{id="input.height", x=40, y=id"label.height".y-1, w=50, color="black", bg="gray+2", constraint="%d+"},
		
		button{id="button.new", x=40, y=id"label.height".y+10, w=50, text="Create"}
	},
	
	box{id="open", x=20, y=id"new".y+id"new".h+20, w=screen.width-40, h=screen.font.height+1}{
		box{x=-20, w=80, h=screen.font.height+2, color="gray-2"}{
			text{x=20, y=2, text="OPEN FILE"}
		},
		
		text{id="label.filename", y=15, text="Filename", color="black"},
		input{id="input.filename", x=80, y=id"label.filename".y-1, w=100, color="black", bg="gray+2", constraint="%d+"},
		
		button{id="button.open", y=id"label.filename".y-2, text="Open"}
			(function(self)
				self.x = self.w - id"open".w - self.calc.w
				self:update()
			end),
	}
}
box{id="paint", color="black", w=screen.width, h=screen.height}