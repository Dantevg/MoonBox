# OS
Provides OS functions for time/timing,
shutdown/reboot communication and execution.

## Constants
### os.FPS
Contains the *target* FPS.

### os.version
Contains the string `"MoonBox {version}"`,
with `{version}` replaced by the current version number.

---

## Functions
### os.clock ( )
Acts the same way as the default Lua `os.clock`.

### os.time ( [h24 [, seconds]] )
Returns the formatted time in 12-hour clock
(or 24-hour clock when `h24` is set).
Doesn't include the seconds, except when `seconds` is set.

### os.date ( [yearFirst] )
Returns the date, in `dd-mm-yy` format,
or in `yy-mm-dd` when `yearFirst`.

### os.datetime ( )
Returns what would have been returned by the default Lua `os.date("*t")`.

### os.startTimer ( [seconds] )
Starts a timer for `seconds` seconds, or one frame when `nil`.
Returns the timer id, which will be returned by the [`timer` event](event.md#timer) later on.

### os.cancelTimer ( id )
Stops timer `id`.

### os.sleep ( [time] )
Blocks until `time` has been passed (see `os.startTimer`)

### os.reboot ( )
Reboots the computer. This is the same as calling `event.push("reboot")`.

### os.shutdown ( )
Immediately stops execution and shuts down.

### os.setClipboard ( text )
Sets MoonBoxs's sandbox clipboard to `text`.
This clipboard does not interfere with the system's clipboard,
except when you do that yourself in the MoonBox menu.

### os.getClipboard ( )
Returns the current value of MoonBox's clipboard.

### os.run ( path )
Runs the file at `path`.
