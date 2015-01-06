
--
--  Menu Bar
--

MenuBar = {}
MenuBar.__index = MenuBar

--- The y location of the menu bar.
MenuBar.y = 1

--- The duration in seconds to wait when flashing a menu item.
MenuBar.flashDuration = 0.1

--- Items contained in the menu bar.
MenuBar.items = {
	{
		["name"] = "File",
		["contents"] = {
			"About",
			"New",
			"Open",
			"Save",
			"Save as",
			"Settings",
			"Quit",
		},
	},
	{
		["name"] = "Edit",
		["contents"] = {
			"Copy line",
			"Cut line",
			"Paste line",
			"Delete line",
			"Comment line",
		},
	},
	{
		["name"] = "Tools",
		["contents"] = {
			"Go to line",
			"Reindent",
		},
	},
}


--- Create a new menu bar.
function MenuBar.new(...)
	local self = setmetatable({}, MenuBar)
	self:setup(...)
	return self
end


function MenuBar:setup()
	local w = term.getSize()
	self.win = window.create(term.native(), 1, MenuBar.y, w, 1)
	self.flash = nil
	self.focus = nil
end


--- Draws a menu item.
function MenuBar:drawItem(item, flash)
	term.setBackgroundColor(Theme["menu dropdown background"])
	term.clear()

	-- Render all the items
	for i, text in pairs(item.contents) do
		if i == flash then
			term.setTextColor(Theme["menu dropdown flash text"])
			term.setBackgroundColor(Theme["menu dropdown flash background"])
		else
			term.setTextColor(Theme["menu dropdown text"])
			term.setBackgroundColor(Theme["menu dropdown background"])
		end

		term.setCursorPos(2, i + 1)
		term.clearLine()
		term.write(text)
	end
end


--- Flashes an item when clicked, then draws it as focused.
function MenuBar:drawFlash(index)
	self.flash = index
	self:draw()
	sleep(MenuBar.flashDuration)
	self.flash = nil
	self.focus = index
	self:draw()
end


--- Returns the width of the window to create for a particular item index.
function MenuBar:itemWidth(index)
	local item = self.items[index]
	local width = -1
	for _, text in pairs(item.contents) do
		if text:len() > width then
			width = text:len()
		end
	end
	width = width + 2

	return width
end


--- Opens a menu item, blocking the event loop until it's closed.
function MenuBar:open(index)
	-- Flash the menu item
	term.setCursorBlink(false)
	self:drawFlash(index)

	-- Window location
	local item = self.items[index]
	local x = self:itemLocation(index)
	local y = MenuBar.y + 1
	local height = #item.contents + 2
	local width = self:itemWidth(index)

	-- Create the window
	local win = window.create(term.native(), x, y, width, height)
	term.redirect(win)
	self:drawItem(item)

	-- Wait for a click
	while true do
		local event = {os.pullEventRaw()}

		if event[1] == "terminate" then
			os.queueEvent("exit")
			break
		elseif event[1] == "mouse_click" then
			local cx = event[3]
			local cy = event[4]

			if cy >= y and cy < y + height and cx >= x and cx < x + width then
				-- Clicked on the window somewhere
				if cy >= y + 1 and cy < y + height - 1 then
					-- Clicked on an item
					local index = cy - y
					self:drawItem(item, index)
					sleep(MenuBar.flashDuration)

					local text = item.contents[index]
					os.queueEvent("menu item trigger", text)
					break
				end
			else
				-- Close the menu item
				os.queueEvent("menu item close")
				break
			end
		end
	end

	self.focus = nil
	win.setVisible(false)
end


--- Render the menu bar
--- Redirects the terminal to the menu bar's window
function MenuBar:draw()
	term.redirect(self.win)
	term.setBackgroundColor(Theme["menu bar background"])
	term.setTextColor(Theme["menu bar text"])
	term.clear()
	term.setCursorPos(2, 1)

	for i, item in pairs(MenuBar.items) do
		if i == self.focus then
			term.setTextColor(Theme["menu bar text focused"])
			term.setBackgroundColor(Theme["menu bar background focused"])
		elseif i == self.flash then
			term.setTextColor(Theme["menu bar flash text"])
			term.setBackgroundColor(Theme["menu bar flash background"])
		else
			term.setTextColor(Theme["menu bar text"])
			term.setBackgroundColor(Theme["menu bar background"])
		end

		term.write(" " .. item.name .. " ")
	end
end


--- Returns the min and max x location for a particular menu item.
--- Returns nil if the index isn't found.
function MenuBar:itemLocation(index)
	local minX = 2
	local maxX = -1

	for i, item in pairs(MenuBar.items) do
		maxX = minX + item.name:len() + 1
		if index == i then
			return minX, maxX
		end
		minX = maxX + 1
	end

	return nil
end


--- Called when a click event is received.
function MenuBar:click(x, y)
	if y == 1 then
		-- Determine the clicked item
		local minX = 2
		local maxX = -1
		local index = -1

		for i, item in pairs(MenuBar.items) do
			maxX = minX + item.name:len() + 1
			if x >= minX and x <= maxX then
				index = i
				break
			end
			minX = maxX + 1
		end

		if index ~= -1 then
			self:open(index)
		end

		return true
	end
end


--- Called when an event is triggered on the menu bar
function MenuBar:event(event)
	if event[1] == "mouse_click" then
		return self:click(event[3], event[4])
	end

	return false
end
