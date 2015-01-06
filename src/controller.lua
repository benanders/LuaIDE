
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
	local path = nil
	if #args >= 1 then
		local file = shell.dir() .. "/" .. args[1]
		file = file:gsub("/+", "/")

		if not fs.isDir(file) then
			path = file
		else
			printError("Cannot edit a directory")
			return false
		end
	end

	term.setBackgroundColor(colors.black)
	term.clear()

	Theme.load()

	self.menuBar = MenuBar.new()
	self.tabBar = ContentTabLink.new()
	self.responder = Responder.new(self)

	if path then
		self.tabBar:current():edit(path)
	end

	return true
end


--- Draw the whole IDE.
function Controller:draw()
	self.menuBar:draw()
	self.tabBar:draw()
end


--- Run the main loop.
function Controller:run()
	self:draw()

	while true do
		local event = {os.pullEventRaw()}
		local cancel = false

		if event[1] == "terminate" or event[1] == "exit" then
			break
		end

		-- Trigger a redraw so we can close the menu before displaying any menu items, etc.
		if event[1] == "menu item close" or event[1] == "menu item trigger" then
			self:draw()
		end

		if event[1] == "menu item trigger" and not cancel then
			cancel = self.responder:trigger(event[2])

			-- If some event was triggered, then redraw fully
			if cancel then
				self:draw()
			end
		end

		if not cancel then
			cancel = self.menuBar:event(event)
		end

		if not cancel then
			cancel = self.tabBar:event(event)
		end

		self.tabBar:current():restoreCursor()
	end
end
