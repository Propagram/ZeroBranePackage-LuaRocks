# LuaRocks ZeroBrane Package

[![license](http://img.shields.io/badge/license-MIT-darkgreen.svg)](LICENSE)

Search, install, and manage [ZeroBrane Studio](https://studio.zerobrane.com/) Packages and Modules from [LuaRocks.org](https://luarocks.org/) directly in your favorite IDE!

![zbstudio](https://github.com/Propagram/ZeroBranePackage-LuaRocks/assets/89323442/50fa292e-5a84-4143-934c-ece5203697cd)

## How to install this package

1. Download the `LuaRocks.lua` file from this repository and place it in the folder `<UserHomePath>/.zbstudio/packages`.

2. Download the [LuaRocks binary from the official website](https://luarocks.github.io/luarocks/releases/) *(for Windows only)* or compile it from the source code [following the instructions on the official website](https://github.com/luarocks/luarocks/wiki/Download#user-content-installing), and place the executable in the same folder as `LuaRocks.lua` or make it searchable on the system `PATH`.

3. Install [git](https://git-scm.com/download/win) *(Windows)* or run `sudo apt-get install git` *(Linux)*

4. Restart the IDE.

## Features

* Search for modules on the Luarocks.org website directly through the plugin;
* Install, update, and remove modules with just one button;
* This plugin is capable of self-updating;
* Quickly access the official website of any installed package;
* **ALL** official packages are already available for installation in the plugin;
* You can install modules directly in the project or per-user.

## How to Deploy a ZeroBrane Package via LuaRocks

1. Create a public repository. The repository name must start with `ZeroBranePackage-` followed by the name of your package. For example, if your package file is named `example.lua`, the repository name should be `ZeroBranePackage-example`. It's important to check beforehand if `ZeroBranePackage-example` already exists, for instance, if it's been previously released on LuaRocks.org (perform a search before proceeding to ensure uniqueness).

2. Upload your `.lua` package file to the repository **without** the `ZeroBranePackage-` prefix. Using our example, the file should be named `example.lua`.

3. Now, create a `.rockspec` file (the LuaRocks accepted standard). You can use a text editor such as Notepad. The Rockspec format should be as follows. Remember to replace the values to fit your package! (In the example below, we'll use our sample: `ZeroBranePackage-example`)

```lua
package = "ZeroBranePackage-example" --> Edit here
version = "0.1.0-0"
source = {
 url = "git://github.com/YOUR-USERNAME/ZeroBranePackage-example.git", --> Edit here
 branch = "main"
}
description = {
 summary = "Package Example Title", --> Edit here
 detailed = [[Package Example Full Description]], --> Edit here
 homepage = "https://github.com/YOUR-USERNAME/ZeroBranePackage-example", --> Edit here
 maintainer = "Your Name", --> Edit here
 license = "MIT"
}
dependencies = {
  "lua == 5.1"
}
build = {
 type = "builtin",
 modules = {
  ["example"] = "example.lua", --> Mandatory: Remove "ZeroBranePackage-" prefix here
 }
}
```

4. Create an account on [LuaRocks.org](https://luarocks.org). LuaRocks is the de facto official package manager for the Lua language. The ecosystem is entirely free.

5. On LuaRocks.org, click **Upload**. On the left side, under "Rockspec", select the ".rockspec" file you previously created and click **Upload**.

6. Done! Your package is now available for installation within ZeroBrane Studio.

## License

MIT License

Copyright (c) 2023 Propagram

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
