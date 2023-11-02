-- (c) 2023 Propagram. MIT Licensed. 

local luarocks_config = ide.config.luarocks or {}
local luarocks_version
local luarocks_path = luarocks_config.path or (ide.osname == "Windows" and "luarocks.exe" or "luarocks")
local luarocks_panel = "luarocksPanel"
local luarocks_variables = luarocks_config.variables or {}
local debug = luarocks_config.debug
local lua_dir, lua_version

local zerobrane_path, dir_separator = string.match(ide.editorFilename,"^(.+)([/\\])")
zerobrane_path = zerobrane_path .. dir_separator
local packages_path = zerobrane_path .. "packages" .. dir_separator
local project_path

local function print(...)
  if debug then
    ide:Print(...)
  end
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  url = url:gsub(" ", "+")
  return url
end

wx.wxGetApp():Connect(wx.wxEVT_HTML_TAG_HANDLER, function(object)
  local tag = object.HtmlTag:GetParam("tag")
  if tag == "a" then
    local href = object.HtmlTag:GetParam("href")
    local text = object.HtmlTag:GetParam("text")
    local parent = object:GetHtmlParser():GetWindowInterface():GetHTMLWindow()
    local link = wx.wxHyperlinkCtrl(parent, wx.wxID_ANY, text, href, wx.wxDefaultPosition, wx.wxDefaultSize)
    local widget = wx.wxHtmlWidgetCell(link, 0)
    object.HtmlParser:OpenContainer():InsertCell(widget)
    object:SetParseInnerCalled(false)
  end
end)

local bg, fg

local function luarocks(cmd, ok_callback, spec, no_lua, no_shell, old_lua_dir, old_lua_version)
  if no_lua then
    cmd = luarocks_path .." " .. cmd
  else
    local args = cmd
    cmd = luarocks_path ..
          " --lua-dir=\"" .. (old_lua_dir or lua_dir) .. "\"" ..
          " --lua-version=\"" .. (old_lua_version or lua_version) .. "\""
    if luarocks_config.server then
      cmd = luarocks_path ..
          " --server=\"" .. luarocks_config.server .. "\""
    end
    for key, value in pairs(luarocks_variables) do
      if type(key) == "string" then
        cmd = cmd .. " " .. key:gsub("\"", "") .. "=\"" .. value:gsub("\"", "") .. "\""
      end
    end
    if spec == 0 then -- Projects Modules
      cmd = cmd ..
            " --tree=\"" .. project_path:gsub("\"", "") .. (luarocks_config.directory or "luarocks_modules") .. "\""
      spec = project_path
    elseif spec == 1 then  -- System/User Modules
      
    elseif spec == 2 then  -- IDE Packages
      cmd = cmd ..
            " --tree=\"" .. packages_path:gsub("\"", "") .. "\""
      spec = packages_path
    end
    cmd = cmd .." " .. args
  end
  local shell_cmd = 'bash -c "%s"' -- do not use %q
  if ide.osname == "Windows" then
    shell_cmd = 'cmd /c "%s"' -- do not use %q
  end
  if not no_shell then
    cmd = shell_cmd:format(cmd:gsub('"', '""'))
  end
  local results = {}
  -- CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
  return CommandLineRun(cmd, type(spec) == "string" and spec or nil, true, false, function(result)
    if type(result) == "string" then
      table.insert(results, result)
    end
  end, cmd, function(pid)
    local out = table.concat(results):match("^[\n\r\f%s\t]*(.-)[%s\t\n\r\f]*$")
    return ok_callback and ok_callback(out, pid)
  end)
end

