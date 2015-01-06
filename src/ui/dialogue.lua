
--
--  File Dialogue
--

--- A file selection dialogue.
FileDialogue = {}
FileDialogue.__index = FileDialogue

FileDialogue.y = 3

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
	local list = self:list()
	local startY = 6
	local height = self.height - startY

	term.setBackgroundColor(Theme["file dialogue background"])

	for y = 1, math.min(height) do
		term.setCursorPos(2, y + startY - 1)
		term.clearLine()

		local file = list[y]
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
end


function FileDialogue:clickOnItem(name)
	local path = fs.combine(self.dir, name)
	if fs.isDir(path) then
		self.dir = path
		return "/" .. path
	else
		return "/" .. path
	end
end


function FileDialogue:setDir(dir)
	self.dir = shell.resolve("/" .. dir)
	self.scroll = 0
	selfCopy:drawFileList()
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
	local listStartY = y + 5
	local selfCopy = self

	field:setCallback(function(event)
		if event[1] == "mouse_click" then
			local cx = event[3]
			local cy = event[4]
			if cy >= listStartY and cy < listStartY + self.height then
				local list = selfCopy:list()
				local item = list[cy - listStartY + 1]
				if item then
					local result = selfCopy:clickOnItem(item)
					selfCopy:drawFileList()
					return result
				end
			end
		elseif event[1] == "char" or event[1] == "key" then
			if fs.isDir(field.text) or fs.isDir(fs.getDir(field.text)) then
				selfCopy:setDir(field.text)
			end
		end
	end)

	-- Show
	self:drawFileList()
	local result = field:show()
	if result:len() == 0 then
		result = nil
	end

	return result
end
