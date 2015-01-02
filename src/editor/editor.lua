
--
--  Editor
--

--- An editor.
--- Controls the state of an editor for a single file.
Editor = {}
Editor.__index = Editor


--- Create a new editor from the lines of text to edit, and its size.
function Editor.new(...)
	local self = setmetatable({}, Editor)
	self:setup(...)
	return self
end


function Editor:setup(lines, width, height)
	self.lines = lines

	--- The editor size.
	self.width = width
	self.height = height

	--- The position of the cursor relative to the top left
	--- of the editor window. Starting at (1, 1).
	self.cursor = {}
	self.cursor.x = 1
	self.cursor.y = 1
	self.cursor.visible = true

	--- The scroll amount on each axis. Starting at (0, 0).
	self.scroll = {}
	self.scroll.x = 0
	self.scroll.y = 0

	--- State variables
	self.dirtyData = nil
end


--- Move the cursor to an absolute position within the document.
--- Start at (1, 1).
function Editor:moveCursorTo(x, y)
	local width = self:textWidth()

	-- Y axis
	if y > self.scroll.y and y <= self.scroll.y + self.height then
		-- Within our current view
		local previousY = self.cursor.y
		self.cursor.y = y - self.scroll.y
		self:updateGutter(previousY)
	elseif y <= self.scroll.y then
		-- Above us
		self.cursor.y = 1
		self.scroll.y = y - 1
		self:setDirty("full")
	else
		-- Below us
		self.cursor.y = self.height
		self.scroll.y = y - self.height
		self:setDirty("full")
	end

	-- X axis
	local length = self:currentLineLength()
	if x > self.scroll.x and x <= self.scroll.x + width then
		self.cursor.x = x - self.scroll.x

		-- Handle the case where the word is 1 cell to the left of the screen.
		if length > 0 and self.cursor.x == 1 and length - self.scroll.x <= 0 then
			if self.scroll.x > 0 then
				self.cursor.x = 2
				self.scroll.x = self.scroll.x - 1
				self:setDirty("full")
			end
		end
	elseif x <= self.scroll.x then
		-- To the left of us
		if length > 0 then
			self.cursor.x = 2
			self.scroll.x = x - 2
		else
			self.cursor.x = 1
			self.scroll.x = x - 1
		end

		self:setDirty("full")
	else
		-- To the right of us
		self.cursor.x = width
		self.scroll.x = x - width
		self:setDirty("full")
	end
end


