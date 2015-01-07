
--
--  File Dialogue
--

--- A file selection dialogue.
FileDialogue = {}
FileDialogue.__index = FileDialogue

FileDialogue.y = 3
FileDialogue.listStartY = 6

FileDialogue.ignore = {
	".git",
	".gitignore",
	".DS_Store",
}


--- Create a new dialogue
function FileDialogue.new(...)
	self = setmetatable({}, FileDialogue)
	self:setup(...)
	return self
end


function FileDialogue:setup(title)
	self.title = title
	self.dir = shell.dir()
	self.listCache = self:list()
	self.height = -1
	self.scroll = 0
end


function FileDialogue:list()
	local files = fs.list(self.dir)
	local list = {}

	-- Add items
	for _, file in pairs(files) do
		local add = true
		for _, ignore in pairs(FileDialogue.ignore) do
			if file == ignore then
				add = false
				break
			end
		end

		if add then
			table.insert(list, file)
		end
	end

	-- Sort items
	table.sort(list, function(a, b)
		local aPath = fs.combine(self.dir, a)
		local bPath = fs.combine(self.dir, b)
		if fs.isDir(aPath) and fs.isDir(bPath) then
			return a < b
		elseif fs.isDir(aPath) or fs.isDir(bPath) then
			return fs.isDir(aPath)
		else
			return a < b
		end
	end)

	-- Add the back button
	if self.dir ~= "" then
		table.insert(list, 1, "..")
	end

	return list
end


function FileDialogue:drawFileList()
	term.setBackgroundColor(Theme["file dialogue background"])

	for y = 1, math.min(self:listHeight()) do
		term.setCursorPos(2, y + FileDialogue.listStartY - 1)
		term.clearLine()

		local file = self.listCache[y + self.scroll]
		if file then
			local path = fs.combine(self.dir, file)

			term.setTextColor(Theme["file dialogue file"])
			if fs.isDir(path) then
				term.setTextColor(Theme["file dialogue folder"])
			elseif fs.isReadOnly(path) then
				term.setTextColor(Theme["file dialogue readonly"])
			end

			term.write(file)
		end
	end

	term.setTextColor(Theme["file dialogue text blurred"])
	if #self.listCache - self.scroll > self:listHeight() then
		term.setCursorPos(1, self:listHeight() + FileDialogue.listStartY - 1)
		term.write("v")
	end
	if self.scroll > 0 then
		term.setCursorPos(1, FileDialogue.listStartY)
		term.write("^")
	end
end


function FileDialogue:listHeight()
	return self.height - FileDialogue.listStartY
end


function FileDialogue:clickOnItem(name)
	local path = fs.combine(self.dir, name)
	if fs.isDir(path) then
		self:setDir(path)
		return "/" .. path
	else
		return "/" .. path
	end
end


function FileDialogue:setDir(dir)
	self.dir = shell.resolve("/" .. dir)
	self.listCache = self:list()
	self.scroll = 0
	self:drawFileList()
end


function FileDialogue:scrollUp()
	if self.scroll > 0 then
		self.scroll = self.scroll - 1
		self:drawFileList()
	end
end


function FileDialogue:scrollDown()
	if self.scroll + self:listHeight() < #self.listCache then
		self.scroll = self.scroll + 1
		self:drawFileList()
	end
end



--- Returns nil if the user canceled the operation, or the selected path as
--- a string.
function FileDialogue:show()
	local x = 1
	local y = FileDialogue.y
	local w, h = term.native().getSize()
	self.height = h - (FileDialogue.y - 1) * 2
	local win = window.create(term.native(), x, y, w, self.height)

	-- Create and clear the window
	term.setCursorBlink(false)
	term.redirect(win)
	term.setTextColor(Theme["file dialogue text"])
	term.setBackgroundColor(Theme["file dialogue background"])
	term.clear()

	-- Title text
	term.setCursorPos(2, 2)
	term.write(self.title)

	-- Text field
	local field = TextField.new(2, 4,
		Theme["file dialogue text"], Theme["file dialogue background"])
	field:setWidth(-2)
	field:setPlaceholder("Path...", Theme["file dialogue text blurred"])

	-- Text field's initial text
	field.text = "/" .. self.dir
	field:moveToEnd()

	-- Event callback
	local listStartY = y + FileDialogue.listStartY - 1
	local selfCopy = self

	field:setCallback(function(event)
		if event[1] == "mouse_click" then
			local cx = event[3]
			local cy = event[4]
			if cx > 1 and cy >= listStartY and cy < listStartY + selfCopy:listHeight() then
				local item = selfCopy.listCache[cy - listStartY + 1]
				if item then
					local result = selfCopy:clickOnItem(item)
					selfCopy:drawFileList()
					return result
				end
			elseif cx == 1 then
				if cy == listStartY then
					self:scrollUp()
				elseif cy == listStartY + selfCopy:listHeight() - 1 then
					self:scrollDown()
				end
			end
		elseif event[1] == "char" or (event[1] == "key" and event[2] == keys.backspace) then
			if fs.isDir(field.text) then
				selfCopy:setDir(field.text)
			elseif fs.isDir(fs.getDir(field.text)) then
				selfCopy:setDir(fs.getDir(field.text))
			end
		elseif event[1] == "key" then
			if event[2] == keys.up then
				self:scrollUp()
			elseif event[2] == keys.down then
				self:scrollDown()
			end
		elseif event[1] == "mouse_scroll" then
			if event[2] == -1 then
				self:scrollUp()
			else
				self:scrollDown()
			end
		end
	end)

	-- Show
	self:drawFileList()
	local result = field:show()
	if result and result:len() == 0 then
		result = nil
	end

	return result
end
