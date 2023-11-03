# LuaRocks ZeroBrane Package
Search, install, and manage ZeroBrane Packages and Modules from LuaRocks directly in your favorite IDE!

## TODO

* Set Lua Interpreter to 5.1 on Install/Load IDE packages

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
