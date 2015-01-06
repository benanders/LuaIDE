
--
--  File Dialogue
--

--- A file selection dialogue.
FileDialogue = {}
FileDialogue.__index = FileDialogue

FileDialogue.y = 4


--- Create a new dialogue
function FileDialogue.new(...)
	self = setmetatable({}, FileDialogue)
	self:setup(...)
	return self
end


function FileDialogue:setup(title)
	self.title = title
	self.dir = "/"
	self.field = nil
end


function FileDialogue:drawFileList()

end


--- Returns nil if the user canceled the operation, or the selected path as
--- a string.
function FileDialogue:show()
	local x = 1
	local y = FileDialogue.y
	local w, h = term.native().getSize()
	local height = h - FileDialogue.y * 2
	local win = window.create(term.native(), x, y, w, height)

	term.setCursorBlink(false)
	term.redirect(win)
	term.setTextColor(Theme["file dialogue text"])
	term.setBackgroundColor(Theme["file dialogue background"])
	term.clear()

	term.setCursorPos(2, 2)
	term.write(self.title)

	self.field = TextField.new(2, 4,
		Theme["file dialogue text"], Theme["file dialogue background"])
	self.field:setWidth(-2)
	self.field:setPlaceholder("Path...", Theme["file dialogue text blurred"])

	return self.field:show()
end
