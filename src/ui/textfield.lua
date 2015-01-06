
--
--  Text Field
--

--- An editable text field.
TextField = {}
TextField.__index = TextField


--- Create a new text field.
function TextField.new(...)
	local self = setmetatable({}, TextField)
	self:setup(...)
	return self
end


function TextField:setup(x, y, textColor, backgroundColor)
	self.x = x
	self.y = y
	self.backgroundColor = backgroundColor
	self.textColor = textColor
	self.text = ""

	self.scroll = 0
	self.cursor = 1

	local w, h = term.native().getSize()
	self.width = w - self.x
	self.maximumLength = -1
	self.placeholderText = nil
	self.placeholderColor = colors.black
	self.eventCallback = nil
end


--- Specify negative values as an offset from the right computer edge.
function TextField:setWidth(w)
	if w < 1 then
		local width = term.native().getSize()
		w = width + w
	end

	self.width = w
end


function TextField:setLength(length)
	self.maximumLength = length
end


function TextField:setPlaceholder(text, color)
	self.placeholderText = text
	self.placeholderColor = color
end


function TextField:setCallback(callback)
	self.eventCallback = callback
end


function TextField:draw()
	term.setBackgroundColor(self.backgroundColor)
	term.setTextColor(self.textColor)

	term.setCursorPos(self.x, self.y)
	term.write(string.rep(" ", self.width))
	term.setCursorPos(self.x, self.y)
	term.write(self.text:sub(self.scroll + 1, self.scroll + self.width))

	if self.text:len() == 0 and self.placeholderText then
		term.setTextColor(self.placeholderColor)
		term.write(self.placeholderText:sub(1, self.width))
	end
end


function TextField:left()
	if self.cursor > 1 then
		self.cursor = self.cursor - 1
	elseif self.scroll > 0 then
		self.scroll = self.scroll - 1
	end
end


function TextField:right()
	if self.text:len() < self.width then
		if self.cursor <= self.text:len() then
			self.cursor = self.cursor + 1
		end
	else
		if self.cursor < self.width then
			self.cursor = self.cursor + 1
		elseif self.scroll + self.cursor < self.text:len() + 1 then
			self.scroll = self.scroll + 1
		end
	end
end


function TextField:backspace()
	if self.cursor + self.scroll > 1 then
		local before = self.text:sub(1, self.cursor + self.scroll - 2)
		local after = self.text:sub(self.cursor + self.scroll)
		self.text = before .. after
	end

	self:left()
	if self.cursor == 1 and self.scroll > 0 then
		self.cursor = 2
		self.scroll = self.scroll - 1
	end
end


function TextField:key(key)
	if key == keys.enter then
		return true
	elseif key == keys.left then
		self:left()
	elseif key == keys.right then
		self:right()
	elseif key == keys.backspace then
		self:backspace()
	end
end


function TextField:char(character)
	local before = self.text:sub(1, self.cursor + self.scroll)
	local after = self.text:sub(self.cursor + self.scroll + 1)
	self.text = before .. character .. after
	self:right()
end


function TextField:click(x, y)
	if y == self.y and x >= self.x and x < self.x + self.width then
		local click = x - self.x + 1
		local textWidth = self.text:len() - self.scroll + 1
		self.cursor = math.min(click, textWidth)
	end
end


function TextField:moveToEnd()
	if self.text:len() < self.width then
		-- End on screen
		self.scroll = 0
		self.cursor = self.text:len() + 1
	else
		-- Off screen
		self.scroll = self.text:len() - self.width + 1
		self.cursor = self.width
	end
end


function TextField:show()
	local path = nil

	while true do
		term.setCursorBlink(true)
		self:draw()

		term.setTextColor(self.textColor)
		term.setCursorPos(self.x + self.cursor - 1, self.y)

		local event = {os.pullEventRaw()}

		if event[1] == "terminate" then
			os.queueEvent("exit")
			break
		elseif event[1] == "key" then
			if self:key(event[2]) then
				path = self.text
				break
			end
		elseif event[1] == "char" then
			self:char(event[2])
		elseif event[1] == "mouse_click" or event[1] == "mouse_drag" then
			self:click(event[3], event[4] - self.y + 1)
		end

		if self.eventCallback then
			local newText = self.eventCallback(event)
			if newText then
				self.text = newText
				self:moveToEnd()
			end
		end
	end

	term.setCursorBlink(false)
	return path
end
