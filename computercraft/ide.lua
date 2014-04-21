
--
--  LuaIDE
--  Copyright GravityScore 2014
--  20 April 2014
--



--    Variables


local version = "2.0"

local w, h = term.getSize()

local theme = {
	["background"] = colors.gray,
	["highlightBackground"] = colors.lightGray,

	["accent"] = colors.lightBlue,
	["subtle"] = colors.cyan,

	["text"] = colors.white,
	["hiddenText"] = colors.lightGray,

	["error"] = colors.red,
}



--    Utilities


local function clear(bg, fg)
	term.setTextColor(fg)
	term.setBackgroundColor(bg)
	term.clear()
	term.setCursorPos(1, 1)
end


local function fill(x, y, width, height, bg)
	term.setBackgroundColor(bg)
	for i = y, y + height - 1 do
		term.setCursorPos(x, i)
		term.write(string.rep(" ", width))
	end
end


local function center(text)
	local x, y = term.getCursorPos()
	local w, h = term.getSize()
	local offset = (text:len() % 2 == 0 and 1 or 0)
	term.setCursorPos(math.floor(w / 2 - text:len() / 2) + offset, y)
	term.write(text)
	term.setCursorPos(1, y + 1)
end


local function centerSplit(text, width)
	local words = {}
	for word in text:gmatch("[^ \t]+") do
		table.insert(words, word)
	end

	local lines = {""}
	while lines[#lines]:len() < width do
		lines[#lines] = lines[#lines] .. words[1] .. " "
		table.remove(words, 1)

		if #words == 0 then
			break
		end

		if lines[#lines]:len() + words[1]:len() >= width then
			table.insert(lines, "")
		end
	end

	for _, line in pairs(lines) do
		center(line)
	end
end


local function localiseEvent(event, startY, startX)
	local localised = event

	if localised[1] == "mouse_click" then
		if startY then
			localised[4] = localised[4] - startY + 1
		end

		if startX then
			localised[3] = localised[3] - startX + 1
		end
	end

	return localised
end



--    Files


local File = {}
File.__index = File


function File.new(path)
	local self = setmetatable({}, File)
	self:setup(path)

	return self
end


function File:setup(path)
	self.path = path
end


function File:exists()
	return fs.exists(self.path) and not fs.isDir(self.path)
end


function File:get()
	if not self:exists() then
		return nil
	end

	local f = io.open(self.path, "r")
	local contents = f:read("*a")
	f:close()

	return contents
end


function File:getLines()
	if not self:exists() then
		return nil
	end

	local f = io.open(self.path, "r")
	local lines = {}
	local line = f:read("*l")

	while line do
		table.insert(lines, line)
		line = f:read("*l")
	end

	if #lines <= 0 then
		lines = {""}
	end

	return lines
end


function File:saveLines(lines)
	self:save(table.concat(lines, "\n"))
end


function File:save(contents)
	if fs.isDir(self.path) or fs.isReadOnly(self.path) then
		return false
	end

	local f = io.open(self.path, "w")
	f:write(contents)
	f:close()

	return true
end



--    Content


local Content = {}
Content.__index = Content


Content.startY = 3


function Content.new()
	local self = setmetatable({}, Content)
	self:setup()

	return self
end


function Content:setup()
	local height = h - Content.startY + 1
	self.win = window.create(term.native(), 1, Content.startY, w, height, false)
end


function Content:show()
	term.redirect(self.win)
	self.win.setVisible(true)
	self.win.redraw()
	self.win.restoreCursor()
end


function Content:hide()
	self.win.setVisible(false)
end


function Content:draw()
	self:show()
end


function Content:getName()
	return "test"
end


function Content:event(event)
	print(table.concat(event, " "))
end



--    Content Manager


local ContentManager = {}
ContentManager.__index = ContentManager


function ContentManager.new()
	local self = setmetatable({}, ContentManager)
	self:setup()

	return self
end


function ContentManager:setup()
	self.contents = {}
	self.current = 1
end


function ContentManager:create(index)
	if not index then
		index = #self.contents + 1
	end

	local content = Content.new()
	table.insert(self.contents, index, content)
end


function ContentManager:switch(index)
	if self.contents[index] then
		self:hideAll()
		self.current = index
		self.contents[self.current]:show()
	end
end


function ContentManager:close(index)
	if not index then
		index = self.current
	end

	if index <= #self.contents then
		table.remove(self.contents, index)

		if self.current >= index then
			local index = math.max(1, self.current - 1)
			self:switch(index)
		end
	end
end


function ContentManager:getTabNames()
	local names = {}
	for _, content in pairs(self.contents) do
		table.insert(names, content:getName())
	end

	return names
end


function ContentManager:show()
	self.contents[self.current]:show()
end


function ContentManager:hideAll()
	for i, _ in pairs(self.contents) do
		self.contents[i]:hide()
	end
end


function ContentManager:event(event)
	self.contents[self.current]:event(event)
end



--    Tab Bar

-- Delegate responds to:
--  getTabNames()


local TabBar = {}
TabBar.__index = TabBar


TabBar.y = 2

TabBar.maxTabWidth = 8
TabBar.maxTabs = 5


function TabBar.new(delegate)
	local self = setmetatable({}, TabBar)
	self:setup(delegate)

	return self
end


function TabBar.sanitiseName(name)
	local new = name:gsub("^%s*(.-)%s*$", "%1")
	if new:len() > TabBar.maxTabWidth then
		new = new:sub(1, TabBar.maxTabWidth):gsub("^%s*(.-)%s*$", "%1")
	end

	if new:sub(-1, -1) == "." then
		new = new:sub(1, -2):gsub("^%s*(.-)%s*$", "%1")
	end

	return new:gsub("^%s*(.-)%s*$", "%1")
end


function TabBar:setup(delegate)
	self.delegate = delegate
	self.win = window.create(term.native(), 1, TabBar.y, w, 1, false)
	self.current = 1
end


function TabBar:draw()
	local names = self.delegate:getTabNames()

	term.redirect(self.win)
	self.win.setVisible(true)

	clear(theme.background, theme.text)

	for i, name in pairs(names) do
		local actualName = TabBar.sanitiseName(name)

		if i == self.current then
			term.setTextColor(theme.text)
		else
			term.setTextColor(theme.hiddenText)
		end

		term.write(" " .. actualName)

		if i == self.current and #names > 1 then
			term.setTextColor(theme.error)
			term.write("x")
		else
			term.write(" ")
		end
	end

	if #names < TabBar.maxTabs then
		term.setTextColor(theme.hiddenText)
		term.write(" + ")
	end
end


function TabBar:determineClickedTab(x, y)
	local index, action = nil, nil

	if y == 1 then
		local names = self.delegate:getTabNames()
		local currentX = 2

		for i, name in pairs(names) do
			local actualName = TabBar.sanitiseName(name)
			local endX = currentX + actualName:len() - 1

			if x >= currentX and x <= endX then
				index = i
				action = "switch"
			elseif x == endX + 1 and i == self.current and #names > 1 then
				index = i
				action = "close"
			end

			currentX = endX + 3
		end

		if x == currentX then
			action = "create"
		end
	end

	return action, index
end


function TabBar:click(button, x, y)
	local action, index = self:determineClickedTab(x, y)

	local cancel = false
	if y == 1 then
		cancel = true
	end

	if action then
		local names = self.delegate:getTabNames()

		if action == "switch" then
			self.current = index
			os.queueEvent("tab_bar_switch", index)
		elseif action == "create" then
			os.queueEvent("tab_bar_create")
		elseif action == "close" and #names > 1 then
			os.queueEvent("tab_bar_close", index)
		end
	end

	return cancel
end


function TabBar:event(event)
	local cancel = false

	if event[1] == "mouse_click" then
		cancel = self:click(event[2], event[3], event[4])
	end

	return cancel
end



--    Content Manager and Tab Bar Link


local ContentTabLink = {}
ContentTabLink.__index = ContentTabLink


function ContentTabLink.new()
	local self = setmetatable({}, ContentTabLink)
	self:setup()

	return self
end


function ContentTabLink:setup()
	self.contentManager = ContentManager.new()
	self.tabBar = TabBar.new(self.contentManager)

	local index = #self.contentManager.contents + 1
	self.contentManager:create(index)
	self.contentManager:switch(index)
end


function ContentTabLink:draw()
	self.tabBar:draw()
	self.contentManager.contents[self.contentManager.current]:draw()
end


function ContentTabLink:getTabBarAction(event)
	local action = nil

	if event:find("tab_bar_") == 1 then
		action = event:gsub("tab_bar_", "")
	end

	return action
end


function ContentTabLink:tabBarAction(action, index)
	if action == "switch" then
		self.contentManager:switch(index)
	elseif action == "close" then
		self.contentManager:close()
	elseif action == "create" then
		self.contentManager:create()
	end
end


function ContentTabLink:event(event)
	local cancel = false

	local action = self:getTabBarAction(event[1])
	if action then
		self:tabBarAction(action, event[2])
		self.tabBar:draw()
		cancel = true
	end

	if not cancel then
		cancel = self.tabBar:event(localiseEvent(event, TabBar.y))
	end

	if not cancel then
		cancel = self.contentManager:event(localiseEvent(event, Content.startY))
	end

	return cancel
end



--    Shortcut Handler


local ShortcutManager = {}
ShortcutManager.__index = ShortcutManager


function ShortcutManager.new()
	local self = setmetatable({}, ShortcutManager)
	self:setup()

	return self
end


function ShortcutManager:setup()
	self.timeout = 0.4
	self.shiftPressed = false
	self.controlPressed = false

	self.shiftTimerID = -1
	self.controlTimerID = -1
end


function ShortcutManager:key(key)
	if key == 42 or key == 54 then
		self.shiftPressed = true
		self.shiftTimerID = os.startTimer(self.timeout)
	elseif key == 29 or key == 157 or key == 219 or key == 220 then
		self.controlPressed = true
		self.controlTimerID = os.startTimer(self.timeout)
	end
end


function ShortcutManager:char(char)
	if self.controlPressed and self.shiftPressed then
		os.queueEvent("shortcut", "ctrl shift", char:lower())
	elseif self.controlPressed then
		os.queueEvent("shortcut", "ctrl", char:lower())
	end
end


function ShortcutManager:timer(id)
	if id == self.shiftTimerID then
		self.shiftPressed = false
		self.shiftTimerID = -1
	elseif id == self.controlTimerID then
		self.controlPressed = false
		self.controlTimerID = -1
	end
end


function ShortcutManager:event(event)
	if event[1] == "key" then
		self:key(event[2])
	elseif event[1] == "timer" then
		self:timer(event[2])
	elseif event[1] == "char" then
		self:char(event[2])
	end
end



--    Menu Bar Item


local MenuItem = {}
MenuItem.__index = MenuItem


function MenuItem.new(name, subitems, shortcuts)
	local self = setmetatable({}, MenuItem)
	self:setup(name, subitems, shortcuts)

	return self
end


function MenuItem.displayShortcut(shortcut)
	return shortcut:gsub("ctrl ", "^"):gsub("shift ", "-"):upper()
end


function MenuItem.appendShortcut(name, shortcut, width)
	local actual = name

	if shortcut:len() > 0 then
		local cut = MenuItem.displayShortcut(shortcut)
		actual = name .. string.rep(" ", (width - name:len() - cut:len()) + 1) .. cut
	end

	return actual
end


function MenuItem:setup(name, subitems, shortcuts)
	self.name = name
	self.subitems = subitems
	self.shortcuts = shortcuts
end


function MenuItem:setupWindow(x, y)
	local shortcutWidth = 0
	for _, shortcut in pairs(self.shortcuts) do
		local actual = MenuItem.displayShortcut(shortcut):len()
		if actual > shortcutWidth then
			shortcutWidth = actual
		end
	end

	local width = 2
	for i, name in pairs(self.subitems) do
		local itemWidth = name:len() + shortcutWidth
		if itemWidth > width then
			width = itemWidth
		end
	end

	self.x = x
	self.y = y
	self.width = width + 3
	self.height = #self.subitems + 2
	self.win = window.create(term.native(), x, y, self.width, self.height, false)
end


function MenuItem:determineClickedItem(x, y)
	local index = nil

	if x >= 1 and x <= self.width and y >= 2 and y <= self.height - 1 then
		index = y - 1
	end

	return index
end


function MenuItem:draw(highlightIndex)
	term.redirect(self.win)
	clear(theme.background, theme.text)

	for i, name in pairs(self.subitems) do
		term.setCursorPos(2, i + 1)

		if i == highlightIndex then
			term.setBackgroundColor(theme.highlightBackground)
			term.clearLine()
		else
			term.setBackgroundColor(theme.background)
		end

		local display = MenuItem.appendShortcut(name, self.shortcuts[i], self.width - 3)
		term.write(display)
	end
end


function MenuItem:highlightItem(index)
	self:draw(index)
	sleep(0.1)
	self:draw()
end


function MenuItem:close()
	self.win.setVisible(false)
end


function MenuItem:open()
	self.win.setVisible(true)
	self:draw()
end



--    Menu Bar


local MenuBar = {}
MenuBar.__index = MenuBar


MenuBar.y = 1


function MenuBar.new(items)
	local self = setmetatable({}, MenuBar)
	self:setup(items)

	return self
end


function MenuBar:setup(items)
	self.items = items
	self.win = window.create(term.native(), 1, MenuBar.y, w, 1, false)

	self.isMenuOpen = false
	self.openMenuIndex = nil

	local currentX = 2
	for i, item in pairs(self.items) do
		self.items[i]:setupWindow(currentX - 1, MenuBar.y + 1)
		currentX = currentX + item.name:len() + 2
	end
end


function MenuBar:draw(highlightIndex)
	term.redirect(self.win)
	self.win.setVisible(true)

	clear(theme.background, theme.text)

	for i, item in pairs(self.items) do
		if i == highlightIndex then
			term.setBackgroundColor(theme.highlightBackground)
		else
			term.setBackgroundColor(theme.background)
		end

		term.write(" " .. item.name .. " ")
	end

	if self.isMenuOpen then
		self.items[self.openMenuIndex]:draw()
	end
end


function MenuBar:determineClickedMenu(x, y)
	local index = nil

	if y == 1 then
		local currentX = 2
		for i, item in pairs(self.items) do
			local endX = currentX + item.name:len() - 1
			if x >= currentX and x <= endX then
				index = i
			end

			currentX = endX + 3
		end
	end

	return index
end


function MenuBar:highlightMenu(index)
	self:draw(index)
	sleep(0.1)
	self:draw()
end


function MenuBar:openMenu(index)
	self.isMenuOpen = true
	self.openMenuIndex = index

	self.items[index]:open()
	self:highlightMenu(index)
end


function MenuBar:closeAllMenus()
	self.isMenuOpen = false
	self.openMenuIndex = nil

	for i, item in pairs(self.items) do
		item:close()
	end
end


function MenuBar:click(button, x, y)
	local cancel = false

	if self.isMenuOpen then
		local item = self.items[self.openMenuIndex]

		local localised = localiseEvent({"mouse_click", button, x, y}, item.y, item.x)
		local index = item:determineClickedItem(localised[3], localised[4])
		if index then
			item:highlightItem(index)
			os.queueEvent("menu_bar_action", self.openMenuIndex, index)
		end

		if index or x < item.x or x > item.x + item.width - 1 or
					y < item.y or y > item.y + item.height - 1 then
			self:closeAllMenus()
		end

		self:draw()
		cancel = true
	else
		local index = self:determineClickedMenu(x, y)
		if index then
			self:openMenu(index)
		end

		if y == 1 then
			cancel = true
		end
	end

	return cancel
end


function MenuBar:shortcut(shortcut)
	for menuI, menu in pairs(self.items) do
		for itemI, test in pairs(menu.shortcuts) do
			if test == shortcut then
				os.queueEvent("menu_bar_action", menuI, itemI)
			end
		end
	end
end


function MenuBar:event(event)
	local cancel = false

	if event[1] == "mouse_click" then
		cancel = self:click(event[2], event[3], event[4])
	elseif event[1] == "shortcut" then
		cancel = self:shortcut(event[2] .. " " .. event[3])
	end

	return cancel
end



--    App


local App = {}
App.__index = App


function App.new()
	local self = setmetatable({}, App)
	self:setup()

	return self
end


function App:getMenuItems()
	return {
		MenuItem.new("File", {
			"About",
			"New",
			"Open",
			"Exit IDE",
		}, {
			"",
			"ctrl n",
			"ctrl o",
			"ctrl q",
		}),

		MenuItem.new("Edit", {
			"Copy",
			"Cut",
			"Paste",

			"Copy Line",
			"Cut Line",
			"Paste Line",

			"Go to line",
		}, {
			"ctrl c",
			"ctrl x",
			"ctrl v",

			"",
			"",
			"",

			"",
		}),

		MenuItem.new("Run", {
			"Run",
			"Run with args"
		}, {
			"ctrl r",
			"ctrl shift r"
		}),
	}
end


function App:setup()
	self.manager = ContentTabLink.new()
	self.menuBar = MenuBar.new(self:getMenuItems())
	self.shortcutManager = ShortcutManager.new()
end


function App:draw()
	self.menuBar:draw()
	self.manager:draw()
end


function App:event(event)
	local cancel = false

	self.shortcutManager:event(event)

	if not cancel then
		cancel = self.menuBar:event(localiseEvent(event, MenuBar.y))
	end

	if not cancel then
		cancel = self.manager:event(event)
	end
end


function App:main()
	term.redirect(term.native())
	clear(theme.background, theme.text)
	self:draw()

	while true do
		local event = {os.pullEvent()}
		self:draw()
		self:event(event)
	end
end



--    Error


local Error = {}
Error.__index = Error


function Error.new(msg)
	local self = setmetatable({}, Error)
	self:setup(msg)

	return self
end


function Error:setup(msg)
	self.msg = msg
end


function Error:shouldThrow()
	return self.msg and not self.msg:lower():find("terminate")
end


function Error:displayCrash()
	clear(theme.background, theme.text)

	fill(1, 3, w, 3, theme.accent)
	term.setCursorPos(1, 4)
	center("LuaIDE has crashed!")

	term.setBackgroundColor(theme.background)
	term.setCursorPos(1, 8)
	centerSplit(self.msg, w - 4)
	print("\n")
	center("Please report this error to")
	center("GravityScore.")
	print("")
	center("Press any key to exit.")

	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end



--    Main


local main = function()
	local app = App.new()
	app:main()
end


local original = term.current()
local _, msg = pcall(main)
term.redirect(original)

local err = Error.new(msg)
if err:shouldThrow() then
	err:displayCrash()
end


clear(colors.black, colors.white)
center("Thanks for using LuaIDE " .. version)
center("Made by GravityScore")
print("")
