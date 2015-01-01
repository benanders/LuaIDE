
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
end


--- Shows the content window's window, redrawing it over the existing screen space
--- and restoring the cursor to its original position in the window.
function Content:show()
	term.redirect(self.win)
	self.win.setVisible(true)
	self.win.redraw()
	self.win.restoreCursor()
end


--- Hides the window.
function Content:hide()
	self.win.setVisible(false)
end


--- Draws the editor.
function Content:draw()
	self:show()
end


--- Returns the trimmed domain name of the tab's currently loaded site's URL.
function Content:name()
	return "test"
end


--- Called when an event occurs.
function Content:event(event)

end
