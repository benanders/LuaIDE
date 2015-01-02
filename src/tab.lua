
--
--  Content Manager
--

--- Manages a collection of content windows, one for each tab.
ContentManager = {}
ContentManager.__index = ContentManager


--- Creates a new content manager.
function ContentManager.new(...)
	local self = setmetatable({}, ContentManager)
	self:setup(...)
	return self
end


function ContentManager:setup()
	self.contents = {}
	self.current = 1
end


--- Creates a new content window at the given index.
function ContentManager:create(index)
	if not index then
		index = #self.contents + 1
	end

	local content = Content.new()
	table.insert(self.contents, index, content)
end


--- Switches to the content window at `index`.
function ContentManager:switch(index)
	if self.contents[index] then
		self:hideAll()
		self.current = index
		self.contents[self.current]:show()
	end
end


--- Deletes the content window at the given index.
function ContentManager:close(index)
	if not index then
		index = self.current
	end

	if index <= #self.contents then
		table.remove(self.contents, index)

		if index <= self.current then
			local newIndex = math.max(1, self.current - 1)
			self.current = newIndex

			local name = self.contents[self.current]:name()
			os.queueEvent("tab_bar_switch", newIndex, name)
		end
	end
end


--- Returns a list of names for each content window, in order.
function ContentManager:getTabNames()
	local names = {}
	for _, content in pairs(self.contents) do
		table.insert(names, content:name())
	end

	return names
end


--- Shows the current content window.
function ContentManager:show()
	self.contents[self.current]:show()
end


--- Hides all content windows.
function ContentManager:hideAll()
	for i, _ in pairs(self.contents) do
		self.contents[i]:hide()
	end
end


--- Triggers the given event on the current content window.
function ContentManager:event(event)
	self.contents[self.current]:event(event)
end



--
--  Tab Bar
--

-- Delegate must respond to:
--  getTabNames()

--- The Tab Bar GUI element.
TabBar = {}
TabBar.__index = TabBar

--- The y location of the tab bar.
TabBar.y = 2

--- The maximum number of tabs.
TabBar.maxTabs = 4

--- The maximum length of a tab's name.
local w, h = term.getSize()
TabBar.maxTabWidth = math.floor(w / TabBar.maxTabs)


--- Creates a new tab bar.
function TabBar.new(...)
	local self = setmetatable({}, TabBar)
	self:setup(...)
	return self
end


--- Returns a sanitised tab bar name.
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
	local w = term.getSize()

	self.delegate = delegate
	self.win = window.create(term.native(), 1, TabBar.y, w, 1, false)
	self.current = 1
end


--- Renders the tab bar.
function TabBar:draw()
	local names = self.delegate:getTabNames()

	term.redirect(self.win)
	self.win.setVisible(true)

	Util.clear(Theme["tab bar background"], Theme["tab bar text focused"])

	for i, name in pairs(names) do
		local actualName = TabBar.sanitiseName(name)

		term.setBackgroundColor(Theme["tab bar background blurred"])
		term.setTextColor(Theme["tab bar text blurred"])
		term.write(" ")

		if i == self.current then
			term.setBackgroundColor(Theme["tab bar background focused"])
			term.setTextColor(Theme["tab bar text focused"])
		end

		term.write(actualName)

		if i == self.current and #names > 1 then
			term.setBackgroundColor(Theme["tab bar background close"])
			term.setTextColor(Theme["tab bar text close"])
			term.write("x")
		else
			term.write(" ")
		end
	end

	if #names < TabBar.maxTabs then
		term.setBackgroundColor(Theme["tab bar background blurred"])
		term.setTextColor(Theme["tab bar text blurred"])
		term.write(" + ")
	end
end


--- Makes the tab at the given index active.
function TabBar:switch(index)
	self.current = index
end


--- Returns the appropriate action for the tab bar if
--- clicked at the given location.
--- The first argument `action` is either "switch", "close", or "create"
--- Switch and close return an index that indicates which tab to switch
--- to or close.
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

		if x == currentX and #names < TabBar.maxTabs then
			action = "create"
		end
	end

	return action, index
