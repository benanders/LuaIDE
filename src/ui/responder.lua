
--
--  Menu Bar Responder
--

--- Triggers an appropriate response to different menu item trigger events.
Responder = {}
Responder.__index = Responder


--- Create a new responder
function Responder.new(...)
	local self = setmetatable({}, Responder)
	self:setup(...)
	return self
end


function Responder:setup(controller)
	self.controller = controller
end


function Responder.toCamelCase(identifier)
	identifier = identifier:lower()

	local first = true
	local result = ""
	for word in identifier:gmatch("[^%s]+") do
		if first then
			result = result .. word:lower()
			first = false
		else
			result = result .. word:sub(1, 1):upper() .. word:sub(2):lower()
		end
	end

	return result
end


function Responder:trigger(itemName)
	local name = Responder.toCamelCase(itemName)
	if self[name] then
		self[name](self)
	end
end


function Responder:quit()
	os.queueEvent("exit")
end


-- --- Called when the save item is triggered.
-- function Responder.save(controller)
-- 	local editor = controller.tabBar:current()
-- 	if not editor.path then
-- 		local path = Popup.filePath("Specify a save path...")
-- 		if not path then
-- 			-- User canceled, abort saving
-- 			return
-- 		end

-- 		editor.path = path
-- 	end

-- 	editor:save()
-- end


-- --- Called when the save as item is triggered.
-- function Responder.saveAs(controller)
-- 	local path = Popup.filePath("Specify a save path...")
-- 	if not path then
-- 		-- User canceled, abort saving
-- 		return
-- 	end

-- 	editor:save(path)
-- end


-- --- Called when the open item is triggered.
-- function Responder.open(controller)
-- 	local path = Popup.filePath("Specify a file to open...")
-- 	if not path then
-- 		-- Canceled
-- 		return
-- 	end

-- 	controller.tabBar:create()
-- 	controller.tabBar:switch(controller.tabBar:openCount())
-- 	controller.tabBar:current():edit(path)
-- end


-- --- Called when a menu item trigger event occurs.
-- function Responder.trigger(controller, item)
-- 	-- File menu
-- 	if item == "New" then
-- 		controller.tabBar:create()
-- 		controller.tabBar:switch(controller.tabBar:openCount())
-- 	elseif item == "Open" then
-- 		Responder.open(controller)
-- 	elseif item == "Save" then
-- 		Responder.save(controller)
-- 	elseif item == "Save as" then
-- 		Responder.saveAs(controller)
-- 	elseif item == "Quit" then
-- 		os.queueEvent("exit")
-- 	end

-- 	return true
-- end


-- --- Called when an event occurs.
-- function Responder.event(controller, event)
-- 	if event[1] == "menu item trigger" then
-- 		return Responder.trigger(controller, event[2])
-- 	end

-- 	return false
-- end