--- Move the cursor to a position relative to the top left of
--- the editor window.
--- Start at (1, 1).
function Editor:moveCursorToRelative(x, y)
	local y = math.min(y + self.scroll.y, #self.lines)
	local length = self.lines[y]:len()
	local x = math.min(x + self.scroll.x, length + 1)
	self:moveCursorTo(x, y)
end


--- Move the cursor to the end of the line if it is off the edge of the screen.
function Editor:moveCursorToEndIfOffScreen()
	local length = self:currentLineLength()
	if length - self.scroll.x <= 0 then
		if length > 0 then
			self.cursor.x = 2
			self.scroll.x = length - 1
		else
			self.cursor.x = 1
			self.scroll.x = 0
		end

		self:setDirty("full")
	end
end


--- Move the cursor up a single line.
function Editor:moveCursorUp()
	if self.cursor.y > 1 then
		-- Still on screen, no need to scroll
		local previousY = self.cursor.y
		self.cursor.y = self.cursor.y - 1
		self:updateGutter(previousY)
	else
		-- Need to scroll
		if self.scroll.y > 0 then
			self.scroll.y = self.scroll.y - 1
			self:setDirty("full")
		end
	end

	self:moveCursorToEndIfOffScreen()
end


--- Move the cursor down a single line.
function Editor:moveCursorDown()
	if self.cursor.y < math.min(self.height, #self.lines) then
		-- Still on screen
		local previousY = self.cursor.y
		self.cursor.y = self.cursor.y + 1
		self:updateGutter(previousY)
	else
		-- Need to scroll
		if self:canScrollDown() then
			self.scroll.y = self.scroll.y + 1
			self:setDirty("full")
		end
	end

	self:moveCursorToEndIfOffScreen()
end


--- Move the cursor left one character.
function Editor:moveCursorLeft()
	self:resetCursorRestoration()

	if self.cursor.x > 1 then
		-- Still on screen
		self.cursor.x = self.cursor.x - 1
	else
		-- Need to scroll
		if self.scroll.x > 0 then
			self.scroll.x = self.scroll.x - 1
			self:setDirty("full")
		end
	end
end


--- Move the cursor right one character.
function Editor:moveCursorRight()
	local width = self:textWidth()
	local length = self:currentLineLength()

	if self.cursor.x < math.min(width, length - self.scroll.x + 1) then
		-- Still on screen
		self.cursor.x = self.cursor.x + 1
	else
		-- Need to scroll
		if length + 1 >= width and self.scroll.x + width <= length then
			self.scroll.x = self.scroll.x + 1
			self:setDirty("full")
		end
	end
end


--- Scroll up one line.
function Editor:scrollUp()
	if self.scroll.y > 0 then
		self.scroll.y = self.scroll.y - 1
		self:setDirty("full")
	end
end


--- Scroll down one line.
function Editor:scrollDown()
	if self:canScrollDown() then
		self.scroll.y = self.scroll.y + 1
		self:setDirty("full")
	end
end


--- Returns true if the editor can scroll down.
function Editor:canScrollDown()
	return #self.lines > self.height and self.scroll.y + self.height < #self.lines
end


--- Move the cursor to the start of the current line.
function Editor:moveCursorToStartOfLine()
	self.cursor.x = 1

	if self.scroll.x > 0 then
		self.scroll.x = 0
		self:setDirty("full")
	end
end


--- Move the cursor to the end of the current line.
function Editor:moveCursorToEndOfLine()
	local length = self:currentLineLength()
	local width = self:textWidth()

	if length == 0 then
		-- Move to 0
		self:moveCursorToStartOfLine()
	elseif length - self.scroll.x > 0 then
		-- The end of the line can be seen
		self.cursor.x = length - self.scroll.x + 1
	else
		-- The end of the line is off screen
		self.cursor.x = width
		self.scroll.x = length - width + 1
		self:setDirty("full")
	end
end


--- Move the cursor to the start of the file.
function Editor:moveCursorToStartOfFile()
	local previousY = self.cursor.y
	self.cursor.y = 1
	if self.scroll.y > 0 then
		self.scroll.y = 0
		self:setDirty("full")
	else
		self:updateGutter(previousY)
	end

	self:moveCursorToStartOfLine()
end


--- Move the cursor to the start of the last line in the file.
function Editor:moveCursorToEndOfFile()
	local previousY = self.cursor.y
	self.cursor.y = self.height

	local scroll = #self.lines - self.height
	if self.scroll.y ~= scroll then
		self.scroll.y = scroll
		self:setDirty("full")
	else
		self:updateGutter(previousY)
	end

	self:moveCursorToStartOfLine()
end


--- Move the cursor to the start of a particular line.
--- The line number is given as absolute within the file.
function Editor:moveCursorToLine(y)
	self:moveCursorTo(1, y)
end


--- Move up one page. A page's height is equal to the
--- height of the editor.
function Editor:pageUp()
	local y = math.max(0, self.cursor.y + self.scroll.y - self.height)
	self:moveCursorTo(1, y)
end


--- Move down one page. A page's height is equal to the
--- height of the editor.
function Editor:pageDown()
	local y = math.max(0, self.cursor.y + self.scroll.y + self.height)
	self:moveCursorTo(1, y)
end


--- Delete the character behind the current cursor position.
function Editor:backspace()
	self:resetCursorRestoration()

	-- Only continue if we are not at the first location in the file
	if self.cursor.x > 1 or self.scroll.x > 0 or self.cursor.y > 1 or self.scroll.y > 0 then
		local x, y = self:absoluteCursorPosition()

		if x > 1 then
			-- Remove a single character
			self.lines[y] = self.lines[y]:sub(1, x - 2) .. self.lines[y]:sub(x)
			self:setDirty("line", self.cursor.y)

			-- If the cursor is not at the end of the line
			local length = self.lines[y]:len()
			if self.cursor.x + self.scroll.x <= length + 1 then
				self:moveCursorLeft()
			end
		else
			-- Remove the line
			local length = self.lines[y - 1]:len()
			self.lines[y - 1] = self.lines[y - 1] .. self.lines[y]
			table.remove(self.lines, y)

			-- Update the cursor
			self:moveCursorTo(length + 1, y - 1)
			self:setDirty("full")
		end
	end
end


--- Delete the character in front of the current cursor position.
function Editor:forwardDelete()
	self:resetCursorRestoration()
	local x, y = self:absoluteCursorPosition()
	local length = self:currentLineLength()

	if x <= length then
		-- Remove a single character
		self.lines[y] = self.lines[y]:sub(1, x - 1) .. self.lines[y]:sub(x + 1)
		self:setDirty("line", self.cursor.y)
	else
		-- Remove the line below
		self.lines[y] = self.lines[y] .. self.lines[y + 1]
		table.remove(self.lines, y + 1)
		self:setDirty("full")
	end
end


--- Insert a character at the current cursor position.
function Editor:insertCharacter(character)
	self:resetCursorRestoration()
	local x, y = self:absoluteCursorPosition()
	self.lines[y] = self.lines[y]:sub(1, x - 1) .. character .. self.lines[y]:sub(x)
	self:moveCursorRight()
	self:setDirty("line", self.cursor.y)
end


--- Insert a newline at the current cursor position.
function Editor:insertNewline()
	self:resetCursorRestoration()
	local x, y = self:absoluteCursorPosition()
	local first = self.lines[y]:sub(1, x - 1)
	local second = self.lines[y]:sub(x)

	self.lines[y] = first
	table.insert(self.lines, y + 1, second)

	self:moveCursorDown()
	self:moveCursorToStartOfLine()
	self:setDirty("full")
end


--- Rests the cursor restoration.
function Editor:resetCursorRestoration()
	local length = self:currentLineLength()
	if self.cursor.x + self.scroll.x > length then
		self:moveCursorToEndOfLine()
	end
end


--- Returns the size of the gutter.
function Editor:gutterSize()
	return tostring(#self.lines):len() + Theme["gutter separator"]:len()
end


--- Returns the width of the text portion of the
--- window (excluding the gutter).
function Editor:textWidth()
	return self.width - self:gutterSize()
end


--- Returns the length of the line the cursor is on.
function Editor:currentLineLength()
	return self.lines[self.cursor.y + self.scroll.y]:len()
end


--- Returns the x and y location of the cursor on screen,
--- relative to the top left of the editor's window.
function Editor:cursorPosition()
	local length = self:currentLineLength()
	local x = math.min(self.cursor.x, length - self.scroll.x + 1) + self:gutterSize()
	local y = self.cursor.y
	return x, y
end


--- Return the absolute position of the cursor in the document.
function Editor:absoluteCursorPosition()
	local x = self.cursor.x + self.scroll.x
	local y = self.cursor.y + self.scroll.y
	return x, y
end


--- Appends or sets what to render.
function Editor:setDirty(kind, data)
	if kind == "full" then
		self.dirtyData = kind
	elseif self.dirtyData ~= "full" then
		if not self.dirtyData then
			self.dirtyData = {}
		end

		local data = {
			["kind"] = kind,
			["data"] = data,
		}

		-- Optimizations:
		-- * Remove duplicate draws
		-- * When a line draw is added, remove all gutter draws on that line

		table.insert(self.dirtyData, data)
	end
end


--- Determines whether the gutter on the current line and previous
--- line should be redrawn.
function Editor:updateGutter(previousY)
	if self.cursor.y ~= previousY then
		self:setDirty("gutter", previousY)
		self:setDirty("gutter", self.cursor.y)
	end
end


--- Returns what needs to be redrawn.
--- Returns nil to indicate nothing should be drawn.
--- Returns either "full" if to redraw everything, or an array of:
--- * `line`, lines - A line or lines needs redrawing
--- * `gutter`, lines - The gutter on a line or lines needs redrawing
--- All line values are relative to the top left corner of the editor
function Editor:dirty()
	return self.dirtyData
end


--- Clears the dirty data.
function Editor:clearDirty()
	self.dirtyData = nil
end
