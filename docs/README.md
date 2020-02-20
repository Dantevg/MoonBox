# Documentation

MoonBox's code is divided into 2 types of files: APIs and libraries.
APIs are a part of MoonBox itself and need access to things outside of the sandbox,
while libraries just get normal (sandboxed) access.
Also, all APIs are loaded at boot, but only some libs are.
For others, you can use `require` to load them.

## APIs
- [`disk`](disk.md)
- [`event`](event.md)
- [`mouse`](mouse.md)
- [`net`](net.md)
- [`os`](os.md)
- [`screen`](screen.md)

## libs
- [`colours`](colours.md)
- [`helium`](helium.md)
- [`read`](read.md)
- [`shell`](shell.md)
- [`socket`](socket.md)
- [`swizzle`](swizzle.md)
- [`syntax`](syntax.md)

## [Programs](programs.md)