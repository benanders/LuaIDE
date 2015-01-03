
--
--  Menu Bar
--

MenuBar = {}
MenuBar.__index = MenuBar

--- The y location of the menu bar.
MenuBar.y = 1

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
	self.focused = nil
end


--- Opens a menu item, blocking the event loop until it's closed.
function MenuBar:open(index)
	self.focused = index
	self:draw()

	-- Get the maximum width of all the items to display
	local item = self.items[index]
	local width = -1
	for _, text in pairs(item.contents) do
		if text:len() > width then
			width = text:len()
		end
	end
	width = width + 2

	-- Other location metrics
	local x = self:itemLocation(index)
	local y = MenuBar.y + 1
	local height = #item.contents + 2

	-- Create the window
	local win = window.create(term.native(), x, y, width, height)
	term.redirect(win)
	term.setTextColor(Theme["menu dropdown text"])
	term.setBackgroundColor(Theme["menu dropdown background"])
	term.clear()

	-- Render all the items
	for i, text in pairs(item.contents) do
		term.setCursorPos(2, i + 1)
		term.write(text)
	end

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
					local text = item.contents[cy - y]
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

	self.focused = nil
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
		if i == self.focused then
			term.setBackgroundColor(Theme["menu bar background focused"])
			term.setTextColor(Theme["menu bar text focused"])
		else
			term.setBackgroundColor(Theme["menu bar background"])
			term.setTextColor(Theme["menu bar text"])
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
