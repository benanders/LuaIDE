
--
--  Panel
--

--- A simple text panel to display some text, that pops up with a close button
Panel = {}
Panel.__index = Panel


--- Create a new panel
function Panel.new(...)
	local self = setmetatable({}, Panel)
	self:setup(...)
	return self
end


--- Create an error panel.
function Panel.error(...)
	local panel = Panel.new()
	panel:center(...)
	panel:show()
end


function Panel:setup()
	self.lines = {}
	self.width = 0
end


function Panel:line(position, ...)
	local items = {...}
	if #items > 1 then
		for _, item in pairs(items) do
			self:line(position, item)
		end
	else
		local line = items[1]
		if line:len() + 4 > self.width then
			self.width = line:len() + 4
		end

		table.insert(self.lines, {["text"] = line, ["position"] = position})
	end
end


function Panel:center(...)
	self:line("center", ...)
end


function Panel:left(...)
	self:line("left", ...)
end


function Panel:right(...)
	self:line("right", ...)
end


function Panel:empty()
	self:line("left", "")
end


function Panel:show()
	self.height = #self.lines + 2

	local w, h = term.native().getSize()
	local x = math.floor(w / 2 - self.width / 2) + 1
	local y = math.floor(h / 2 - self.height / 2)
	local win = window.create(term.native(), x, y, self.width, self.height)

	term.redirect(win)
	term.setCursorBlink(false)
	term.setBackgroundColor(Theme["panel background"])
	term.clear()

	-- Close button
	term.setCursorPos(1, 1)
	term.setTextColor(Theme["panel close text"])
	term.setBackgroundColor(Theme["panel close background"])
	term.write("x")

	-- Lines
	term.setTextColor(Theme["panel text"])
	term.setBackgroundColor(Theme["panel background"])

	for i, line in pairs(self.lines) do
		local x = 3
		if line.position == "center" then
			x = math.floor(self.width / 2 - line.text:len() / 2) + 1
		elseif line.position == "right" then
			x = self.width - line.text:len() - 1
		end

		term.setCursorPos(x, i + 1)
		term.write(line.text)
	end

	-- Wait for a click on the close button or outside the panel
	while true do
		local event = {os.pullEventRaw()}

		if event[1] == "terminate" then
			os.queueEvent("exit")
			break
		elseif event[1] == "mouse_click" then
			local cx = event[3]
			local cy = event[4]
			if cx == x and cy == y then
				break
			else
				local horizontal = cx < x or cx >= x + self.width
				local vertical = cy < y or cy >= y + self.height
				if horizontal or vertical then
					break
				end
			end
		end
	end
end
