
--
--  Content
--

--- A content window for each tab.
--- Responsible for rendering the editor.
Content = {}
Content.__index = Content

--- The starting y position of the tab.
Content.startY = 3


--- Create a new content window.
function Content.new(...)
	local self = setmetatable({}, Content)
	self:setup(...)
	return self
end


function Content:setup()
	local w, h = term.native().getSize()
	self.height = h - Content.startY + 1
	self.width = w
	self.win = window.create(term.native(), 1, Content.startY, self.width, self.height, false)
	self.editor = Editor.new({""}, self.width, self.height)
	self.path = nil
	self.highlighter = SyntaxHighlighter.new()
	self:updateSyntaxHighlighting("")
end


--- Set the file currently being edited in this tab.
--- Discards the current file and all changes and replaces it.
--- Returns nil on success and a string error message on failure.
function Content:edit(path)
	local lines, err = File.load(path)

	if lines then
		self.path = path
		self.editor = Editor.new(lines, self.width, self.height)
		self:updateSyntaxHighlighting("")
	else
		Popup.errorPopup("Failed to open file", err)
	end
end


--- Save the contents of the editor.
function Content:save(path)
	if not self.path then
		self.path = path
	end
	if not path then
		path = self.path
	end

	if not path then
		Popup.errorPopup("No path specified to save to!")
	end

	local err = File.save(self.editor.lines, path)
	if err then
		Popup.errorPopup("Failed to save file", err)
	end
end


--- Returns the name of the file being edited.
function Content:name()
	return "test"
end


--- Shows the content window's window, redrawing it over the existing screen space
--- and restoring the cursor to its original position in the window.
function Content:show()
	term.redirect(self.win)
	self.win.setVisible(true)
	self:draw()
	self:restoreCursor()
end


--- Hides the window.
function Content:hide()
	self.win.setVisible(false)
end


--- Sets the cursor position to that defined by the editor.
function Content:restoreCursor()
	local x, y = self.editor:cursorPosition()

	term.redirect(self.win)
	term.setCursorPos(x, y)
	term.setTextColor(Theme["editor text"])
	term.setCursorBlink(true)
end


--- Renders a whole line - gutter and text.
--- Does not redirect to the terminal.
function Content:drawLine(y)
	term.setBackgroundColor(Theme["editor background"])
	term.setCursorPos(1, y)
	term.clearLine()
	self:drawText(y)
	self:drawGutter(y)
end


--- Renders the gutter on a single line.
function Content:drawGutter(y)
	if y == self.editor.cursor.y then
		term.setBackgroundColor(Theme["gutter background focused"])
		term.setTextColor(Theme["gutter text focused"])
	else
		term.setBackgroundColor(Theme["gutter background"])
		term.setTextColor(Theme["gutter text"])
	end

	local size = self.editor:gutterSize()
	local lineNumber = tostring(y + self.editor.scroll.y)
	local padding = string.rep(" ", size - lineNumber:len() - 1)
	lineNumber = padding .. lineNumber .. Theme["gutter separator"]
	term.setCursorPos(1, y)
	term.write(lineNumber)
end


--- Renders the text for a single line.
function Content:drawText(y)
	local absoluteY = y + self.editor.scroll.y
	local data = self.highlighter:data(absoluteY, self.editor.scroll.x, self.width)

	term.setBackgroundColor(Theme["editor background"])
	term.setTextColor(Theme["editor text"])
	term.setCursorPos(self.editor:gutterSize() + 1, y)

	for _, item in pairs(data) do
		if item.kind == "text" then
			-- Render some text
			term.write(item.data)
		elseif item.kind == "color" then
			-- Set the current text color
			local index = item.data
			if index == "text" then
				index = "editor text"
			end

			term.setTextColor(Theme[index])
		end
	end
end


--- Fully redraws the editor.
function Content:draw()
	term.redirect(self.win)

	-- Clear
	term.setBackgroundColor(Theme["editor background"])
	term.clear()

	-- Iterate over each line
	local lineCount = math.min(#self.editor.lines, self.height)
	for y = 1, lineCount do
		self:drawText(y)
		self:drawGutter(y)
	end

	-- Restore the cursor position
	self:restoreCursor()
end


--- Updates the screen based off what the editor says needs redrawing.
function Content:updateDirty()
	local dirty = self.editor:dirty()
	if dirty then
		if dirty == "full" then
			self:draw()
		else
			term.redirect(self.win)
			for _, data in pairs(dirty) do
				if data.kind == "gutter" then
					self:drawGutter(data.data)
				elseif data.kind == "line" then
					self:drawLine(data.data)
				end
			end
		end

		self.editor:clearDirty()
	end
end


--- Updates the syntax highlighter.
--- Triggers an update of the mapped data if character is non-nil,
--- and a full redraw if character is one of the full redraw triggers.
function Content:updateSyntaxHighlighting(character)
	if character then
		self.highlighter:update(self.editor.lines)

		-- Trigger a full redraw if a mapped character was typed (ie. affects
		-- the highlighting on other lines).
		if SyntaxHighlighter.fullRedrawTriggers:find(character, 1, true) then
			self.editor:setDirty("full")
		end
	end
end


--- Called when a key event occurs.
function Content:key(key)
	if key == keys.up then
		self.editor:moveCursorUp()
	elseif key == keys.down then
		self.editor:moveCursorDown()
	elseif key == keys.left then
		self.editor:moveCursorLeft()
	elseif key == keys.right then
		self.editor:moveCursorRight()
	elseif key == keys.backspace then
		local character = self.editor:backspace()
		self:updateSyntaxHighlighting(character)
	elseif key == keys.enter then
		self.editor:insertNewline()
		self:updateSyntaxHighlighting("\n")
	end
end


--- Called when a char event occurs.
function Content:char(character)
	self.editor:insertCharacter(character)
	self:updateSyntaxHighlighting(character)
end


--- Called when an event occurs.
function Content:event(event)
	if event[1] == "char" then
		self:char(event[2])
	elseif event[1] == "key" then
		self:key(event[2])
	elseif event[1] == "mouse_click" or event[1] == "mouse_drag" then
		self.editor:moveCursorToRelative(event[3] - self.editor:gutterSize(), event[4])
		return true
	end

	self:updateDirty()
	self:restoreCursor()
	return false
end