-- IDE Packages luarocks command hack
local function luarocks_ide(cmd, callback)
  local old_lua_dir = lua_dir
  local old_lua_version = lua_version
  local lua_modules_path = "/share/lua/" .. old_lua_version
  local lib_modules_path = "/lib/lua/" .. old_lua_version
  local rocks_subdir = "/lib/luarocks/rocks-" .. old_lua_version
  luarocks("config lua_modules_path \"\"", function()
    luarocks("config lib_modules_path \"\"", function()
      luarocks("config rocks_subdir \"\"", function()
        luarocks(cmd, function(result)
          luarocks("config lua_modules_path \"" .. lua_modules_path .. "\"", function()
            luarocks("config lib_modules_path \"" .. lib_modules_path .. "\"", function()
              luarocks("config lib_modules_path \"" .. rocks_subdir .. "\"", function()
                return callback and callback(result)
              end, 2, nil, nil, old_lua_dir, old_lua_version)
            end, 2, nil, nil, old_lua_dir, old_lua_version)
          end, 2, nil, nil, old_lua_dir, old_lua_version)
        end, 2, nil, nil, old_lua_dir, old_lua_version)
      end, 2, nil, nil, old_lua_dir, old_lua_version)
    end, 2, nil, nil, old_lua_dir, old_lua_version)
  end, 2, nil, nil, old_lua_dir, old_lua_version)
end

local page_image_list = wx.wxImageList(24, 24)
page_image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER_OPEN, wx.wxART_OTHER, wx.wxSize(-1, -1)))
page_image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_GO_HOME, wx.wxART_TOOLBAR, wx.wxSize(24, 24)))
page_image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_TOOLBAR, wx.wxSize(24, 24)))
page_image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_INFORMATION, wx.wxART_TOOLBAR, wx.wxSize(24, 24)))

local image_list = wx.wxImageList(16, 16)
image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_LIST_VIEW, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FIND_AND_REPLACE, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_GO_DOWN, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_HELP, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
image_list:Add(wx.wxArtProvider.GetBitmap(wx.wxART_DELETE, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))

local function create_html(html)
  if not html then
    return "<html></html>"
  end
  html = html:gsub("&", "&amp;")
  html = html:gsub("<", "&lt;")
  html = html:gsub(">", "&gt;")
  html = html:gsub("\n", "<br/>\n")
  html = html:gsub("(.-)%s%-%s([^<]+)", function(title, summary)
    return "<h5>" .. title .. "</h5><p>" .. summary .. "</p><hr/>"
  end)
  html = html:gsub("(https://[^%s\n]+)", function(link)
    return "<lua tag='a' href='" .. link .. "' text='" .. link .. "'>"
  end)
  html = html:gsub("\n([A-Za-z0-9%s]-):", function(title)
    return "<br/><b>" .. title .. ":</b> "
  end)
  return [[
<html>
    <head>
    <title>wxLua Bound Widget demonstration</title>
    </head>
    <body>
]] .. html .. [[
    </body>
</html>
]]
end

local onTabLoad = {}

