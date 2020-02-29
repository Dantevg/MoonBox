![image](docs/res/moonbox-128.png)
# MoonBox
MoonBox is yet another Lua sandbox, built with the [LÖVE][love2d] game engine.

## Features
- Runs on [LÖVE][love2d], with LuaJIT 5.1
- Screen: `300x200 @ 20fps` (configurable)
- Colours: `6-bit` palette
- Font: `5x5-pxl-round.ttf` (configurable in code)
- Built-in programs:
	- `edit` Text and code editor
	- `paint` Image editor
	- `hexview` Binary file viewer
	- `lua` Command prompt
- Networking with `luasocket` (`http`, `tcp`, `udp`)
- Love2d goodies, like hashing, compression and base64-encoding
- Lua `math` extensions like `constrain`, `map`, `lerp`, `round`
- ... More to come!

## Screenshots

### edit.lua  
![edit.lua](docs/res/edit.png)

### paint.lua  
![paint.lua](docs/res/paint.png)

<img src="docs/res/about.png" width="49%"> <img src="docs/res/charnoise.png" width="49%">
<img src="docs/res/menu.png" width="49%"> <img src="docs/res/settings.png" width="49%">

## Installation
I haven't created binaries yet. So for now, you will have to install it manually yourself.
If you've ever worked with [LÖVE][love2d], you know what to do.

## Documentation
For the documentation, refer to [docs/README.md](docs/README.md)

## License
Refer to [LICENSE](LICENSE). A copy here:
```
MIT License

Copyright (c) 2020 Dante van Gemert

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```



[love2d]: https://love2d.org
[cc]: https://computercraft.cc
