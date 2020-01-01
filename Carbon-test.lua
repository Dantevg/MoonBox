-- MARKUP STYLE -- Nested Lua table

t = {"box", x=10, y=10, w=screen.width-20, h=screen.height-20,
	{"box", id="top", w=screen.width-20, h=50, color="red-1",
		{"text", text="Hello, world!", color="red+1"}
	},
	{"box", id="bottom", w=screen.width-20, h=50, color="blue-1",
		{"text", text="Bottom", color="blue+1"}
	}
}



-- MARKUP STYLE -- Nested Lua functions

Carbon.box{x=10, y=10, w=screen.width-20, h=screen.height-20,
	Carbon.box{id="top", w=screen.width-20, h=50, color="red-1",
		Carbon.text{text="Hello, world!", color="red+1"}
	},
	Carbon.box{id="bottom", w=screen.width-20, h=50, color="blue-1",
		{"text", text="Bottom", color="blue+1"}
	}
}



-- MARKUP STYLE -- Concatenated Lua functions

box{x=10, y=10, w=screen.width-20, h=screen.height-20}{
	box{id="top", w=screen.width-20, h=50, color="red-1"}{
		text{text="Hello, world!", color="red+1"}
	},
	box{id="bottom", w=screen.width-20, h=50, color="blue-1"}{
		text{text="Bottom", color="blue+1"}
	}
}



-- FUNCTION STYLE -- AddChild

GUI:addChild("box", {
	x = 10,
	y = 10,
	w = screen.width-20,
	h = screen.height-20
})
GUI:find(1):addChild("box", {
	id = "top",
	w = screen.width-20,
	h = 50,
	color = "red-1"
})
GUI:find("top"):addChild("text", {
	text = "Hello, world!",
	color = "red+1"
})
GUI:find(1):addChild("box", {
	id = "bottom",
	w = screen.width-20,
	h = 50,
	color = "blue-1"
})
GUI:find("bottom"):addChild("text", {
	text = "Bottom",
	color = "blue+1"
})



-- FUNCTION STYLE -- Plain functions

main = GUI:box{x=10, y=10, w=screen.width-20, h=screen.height-20}

top = main:box{id="top", w=screen.width-20, h=50, color="red-1"}
top:text{text="Hello, world!", color="red+1"}

bottom = main:box{id="bottom", w=screen.width-20, h=50, color="blue-1"}
bottom:text{text="Bottom", color="blue+1"}



-- FUNCTION STYLE -- x,y,w,h function

main = GUI:box( 10, 10, screen.width-20, screen.height-20 )

top = main:box( nil, nil, screen.width-20, 50 ){id="top", color="red-1"}
top:text(){text="Hello, world!", color="red+1"}

bottom = main:box( nil, nil, screen.width-20, 50 ){id="bottom", color="blue-1"}
bottom:text(){text="Bottom", color="blue+1"}



-- FUNCTION STYLE -- Property functions

main = Carbon.box(GUI).x(10).y(10).w(screen.width-20).h(screen.height-20)

top = Carbon.box(main).id("top").w(screen.width-20).h(50).color("red-1")
Carbon.text(top).text("Hello, world!").color("red+1")

bottom = Carbon.box(main).id("bottom").w(screen.width-20).h(50).color("blue-1")
Carbon.text(bottom).text("Bottom").color("blue+1")



-- FUNCTION STYLE -- Custom functions
main = GUI:box( 10, 10, screen.width-20, screen.height-20 )

top = main:box( nil, nil, screen.width-20, 50, "red-1" )
top:text( "Hello, world!", "red+1" )

bottom = main:box( nil, nil, screen.width-20, 50, "blue-1" )
bottom:text( "Bottom", "blue+1" )


GUI:vertical( 0, 0, screen.width, screen.height )
GUI[1]:vertical()
GUI[1][1]:header("NEW IMAGE")
GUI[1][1]:horizontal().id("width")
GUI[1][1]["width"]:text("Width")
GUI[1][1]["width"]:input().id("input")

GUI:ver().w("parent").margin(20)

GUI[1]:ver()
GUI[1][1]:text("NEW IMAGE").bg("gray-2")
GUI[1][1]:hor().w("parent")
GUI[1][1][2]:text("Width")
GUI[1][1][2]:input().callback(function(a) print(a) end)
GUI[1][1]:hor().w("parent")
GUI[1][1][3]:text("Height")
GUI[1][1][3]:input().callback(function(a) print(a) end)

GUI[1]:ver()
GUI[1][2]:hor().w("parent")
GUI[1][2][1]:text("Filename")
GUI[1][2][1]:input().callback(function(a) print(a) end)
GUI[1][2][1]:button("Open").callback(function(a) print(a) end)

vertical
	vertical
		text
		horizontal
			text
			input
		horizontal
			text
			input
		button
	
	vertical
		horizontal
			text
			input
			button