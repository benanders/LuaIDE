
--
--  Utility APIs
--

--- Contains various utilities.
Util = {}


--- Clear the background of the terminal to `bg`, and
--- set the text color to `fg`
function Util.clear(bg, fg)
	term.setBackgroundColor(bg)
	term.setTextColor(fg)
	term.clear()
	term.setCursorPos(1, 1)
end


--- Print `text` centered on the current cursor line.
--- Moves the cursor to the line below it after writing.
function Util.center(text)
	local w = term.getSize()
	local _, y = term.getCursorPos()
	if text:len() <= w then
		term.setCursorPos(math.floor(w / 2 - text:len() / 2) + 1, y)
		term.write(text)
		term.setCursorPos(1, y + 1)
	else
		term.setCursorPos(1, y)
		print(text)
	end
end


--- Fills the given area on the screen with a color.
function Util.fill(x, y, width, height, color)
	local w, h = term.getSize()
	if width == -1 then
		width = w
	end

	if height == -1 then
		height = h
	end

	if x == -1 then
		x = math.floor(w / 2 - width / 2) + 1
	end

	if y == -1 then
		y = math.floor(h / 2 - height / 2) + 1
	end

	term.setBackgroundColor(color)
	local str = string.rep(" ", width)
	for i = y, y + height - 1 do
		term.setCursorPos(x, i)
		term.write(str)
	end
end


--- Writes the given text at the specified location.
function Util.write(x, y, text)
	if x == -1 then
		local w = term.getSize()
		x = math.floor(w / 2 - text:len() / 2) + 1
	end

	term.setCursorPos(x, y)
	term.write(text)
end


--- Renders an error.
function Util.displayError(err)
	Util.clear(Theme.background, Theme.text)
	Util.fill(1, 3, -1, 3, Theme.subtle)
	Util.write(-1, 4, "Firewolf Crash")
	term.setBackgroundColor(Theme.background)

	term.setCursorPos(1, 9)
	Util.center("Firewolf has crashed unexpectedly.")
	Util.center("Here's the error:")
	print()
	Util.center(err)
	print()
	Util.center("Press any key to exit.")
end


--- Waits for a key press and stops the key from being displayed.
function Util.waitForKey()
	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end


local function copyTable(source, destination)
	for key, value in pairs(source) do
		destination[key] = value
	end
end


--- Creates a text field.
function Util.textField(startX, startY, length, startingText, placeholder,
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
		term.setBackgroundColor(Theme.accent)
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
