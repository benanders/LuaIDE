
--
--  Menu Bar Responder
--

--- Triggers an appropriate response to different menu item trigger events.
Responder = {}


--- Called when a menu item trigger event occurs.
function Responder.trigger(item)
	if item == "Quit" then
		os.queueEvent("exit")
	end

	return true
end


--- Called when an event occurs.
function Responder.event(event)
	if event[1] == "menu item trigger" then
		return Responder.trigger(event[2])
	end

	return false
end
