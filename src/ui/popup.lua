
--
--  Popup
--

--- A popup that displays a message.
Popup = {}
Popup.__index = Popup


--- Displays an error message to the user.
--- Blocks until the user clicks the dismiss button.
function Popup.errorPopup(...)

end


--- Opens a file browsing dialog.
--- Returns the selected path, or nil if the operation was canceled.
function Popup.filePopup(message)
	local w, h = term.native().getSize()
	local win = window.create(term.native(), 1, 1, w, h)

	term.redirect(win)
	term.setBackgroundColor(Theme["file popup background"])
	term.setTextColor(Theme["file popup text"])
	term.clear()

	term.setCursorPos(2, 2)
	term.write(message)

	term.setCursorPos(2, 4)
	term.write("Path: ")

	local path =
end



--
--  Text Field
--

--- An editable text field.
TextField = {}
TextField.__index = TextField


--- Create a new text field.
function TextField.new(...)
	local self = setmetatable({}, TextField)
	self:setup(...)
	return self
end


--- Creates a text field.
function Popup.textField(startX, startY, length, startingText, backgroundColor, placeholder,
		shouldHideText, originalHistory, eventCallback)
	local horizontalScroll = 1
	local cursorPosition = 1
	local historyPosition = nil
	local history = {}

	if originalHistory then
		copyTable(originalHistory, history)
		table.insert(history, "")
		historyPosition = #history
	end

	local data = startingText

	if not data then
		data = ""
	else
		cursorPosition = data:len() + 1
	end

	while true do
		term.setCursorBlink(true)
		term.setBackgroundColor(backgroundColor)
		term.setTextColor(Theme.text)

		term.setCursorPos(startX, startY)
		term.write(string.rep(" ", length))
		term.setCursorPos(startX, startY)

		local text = data
		if shouldHideText then
			text = string.rep("*", #data)
		end
		term.write(text:sub(horizontalScroll, horizontalScroll + length - 1))

		if #data == 0 and placeholder then
			term.setTextColor(Theme.text)
			term.write(placeholder)
		end

		term.setCursorPos(startX + cursorPosition - horizontalScroll, startY)

		local event = {os.pullEventRaw()}
		if event[1] == "terminate" then
			data = nil
			break
		end

		if eventCallback then
			local shouldReturn, response = eventCallback(data, event)
			if shouldReturn then
				data = response
				break
			end
		end

		local isMouseEvent = event[1] == "mouse_click" or event[1] == "mouse_drag"

		if isMouseEvent then
			local inHorizontalBounds = event[3] >= startX and event[3] < startX + length
			local inVerticalBounds = event[4] == startY
			if inHorizontalBounds and inVerticalBounds then
				local previousX = term.getCursorPos()
				local position = cursorPosition - (previousX - event[3])
				cursorPosition = math.min(position, #data + 1)
			end
		elseif event[1] == "char" then
			if term.getCursorPos() >= startX + length - 1 then
				horizontalScroll = horizontalScroll + 1
			end

			cursorPosition = cursorPosition + 1
			local before = data:sub(1, cursorPosition - 1)
			local after = data:sub(cursorPosition, -1)
			data = before .. event[2] .. after
		elseif event[1] == "key" then
			if event[2] == keys.enter then
				break
			elseif event[2] == keys.left and cursorPosition > 1 then
				cursorPosition = cursorPosition - 1
				if cursorPosition <= horizontalScroll and horizontalScroll > 1 then
					local amount = ((horizontalScroll - cursorPosition) + 1)
					horizontalScroll = horizontalScroll - amount
				end
			elseif event[2] == keys.right and cursorPosition <= data:len() then
				cursorPosition = cursorPosition + 1
				if 1 >= length - (cursorPosition - horizontalScroll) + 1 then
					horizontalScroll = horizontalScroll + 1
				end
			elseif event[2] == keys.backspace and cursorPosition > 1 then
				data = data:sub(1, cursorPosition - 2) .. data:sub(cursorPosition, -1)
				cursorPosition = cursorPosition - 1
				if cursorPosition <= horizontalScroll and horizontalScroll > 1 then
					local amount = ((horizontalScroll - cursorPosition) + 1)
					horizontalScroll = horizontalScroll - amount
				end
			elseif event[2] == keys.up and history then
				if historyPosition > 1 then
					historyPosition = historyPosition - 1
					data = history[historyPosition]
					cursorPosition = history[historyPosition]:len() + 1
				end
			elseif event[2] == keys.down and history then
				if historyPosition < #history then
					historyPosition = historyPosition + 1
					data = history[historyPosition]
					cursorPosition = history[historyPosition]:len() + 1
				end
			end
		end
	end

	term.setCursorBlink(false)
	return data
end
