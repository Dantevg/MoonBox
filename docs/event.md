# Event
Provides functions for event handling.

## Functions
### event.wait ( [event] )
Stops execution until `event` occurs (or any event, if missing).
Returns the event name, followed by any values specific for that event (see [Events](#Events)).
Always stops and errors when the "terminate" event occurs.

### event.push ( [event [, ...]] )
Pushes an event on the stack, whith name given by `event`,
and optional extra parameters which will be returned by `event.wait` later on.

### event.keyDown ( key )
Returns whether `key` is pressed. (see [Keys](#Keys))

---

## Events
These are the default events that are thrown by MoonBox:

#### key, keyUp
When a key has been pressed down (`key`) or released (`keyUp`).
Returns the name of the key.

#### char
When a printable character has been entered.
Returns the representation of the character,
which is almost same as the key name from `key` and `keyUp`.
(this represents space as the actual space character,
and distinguishes between upper and lower case)

#### mouse, mouseUp
When a mouse button has been pressed (`mouse`) or released (`mouseUp`).
Returns the x and y coordinates, followed by the button number
(1 is primary, 2 is secondary and 3 is the scroll wheel).

#### scroll
When the scroll wheel has moved.
Returns the x and y coordinates of the mouse, followed by the amount with which was scrolled  
Normally, when scrolling is not inverted (like Apple's magic mouse by default),
positive numbers scroll up.

#### drag
When the mouse moved while pressing a button.
Returns the dx and dy amounts of movement, followed by the button number.

#### resize
When the window has been resized.
Returns the new screen width and height.

---

## Keys
Printable keys are represented by their value,
except the space key, which is represented by the string `"space"`.
The numpad keys are prefixed by `"kp"`. Other keys are named after their non-abbreviated name,
so `"pagedown"` instead of ~~`'"pgdn"`~~.

The key names are almost equal to [Love2d's key names](https://love2d.org/wiki/KeyConstant)
(hey, what a coincidence!), but there are some differences:
- The enter key is called `"enter"`, not ~~`"return"`~~.
	This change was made because I thought it better represented the key.
- All keys which have a left and right variant don't have their direction present in the name:
	`"ctrl"` instead of ~~`"lctrl"`~~ and ~~`"rctrl"`~~.
	This change was made because I thought it wasn't needed to know which of the modifier keys was being pressed,
	and to offer a key combination which is only recognised outside of the sandbox.