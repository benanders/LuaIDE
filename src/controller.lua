
--
--  Controller
--

Controller = {}
Controller.__index = Controller


--- Create a new controller object.
--- Returns nil if the program should exit due to invalid arguments.
function Controller.new(...)
	local self = setmetatable({}, Controller)
	if not self:setup(...) then
		return nil
	else
		return self
	end
end


function Controller:setup(args)
	local project = nil
	if #args >= 1 then
		local file = shell.dir() .. "/" .. args[1]
		if not fs.isDir(file) then
			project = file
		else
			printError("Cannot edit a directory")
			return false
		end
	else
		print("Usage:")
		print("  luaide <filepath>")
		return false
	end

	term.setBackgroundColor(colors.black)
	term.clear()

	Theme.load()

	self.menuBar = MenuBar.new()
	self.tabBar = ContentTabLink.new()
	return true
end


--- Run the main loop.
function Controller:run()
	self.menuBar:draw()
	self.tabBar:draw()

	while true do
		local event = {os.pullEventRaw()}
		local cancel = false

		if event[1] == "terminate" or event[1] == "exit" then
			break
		elseif event[1] == "menu item close" or event[1] == "menu item trigger" then
			-- Trigger a full redraw
			self.menuBar:draw()
			self.tabBar:draw()
		end

		if not cancel then
			cancel = self.menuBar:event(event)
		end

		if not cancel then
			cancel = self.tabBar:event(event)
		end

		self.tabBar:restoreCursor()
	end
end
