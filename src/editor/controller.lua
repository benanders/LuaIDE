
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
	self.editor = Editor.new(project)
	return true
end


--- Run the main loop.
function Controller:run()
	self.menuBar:draw()
	self.tabBar:draw()

	-- Render the editor last so the cursor is in the correct position
	self.editor:draw()
	self.editor:restoreCursor()

	while true do
		local event = {os.pullEventRaw()}

		if event[1] == "terminate" then
			break
		end

		local cancel = false

		if not cancel then
			cancel = self.menuBar:event(event)
		end

		if not cancel then
			cancel = self.tabBar:event(event)
		end

		if not cancel then
			cancel = self.editor:event(event)
		end

		self.editor:restoreCursor()
	end
end