local function create_tab(parent, page, tab)

  local panel = wx.wxPanel(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
  local sizer = wx.wxBoxSizer(wx.wxVERTICAL)

  local list = wx.wxListBox(panel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
  
  list:SetBackgroundColour(bg)
  list:SetForegroundColour(fg)

  local box =  wx.wxStaticBoxSizer(wx.wxVERTICAL, panel, page == 2 and "Package:" or "Module:")
  box:GetStaticBox():Enable(false)

  local image = wx.wxArtProvider.GetBitmap(wx.wxART_FIND, wx.wxART_BUTTON, wx.wxSize(16, 16))
  
  local details
  local results_label

  if tab == 2 then --> Download

    local search_panel = wx.wxPanel(panel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
    local search_sizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    
    search_panel:SetSizer(search_sizer)
    
    local search_label = wx.wxStaticText(panel, wx.wxID_ANY, page == 2 and "Search packages:" or "Search modules:")
    -- search_label:SetForegroundColour(fg)

    local search = wx.wxTextCtrl(search_panel, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_PROCESS_ENTER)
    
    search:SetBackgroundColour(bg)
    search:SetForegroundColour(fg)
    
    local search_button = wx.wxBitmapButton(search_panel, wx.wxID_ANY, image, wx.wxDefaultPosition, wx.wxDefaultSize)
    
    local event = function()
      local cmd
      local value = search:GetValue()
      value = value:match("^[%s\t]*(.-)[%s\t]*$")
      value = value:gsub("[^a-zA-Z_%-0-9]", "")
      if value == "" then
        results_label:SetLabel("No results for '" .. search:GetValue() .. "'")
        return
      end
      results_label:SetLabel("Searching...")
      if page == 0 then -- Project Modules
        cmd = "search " .. value .. " --porcelain"
      elseif page == 1 then -- System Modules
        cmd = "search " .. value .. " --porcelain"
      elseif page == 2 then -- IDE Packages
        cmd = "search " .. (luarocks_config.package_prefix or "ZeroBranePackage-") .. value .. " --porcelain"
      else
        print("page not found:", page)
        return
      end
      
      luarocks(cmd, function(out)
        local items = {}
        string.gsub(out, "([^\n\r\f%s\t]+)[%s\t]+[0-9%.%-]+[%s\t]+rockspec", function(item)
          if not items[item] then
            items[#items + 1] = item
          end
          items[item] = true
        end)
        list:Clear()
        list:InsertItems(items, list:GetCount())
        if #items == 0 then
          results_label:SetLabel("No results for '" .. search:GetValue() .. "'")
        elseif #items == 1 then
          results_label:SetLabel(#items .. " result for '" .. search:GetValue() .. "':")
        else
          results_label:SetLabel(#items .. " results for '" .. search:GetValue() .. "':")
        end
        --list:InsertItems({"teste"}, list:GetCount())
      end)
    end

    search_button:Connect(wx.wxEVT_BUTTON, event)
    search:Connect(wx.wxEVT_TEXT_ENTER, event)

    search_sizer:Add(search, 2,  wx.wxEXPAND+wx.wxALL, 0)
    search_sizer:Add(search_button, 0,  wx.wxEXPAND+wx.wxRIGHT + wx.wxBOTTOM + wx.wxTOP, 0)
    
    sizer:Add(search_label, 0,  wx.wxEXPAND+wx.wxALL, 4)
    sizer:Add(search_panel, 0,  wx.wxEXPAND+wx.wxALL, 0)

  elseif tab == 1 then --> Installed

    onTabLoad[page] = function()
      list:Clear()
      details:SetPage(create_html())
      box:GetStaticBox():Enable(false)

      results_label:SetLabel("Loading...")

      if page == 0 then --> Project Modules
        luarocks("list --porcelain", function(result)
          local items = {}
          string.gsub(result, "([^\n\r\f%s\t]+)[%s\t]+[0-9%.%-]+[%s\t]+installed", function(item)
            if not items[item] then
              items[#items + 1] = item
            end
            items[item] = true
          end)
          list:Clear()
          list:InsertItems(items, list:GetCount())
          if #items == 0 then
            results_label:SetLabel(page == 2 and "No packages found" or "No modules found")
          elseif #items == 1 then
            results_label:SetLabel(page == 2 and #items .. " package found:" or #items .. " module found:")
          else
            results_label:SetLabel(page == 2 and #items .. " packages found:" or #items .." modules found:")
          end
        end, 0)
      elseif page == 1 then --> System Modules
        luarocks("list --porcelain", function(result)
          local items = {}
          string.gsub(result, "([^\n\r\f%s\t]+)[%s\t]+[0-9%.%-]+[%s\t]+installed", function(item)
            if not items[item] then
              items[#items + 1] = item
            end
            items[item] = true
          end)
          list:Clear()
          list:InsertItems(items, list:GetCount())
          if #items == 0 then
            results_label:SetLabel(page == 2 and "No packages found" or "No modules found")
          elseif #items == 1 then
            results_label:SetLabel(page == 2 and #items .. " package found:" or #items .. " module found:")
          else
            results_label:SetLabel(page == 2 and #items .. " packages found:" or #items .." modules found:")
          end
        end, 1)
      elseif page == 2 then --> IDE Packages
        luarocks_ide("list --porcelain", function(result)
          local items = {}
          string.gsub(result, "([^\n\r\f%s\t]+)[%s\t]+[0-9%.%-]+[%s\t]+installed", function(item)
            local start, final = string.find(item, (luarocks_config.package_prefix or "ZeroBranePackage-"), 0, true)
            if start == 1 then
              item = string.sub(item, final + 1)
              if not items[item] then
                items[#items + 1] = item
              end
              items[item] = true
            end
          end)
          list:Clear()
          list:InsertItems(items, list:GetCount())
          if #items == 0 then
            results_label:SetLabel(page == 2 and "No packages found" or "No modules found")
          elseif #items == 1 then
            results_label:SetLabel(page == 2 and #items .. " package found:" or #items .. " module found:")
          else
            results_label:SetLabel(page == 2 and #items .. " packages found:" or #items .." modules found:")
          end
        end, 1)
      else
        print("page not found:", page)
        return
      end

    end
    
  end
  
  results_label = wx.wxStaticText(panel, wx.wxID_ANY, tab == 2 and "Results:" or (page == 2 and "Packages:" or "Modules:"))
  sizer:Add(results_label, 0,  wx.wxEXPAND+wx.wxALL, 4)

  sizer:Add(list, 10,  wx.wxEXPAND+wx.wxALL, 0)
  sizer:Add(box, 1,  wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT + wx.wxBOTTOM, 0)
  panel:SetSizer(sizer)

  if tab == 1 then --> Installed
    
    details = wx.wxLuaHtmlWindow(box:GetStaticBox(), wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(0, 100))
  
    details:SetPage(create_html())

    box:Add(details, 10, wx.wxEXPAND+wx.wxALL, 0)

  end
  
  local toolbar = wx.wxToolBar(box:GetStaticBox(), wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTB_NODIVIDER)

  if tab == 1 then --> Installed
    toolbar:AddTool(wx.wxID_ANY, "&Update", image_list:GetBitmap(4), page == 2 and "Update package" or "Update module") --> 0
    toolbar:AddSeparator() --> 1
    toolbar:AddTool(wx.wxID_ANY, "&Homepage", image_list:GetBitmap(3), page == 2 and "Package homepage" or "Module homepage") --> 2
    toolbar:AddSeparator() --> 3
    toolbar:AddTool(wx.wxID_ANY, "&Remove", image_list:GetBitmap(5), page == 2 and "Remove package" or "Remove module") --> 4
  elseif tab ==2 then --> Download
    toolbar:AddTool(wx.wxID_ANY, "&Install", image_list:GetBitmap(2), page == 2 and "Install package" or "Intall module") --> 0
    toolbar:AddSeparator() --> 1
    toolbar:AddTool(wx.wxID_ANY, "&Query", image_list:GetBitmap(3), page == 2 and "Query package" or "Query module") --> 2
  end
  
  toolbar:Connect(wx.wxEVT_COMMAND_MENU_SELECTED, function(event)

    local tool = toolbar:GetToolPos(event:GetId())
    
    if tool == wx.wxNOT_FOUND then
      return
    end
    
    print("tool:", tool, page, tab)
    
    local selection = list:GetSelection()
    if selection == wx.wxNOT_FOUND then
      return
    end
    local item = list:GetString(selection)

    if tab == 1 then --> Installed
      
      if tool == 0 then --> Update
        if page == 0 then --> Project modules
          luarocks("install " .. item, function(result)
            print(result)
            onTabLoad[page]()
          end, 0)
        elseif page == 1 then --> System modules
          luarocks("install " .. item, function(result)
            print(result) 
            onTabLoad[page]()
          end, 2)
        elseif page == 2 then --> IDE packages
          luarocks_ide("install " .. (luarocks_config.package_prefix or "ZeroBranePackage-") .. item, function(result)
            print(result)
            onTabLoad[page]()
          end)
        end
      elseif tool == 2 then --> Homepage
        if page == 0 then --> Project modules
          luarocks("show " .. item .. " --porcelain", function(result)
            local homepage = string.match(result, "\nhomepage[%s\t]+([^\n%s]+)")
            if homepage then
              wx.wxLaunchDefaultBrowser(homepage, 0)
            else
              print("no homepage found")
            end
          end, 0)
        elseif page == 1 then --> System modules
          luarocks("show " .. item .. " --porcelain", function(result)
            local homepage = string.match(result, "\nhomepage[%s\t]+([^\n%s]+)")
            if homepage then
              wx.wxLaunchDefaultBrowser(homepage, 0)
            else
              print("no homepage found")
            end
          end, 2)
        elseif page == 2 then --> IDE packages
          luarocks_ide("show " .. (luarocks_config.package_prefix or "ZeroBranePackage-") .. item .. " --porcelain", function(result)
            local homepage = string.match(result, "\nhomepage[%s\t]+([^\n%s]+)")
            if homepage then
              wx.wxLaunchDefaultBrowser(homepage, 0)
            else
              print("no homepage found")
            end
          end)
        end
        
      elseif tool == 4 then --> Remove

        if wx.wxMessageDialog(ide:GetProjectNotebook(), page == 2 and "Are you sure you want to remove the package " .. item .. "?" or "Are you sure you want to remove the module " .. item .. "?", "Confirm",  wx.wxICON_QUESTION+wx.wxOK+wx.wxCANCEL):ShowModal() == wx.wxID_OK then
          if page == 0 then --> Project modules
            luarocks("remove " .. item, function(result)
              print(result)
              onTabLoad[page]()
            end, 0)
          elseif page == 1 then --> System modules
            luarocks("remove " .. item, function(result)
              print(result) 
              onTabLoad[page]()
            end, 2)
          elseif page == 2 then --> IDE packages
            luarocks_ide("remove " .. (luarocks_config.package_prefix or "ZeroBranePackage-") .. item, function(result)
              print(result)
              onTabLoad[page]()
            end)
          end
        end
      end
      
    elseif tab ==2 then --> Download

      if tool == 0 then --> Install
        if page == 0 then --> Project modules
          luarocks("install " .. item, function(result)
            print(result)
            onTabLoad[page]()
          end, 0)
        elseif page == 1 then --> System modules
          luarocks("install " .. item, function(result)
            print(result) 
            onTabLoad[page]()
          end, 2)
        elseif page == 2 then --> IDE packages
          luarocks_ide("install " .. (luarocks_config.package_prefix or "ZeroBranePackage-") .. item, function(result)
            print(result)
            onTabLoad[page]()
          end)
        end
      elseif tool == 2 then --> Query
        wx.wxLaunchDefaultBrowser("https://luarocks.org/search?q=" .. urlencode(item), 0)
      end
    end
    

  end)
  
  toolbar:Realize()
  
  box:Add(toolbar, 0,  wx.wxEXPAND+wx.wxALL, 2)

  list:Connect(wx.wxEVT_LISTBOX, function(object)
    
    local selection = object:GetSelection()

    if selection == wx.wxNOT_FOUND then
      return
    end
    
    local item = object:GetString(selection)

    ide:Print("item:", item)
    box:GetStaticBox():Enable(true)
    
    if tab == 1 then -- Installed
      if page == 0 then --> Project modules
        luarocks("show " .. item, function(result)
          details:SetPage(create_html(result))
        end, 0)
      elseif page == 1 then --> System modules
        luarocks("show " .. item, function(result)
          details:SetPage(create_html(result))
        end, 2)
      elseif page == 2 then --> IDE packages
        luarocks_ide("show " .. (luarocks_config.package_prefix or "ZeroBranePackage-") .. item, function(result)
          details:SetPage(create_html(result))
        end)
      end
    end
    
  end)

  return panel
end



local function create_page(parent, page)

  local panel = wx.wxPanel(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
  local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
  
  local subcontrol = wx.wxToolbook(panel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)

  sizer:Add(subcontrol, 0, wx.wxEXPAND+wx.wxALL, 0)

  subcontrol:SetImageList(image_list)
  subcontrol:AddPage(create_tab(subcontrol, page, 1), "Installed", true, 0)
  subcontrol:AddPage(create_tab(subcontrol, page, 2), "Download", false, 1)

  panel:SetSizer(sizer)

  return panel
end

local function create_about(parent)
  local panel = wx.wxPanel(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
  local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
  
  local subcontrol = wx.wxLuaHtmlWindow(panel)

  subcontrol:SetPage([[
<html>
    <head>
    <title>About LuaRocks ZeroBrane Package</title>
    </head>
    <body>
        <h3>LuaRocks ZeroBrane Package</h3>
        <p><b>LuaRocks</b> is the package manager for Lua modules.</p>
        <p>It allows you to create and install Lua modules as self-contained packages called <i>rocks</i>. You can download and install LuaRocks on Unix and Windows. <lua tag="a" href="https://luarocks.org/#quick-start" text="Get started"></p>
        <p>LuaRocks is free software and uses the same license as Lua.</p>
        <hr>
        <p>Submit your fixes, issues, and feature requests to help improve this project!</p>
        <p>
          <lua tag="a" href="https://github.com/Propagram/ZeroBranePackage-LuaRocks" text="https://github.com/Propagram/ZeroBranePackage-LuaRocks">
        </p>
    </body>
</html>
]])

  sizer:Add(subcontrol, 1, wx.wxEXPAND+wx.wxALL, 0)
  panel:SetSizer(sizer)
  
  return panel
end

local w, h = 200,200
local conf = function(panel)
  panel:Dock():MinSize(w,-1):BestSize(w,-1):FloatingSize(w,h)
end

local function success()

    if type(ide:GetConfig().styles) == "table" and  ide:GetConfig().styles.text then
      bg = wx.wxColour(unpack(ide:GetConfig().styles.text.bg))
      fg = wx.wxColour(unpack(ide:GetConfig().styles.text.fg))
    end
    
    local control = wx.wxListbook(ide:GetProjectNotebook(), wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(200,200))

    control:SetImageList(page_image_list)
    
    control:GetListView():SetBackgroundColour(bg)
    control:GetListView():SetForegroundColour(fg)
    
    control:Connect(wx.wxEVT_LISTBOOK_PAGE_CHANGED, function(object) 

      local page = object:GetSelection()

      if page == wx.wxNOT_FOUND then
        return
      end

      if onTabLoad[page] then
        onTabLoad[page]()
      end

    end)

    control:AddPage(create_page(control, 0), "Project Modules", true, 0)
    control:AddPage(create_page(control, 1), "Global Modules", false, 1)
    control:AddPage(create_page(control, 2), "IDE\nPackages", false, 2)
    -- control:AddPage(CreateBookPage(control, 3), "Tools", false, 2)
    control:AddPage(create_about(control), "About", false, 3)

    ide:AddPanelFlex(ide:GetProjectNotebook(), control, luarocks_panel, TR("LuaRocks"), conf)
end

local function failure()
  
  local panel = wx.wxPanel(ide:GetProjectNotebook(), wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize)
  local sizer = wx.wxBoxSizer(wx.wxVERTICAL)
  
  local subcontrol = wx.wxLuaHtmlWindow(panel)

  sizer:Add(subcontrol, 1, wx.wxEXPAND+wx.wxALL, 0)
  panel:SetSizer(sizer)

  if ide.osname == "Windows" then
    subcontrol:SetPage([[
<html>
    <head>
    <title>LuaRocks ZeroBrane Package</title>
    </head>
    <body>
        <h3>LuaRocks ZeroBrane Package</h3>
        <hr>
        <p><b>Could not find "LuaRocks.exe" on your system PATH.</b><br/><br/>Download or compile the executable and place it in the same folder as this package <i>(]] .. packages_path .. [[luarocks.exe)</i>, or edit the settings (Edit Menu/Preferences) and provide the executable location as follows:<br/><br/><i>luarocks = {<br/>&nbsp;&nbsp;path = "C:/path/to/luarocks.exe"<br/>}</i></p>
        <br/><hr>
        <p>Submit your fixes, issues, and feature requests to help improve this project!</p>
        <p><lua tag="a" href="https://github.com/Propagram/ZeroBranePackage-LuaRocks" text="https://github.com/Propagram/ZeroBranePackage-LuaRocks">
        </p>
    </body>
</html>
]])
  else
    subcontrol:SetPage([[
<html>
    <head>
    <title>LuaRocks ZeroBrane Package</title>
    </head>
    <body>
        <h3>LuaRocks ZeroBrane Package</h3>
        <hr>
        <p><b>Could not find "LuaRocks" on your system PATH.</b><br/><br/>Download and build the source code and place it in the same folder as this package <i>(]] .. packages_path .. [[luarocks)</i>, or edit the settings (Edit Menu/Preferences) and provide the binary location as follows:<br/><br/><i>luarocks = {<br/>&nbsp;&nbsp;path = "/path/to/luarocks"<br/>}</i></p>
        <br/><hr>
        <p>Submit your fixes, issues, and feature requests to help improve this project!</p>
        <p><lua tag="a" href="https://github.com/Propagram/ZeroBranePackage-LuaRocks" text="https://github.com/Propagram/ZeroBranePackage-LuaRocks">
        </p>
    </body>
</html>
]])
  
  end

  ide:AddPanelFlex(ide:GetProjectNotebook(), panel, luarocks_panel, "LuaRocks", conf)
end

return {
  name = "LuaRocks ZeroBrane Package",
  description = "Search, install, and manage ZeroBrane Packages and Modules from LuaRocks directly in your favorite IDE!",
  author = "Evandro C.",
  version = 0.1,

  onRegister = function(self)
    local pid 
    pid = luarocks("--version", function(out)
      luarocks_version = string.match(out, "luarocks ([%d%.]+)")
      if luarocks_version then
        print("luarocks version: ", luarocks_version)
        success()
      else
        failure()
      end
    end, nil, true)
    if not pid then
      luarocks_path = packages_path .. (ide.osname == "Windows" and "luarocks.exe" or "luarocks")
      pid = luarocks("--version", function(out)
        luarocks_version = string.match(out, "luarocks ([%d%.]+)")
        if luarocks_version then
          print("luarocks version: ", luarocks_version)
          success()
        else
          failure()
        end
      end, nil, true)
    end
    if not pid then
      failure()
    end
  end,
  
  onInterpreterLoad =  function(self, interpreter)
    if interpreter.fexepath then
      lua_dir = string.match(interpreter.fexepath(), "^(.+)([/\\])")
    end
    if interpreter.luaversion then
      lua_version = interpreter.luaversion
      if type(lua_version) == "number" then
        lua_version = lua_version + 0.01 -- fix 5.2999999999999998
      end
      lua_version = string.match(tostring(lua_version), "^(%d%.%d)")
    end
    if not luarocks_variables.LUA_INCDIR then
      luarocks("config variables.LUA_INCDIR", function(result)
        if result == "" or result:lower():match("error") or result == lua_dir:gsub("\"", "") then
          local major, minor = lua_version:match("^(%d)%.(%d)")
          local lua_h = io.open(lua_dir .. dir_separator .. "lua.h", "w")
          lua_h:write(string.format("LUA_VERSION_NUM	%s0%s", major, minor))
          lua_h:close()
          if result ~= lua_dir:gsub("\"", "") then
            luarocks("config variables.LUA_INCDIR \"" .. lua_dir:gsub("\"", "") .. "\"", function()
              print("variables.LUA_INCDIR: ", lua_dir)
            end, nil, true)
          end
        end
      end, nil , true)
    end
    print("lua interpreter: ", lua_dir)
    print("lua version: ", lua_version)
  end,
  
  onProjectLoad = function(self, project)
    project_path = project
    print("project_path: ", project_path)
  end

}