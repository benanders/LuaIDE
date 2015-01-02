
--
--  Menu Bar
--

MenuBar = {}
MenuBar.__index = MenuBar


--- Create a new menu bar.
function MenuBar.new(...)
	local self = setmetatable({}, MenuBar)
	self:setup(...)
	return self
end


function MenuBar:setup()
	local w = term.getSize()
	self.win = window.create(term.native(), 1, 1, w, 1)
end


--- Render the menu bar
--- Redirects the terminal to the menu bar's window
function MenuBar:draw()
	term.redirect(self.win)
	term.setBackgroundColor(Theme["menu bar background"])
	term.setTextColor(Theme["menu bar text"])
	term.clear()
	term.setCursorPos(2, 1)
	term.write("LuaIDE " .. Global.version)
end


--- Trigger an event on the menu bar
function MenuBar:event(event)

end
