# Mouse

## Functions
### mouse.isDown ( button )
Returns whether `button` is down.
Button 1 is primary, 2 is secondary and 3 is the scroll wheel

---

## Variables
### mouse.x, mouse.y
These store the position of the mouse

### mouse.drag
When the mouse is moving and a mouse button is pressed,
this is a table storing the coordinates
(`mouse.drag.x`, `mouse.drag.y`) of where the drag started.

When the mouse isn't dragging, this is `nil`.