end


--- Called when the mouse is clicked.
function TabBar:click(button, x, y)
	local action, index = self:determineClickedTab(x, y)

	local cancel = false
	if y == 1 then
		cancel = true
	end

	if action then
		local names = self.delegate:getTabNames()

		if action == "switch" then
			os.queueEvent("tab_bar_switch", index, names[index])
		elseif action == "create" then
			os.queueEvent("tab_bar_create")
		elseif action == "close" and #names > 1 then
			os.queueEvent("tab_bar_close", index)
		end
	end

	return cancel
end


--- Called when an event occurs.
function TabBar:event(event)
	local cancel = false

	if event[1] == "mouse_click" then
		cancel = self:click(event[2], event[3], event[4])
	end

	return cancel
end



--
--  Content Manager and Tab Bar Link
--

--- Synchronises the tab bar and content manager to maintain
--- a common current tab.
ContentTabLink = {}
ContentTabLink.__index = ContentTabLink


--- Copies from source into destination.
local function copyTable(source, destination)
	for key, value in pairs(source) do
		destination[key] = value
	end
end


--- Converts a mouse event's y coordinate to be relative to the
--- given starting y.
local function localiseEvent(event, startY)
	local localised = {}
	copyTable(event, localised)

	local isMouseClick = localised[1] == "mouse_click"
	local isMouseDrag = localised[1] == "mouse_drag"
	local isMouseScroll = localised[1] == "mouse_scroll"
	if isMouseClick or isMouseDrag or isMouseScroll then
		localised[4] = localised[4] - startY + 1
	end

	return localised
end


--- Creates a new tab bar and content manager link.
function ContentTabLink.new(...)
	local self = setmetatable({}, ContentTabLink)
	self:setup(...)
	return self
end


function ContentTabLink:setup()
	self.contentManager = ContentManager.new()
	self.tabBar = TabBar.new(self.contentManager)

	local index = #self.contentManager.contents + 1
	self.contentManager:create(index)

	local name = self.contentManager.contents[index]:name()
	os.queueEvent("tab_bar_switch", index, name)
end


--- Restore the cursor on the current editor
function ContentTabLink:restoreCursor()
	return self.contentManager.contents[self.contentManager.current]:restoreCursor()
end


--- Renders both the tab bar and current content window.
function ContentTabLink:draw()
	self.tabBar:draw()
	self.contentManager.contents[self.contentManager.current]:draw()
end


--- Switches the current tab to the given index.
function ContentTabLink:switch(index)
	self.contentManager:switch(index)
	self.tabBar:switch(index)
	self.tabBar:draw()
end


--- Closes the tab at the given index.
function ContentTabLink:close(index)
	self.contentManager:close()
	self.tabBar:draw()
end


--- Creates a new tab at the end of the tab list.
function ContentTabLink:create()
	self.contentManager:create()
	self.tabBar:draw()
end


--- Returns true if the event should be passed to the content window.
function ContentTabLink:isEventValid(event)
	local isMouseClick = event[1] == "mouse_click"
	local isMouseDrag = event[1] == "mouse_drag"
	local isMouseScroll = event[1] == "mouse_scroll"
	if isMouseClick or isMouseDrag or isMouseScroll then
		if event[3] < 1 or event[4] < 1 then
			return false
		end
	end

	return true
end


--- Called when an event occurs.
function ContentTabLink:event(event)
	if event[1] == "tab_bar_switch" then
		self:switch(event[2])
	elseif event[1] == "tab_bar_close" then
		self:close(event[2])
	elseif event[1] == "tab_bar_create" then
		self:create()
	else
		-- Trigger an event on the current content window
		local cancel = false

		local tabEvent = localiseEvent(event, TabBar.y)
		if not cancel and self:isEventValid(tabEvent) then
			cancel = self.tabBar:event(tabEvent)
		end

		local contentEvent = localiseEvent(event, Content.startY)
		if not cancel and self:isEventValid(contentEvent) then
			cancel = self.contentManager:event(contentEvent)
		end

		return cancel
	end

	return false
end
