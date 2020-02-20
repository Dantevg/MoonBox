# Screen
Provides functions for drawing on the screen, using canvases and modifying graphics state.

## Variables
### screen.colours64
A table containing the `6-bit` palette (63 colours)

### screen.colours32
A table containing the `5-bit` palette (32 colours)

### screen.colours
A reference to either `screen.colours64` or `screen.colours32`

---
## Drawing functions
These functions all work on a canvas, but to make life easier,
they are set up in such a way that they default to the main screen,
except for`(Canvas):draw()`:
```lua
screen.pixel( 10, 10, "red" ) -- Draws a pixel on the main canvas
c:pixel( 10, 5, "blue" )      -- Draws a pixel on a different canvas,
                              -- assuming c is a canvas obtained from screen.newCanvas()
```

### (Canvas):draw ( x, y  [, scale] )
Draws the canvas to the specified coordinates, with the specified scale

### (Canvas):pixel ( x, y [, colour] )
Draws a pixel with colour `colour` at the specified coordinates.
If `colour` is not specified, draws using the current colour set by `screen.setColour`.

### (Canvas):char ( char [, x [, y [, colour [, scale]]]] )
Prints `char` to the specified position (defaults to the position set by `screen.setPos`).
`colour` defaults to the colour set by `screen.setColour` and `scale` defaults to `1`.

### (Canvas):write ( text [, x [, y]] ) <br> (Canvas):write ( text [, options] )
Writes `text` to the screen, at position (`x`,`y`), otherwise at position (`options.x`,`options.y`). Position defaults to the position set by `screen.setPos`.

When `options.max` is set, that is the maximum number of characters on one line (defaults to until the screen border).

Forces monospaced writing when `options.monospace` is `true`.

Depending on the value of `options.overflow`, when the maximum number of chars is reached,
either wraps and starts a new line (`"wrap"`), adds ellipsis to the end (`"ellipsis"`),
scrolls horizontally so the end of the string is within frame (`"scroll"`), or cuts off (`false`).  
When wrapping (or when encountering a newline character `'\n'`),
the new line starts at the same horizontal position as the previous line:
```
disk1> This line of text
       wraps and aligns
```

### (Canvas):print ( text [, colour] )
Writes `text` to the screen in `colour` (defaults to screen colour), and starts a new line.
This is almost the same as appending a newline character `'\n'` to the string,
but starts the new line aligned to the left screen border.

### (Canvas):rect ( [x [, y [, w [, h [, colour [, filled]]]]] )
Draws a rectangle at position (`x`,`y`), or the current cursor position,
of size (`w`,`h`), or `0`.
Fills (by default, only draws borders when `filled` is `false`) the rectangle with `colour`,
or the current foreground colour.

### (Canvas):line ( x1, y1, x2, y2 [, colour] )
Draws a line in `colour` between points (`x1`,`y1`) and (`x2`,`y2`)

### (Canvas):circle ( [xc [, yc [, r [, colour [, filled]]]]] )
Draws a circle around midpoint (`xc`,`yc`), or the current cursor position, with radius `r`,
in `colour`. `filled` defaults to `true`.

### (Canvas):drawImage ( image [, x [, y [, scale]]] )
Draws `image` (an image previously loaded by `loadImage`, or a string containing a `png` file)
to position (`x`,`y`), or (`1`,`1`). `scale` defaults to `1`.

### (Canvas):tabulate ( elements [, nColumns [, vertical [, fn]]] )
Prints all items from the table `elements`. The amount of columns is automatically determined,
but can be fixed by `nColumns`.

By default, prints the elements line by line. When `vertical` is `true`,
it prints them column by column:
```lua
local t = {'a','b','c','d','e','f'}
screen.tabulate( t, 2 )
--> a  b
--> c  d
--> e  f
screen.tabulate( t, 2, true )
--> a  d
--> b  e
--> c  f
```

If `fn` is a function, it is called with the item every time one is about to get printed.
It doesn't print the items to the screen, but it does set the position,
so `fn` can handle things like fancy coloured printing.

### (Canvas):clear ( [colour] )
Clears the canvas with `colour`.

### (Canvas):move ( x, y )
Moves (scrolls) the canvas in the direction specified, and updates the cursor position accordingly.

### (Canvas):cursor ( [x [, y [, colour]]] )
Draws the cursor (the underscore `'_'` character), at the specified position
(or the current cursor position), using `colour` (or the current foreground colour).

---
## Other functions
### (Canvas):getPixel ( x, y )
Returns the colour of the pixel at position (`x`,`y`).
This is the only non-drawing function that works on canvases.

### screen.setPixelPos ( x, y )
Sets the cursor position to the given coordinates

### screen.getPixelPos ( [x, y] )
Gets the current cursor position.

When `x` **and** `y` are given, those are character coordinates. Returns the
corresponding pixel coordinates.

### screen.setCharPos ( x, y )
Calculates the pixel coordinates from the character coordinates, and sets the cursor position.

### screen.getCharPos ( [x [, y]] )
Returns the character coordinates of the pixel given, or of the current cursor position.

### screen.setColour ( colour )
Sets the foreground colour.

### screen.setBackground ( colour )
Sets the background colour.

### screen.loadImage ( source )
When `source` is a string containing a `png` file, loads the image from that string.  
Otherwise, `source` must be a path to a `.png` file, from which it will try to load the image.

Returns a table containing `width`, `height` and the actual loaded image.

### screen.setFont ( path )
Loads the font at `path`, and sets it.

### screen.newCanvas ( width, height )
Returns a new canvas of given dimensions. The canvas can be used to draw on,
using all `(Canvas)` functions. It contains fields `width` and `height`.
```lua
local c = screen.newCanvas( 50, 50 )
c:write("Hello")
```

### screen.newShader ( path )
Loads the shader located at `path`, and returns it.

### screen.setShader ( [shader] )
Sets the current screen shader previously obtained by a call to `screen.newShader`,
and overrides the previous one if it was set. Call with no arguments to reset shader.

### screen.getFPS ( )
Returns the current frames per second.