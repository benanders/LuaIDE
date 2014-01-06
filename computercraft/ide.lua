
--  
--  Lua IDE
--  Made by GravityScore
--  




--    Variables

local version = "2.0"
local args = {...}


local w, h = term.getSize()
local tabWidth = 2

local autosaveInterval = 20
local allowEditorEvent = true
local keyboardShortcutTimeout = 0.4


local clipboard = nil

local languages = {}
local currentLanguage = {}


local updateURL = "https://raw.github.com/GravityScore/LuaIDE/master/computercraft/ide.lua"
local ideLocation = "/" .. shell.getRunningProgram()
local themeLocation = "/.luaide-theme"


local theme = {
	background = colors.gray,
	titleBar = colors.lightGray,

	top = colors.lightBlue,
	bottom = colors.cyan,

	button = colors.cyan,
	buttonHighlighted = colors.lightBlue,

	editor_lineHighlight = colors.lightBlue,
	editor_errorLineHighlight = colors.pink,

	dangerButton = colors.red,
	dangerButtonHighlighted = colors.pink,

	text = colors.white,
	folder = colors.lime,
	readOnly = colors.red,
}




--    Utilities


local isAdvanced = function()
	return term.isColor and term.isColor()
end



local fill = function(x, y, w, h, text)
	if not text then
		text = " "
	end

	for a = y, y + h - 1 do
		term.setCursorPos(x, a)
		term.write(string.rep(text, w))
	end
end


local clear = function()
	term.setBackgroundColor(theme.background)
	term.setTextColor(theme.text)
	term.clear()
end


local title = function(text)
	term.setBackgroundColor(theme.titleBar)
	fill(1, 2, w, 3)
	term.setCursorPos(2, 3)
	term.write(text)
end


local top = function(...)
	local text = {...}
	local width = 0
	for i, closing in pairs(text) do
		width = width < closing:len() and closing:len() or width
	end

	term.setBackgroundColor(theme.top)
	fill(1, 6, width + 2, #text + 2)
	for i, closing in pairs(text) do
		term.setCursorPos(2, 6 + i)
		term.write(closing)
	end
	print("")
	print("")
	print("")
end


local bottom = function(...)
	local text = {...}
	local width = 0
	for i, closing in pairs(text) do
		width = width < closing:len() and closing:len() or width
	end

	local cx, cy = term.getCursorPos()
	term.setBackgroundColor(theme.bottom)
	fill(w - width - 1, cy, width + 2, #text + 2)
	for i, closing in pairs(text) do
		term.setCursorPos(w - closing:len(), cy + i)
		term.write(closing)
	end
end


local center = function(text)
	local x, y = term.getCursorPos()
	term.setCursorPos(math.floor(w / 2 - text:len() / 2) + (text:len() % 2 == 0 and 1 or 0), y)
	term.write(text)
	term.setCursorPos(1, y + 1)
end



local buttonGrid = function(buttons)
	term.setTextColor(theme.text)
	if #buttons == 2 then
		local y = math.floor(h / 2) - 1

		buttons[1].x = math.floor(w / 2) - buttons[1].text:len() - 3
		buttons[1].y = y

		buttons[2].x = math.floor(w / 2) + 1
		buttons[2].y = y

		for i = 1, #buttons do
			term.setBackgroundColor(theme[buttons[i].id .. (buttons[i].selected and "Highlighted" or "")])
			fill(buttons[i].x, buttons[i].y, buttons[i].text:len() + 2, 3)
			term.setCursorPos(buttons[i].x + 1, buttons[i].y + 1)
			term.write(buttons[i].text)
		end
	elseif #buttons == 3 then

	elseif #buttons == 4 then
		local y1 = math.floor(h / 2) - 2
		local y2 = math.floor(h / 2) + 3

		buttons[1].x = math.floor(w / 2) - buttons[1].text:len() - 3
		buttons[1].y = y1

		buttons[2].x = math.floor(w / 2) + 1
		buttons[2].y = y1

		buttons[3].x = math.floor(w / 2) - buttons[3].text:len() - 3
		buttons[3].y = y2

		buttons[4].x = math.floor(w / 2) + 1
		buttons[4].y = y2

		for i = 1, #buttons do
			buttons[i].w = buttons[i].text:len() + 2
			buttons[i].h = 3

			term.setBackgroundColor(theme[buttons[i].id .. (buttons[i].selected and "Highlighted" or "")])
			fill(buttons[i].x, buttons[i].y, buttons[i].text:len() + 2, 3)
			term.setCursorPos(buttons[i].x + 1, buttons[i].y + 1)
			term.write(buttons[i].text)
		end
	end
end




--    Modified Read


local modifiedRead = function(properties)
	-- Properties:
	-- - replaceCharacter
	-- - displayLength
	-- - maxLength
	-- - onEvent
	-- - startingText

	local text = ""
	local startX, startY = term.getCursorPos()
	local pos = 0

	if not properties then
		properties = {}
	end
	if properties.displayLength then
		properties.displayLength = math.min(properties.displayLength, w - 2)
	end
	if properties.startingText then
		text = properties.startingText
		pos = text:len()
	end

	local edit_draw = function(replaceCharacter)
		local scroll = 0
		if properties.displayLength and pos > properties.displayLength then 
			scroll = pos - properties.displayLength
		end

		local repl = replaceCharacter or properties.replaceCharacter
		term.setTextColor(theme.text)
		term.setCursorPos(startX, startY)
		if repl then
			term.write(string.rep(repl:sub(1, 1), text:len() - scroll))
		else
			term.write(text:sub(scroll + 1))
		end

		term.setCursorPos(startX + pos - scroll, startY)
	end

	term.setCursorBlink(true)
	edit_draw()
	while true do
		local event, key, x, y, param4, param5 = os.pullEvent()

		if properties.onEvent then
			-- Actions:
			-- - exit (bool)
			-- - text

			term.setCursorBlink(false)
			local action = properties.onEvent(text, event, key, x, y, param4, param5)
			if action then
				if action.text then
					edit_draw(" ")
					text = action.text
					if text then
						pos = text:len()
					end
				end if action.exit then
					break
				end
			end
			edit_draw()
		end

		term.setCursorBlink(true)
		if event == "char" then
			local canType = true
			if properties.maxLength and text:len() >= properties.maxLength then
				canType = false
			end

			if canType then
				text = text:sub(1, pos) .. key .. text:sub(pos + 1, -1)
				pos = pos + 1
				edit_draw()
			end
		elseif event == "key" then
			if key == keys.enter then
				break
			elseif key == keys.left and pos > 0 then
				pos = pos - 1
				edit_draw()
			elseif key == keys.right and pos < text:len() then
				pos = pos + 1
				edit_draw()
			elseif key == keys.backspace and pos > 0 then
				edit_draw(" ")
				text = text:sub(1, pos - 1) .. text:sub(pos + 1, -1)
				pos = pos - 1
				edit_draw()
			elseif key == keys.delete and pos < text:len() then
				edit_draw(" ")
				text = text:sub(1, pos) .. text:sub(pos + 2, -1)
				edit_draw()
			elseif key == keys.home then
				pos = 0
				edit_draw()
			elseif key == keys["end"] then
				pos = text:len()
				edit_draw()
			end
		elseif event == "mouse_click" then
			local scroll = 0
			if properties.displayLength and pos > properties.displayLength then 
				scroll = pos - properties.displayLength
			end

			if y == startY and x >= startX and x <= math.min(startX + text:len(), startX + (properties.displayLength or 10000)) then
				pos = x - startX + scroll
				edit_draw()
			elseif y == startY then
				if x < startX then
					pos = scroll
					edit_draw()
				elseif x > math.min(startX + text:len(), startX + (properties.displayLength or 10000)) then
					pos = text:len()
					edit_draw()
				end
			end
		end
	end

	term.setCursorBlink(false)
	print("")
	return text
end




--    Updating


local update_download = function(url, path)

end


local update = function()

end




--    Menu


manageButtonGrid = function(buttons)
	buttonGrid(buttons)

	while true do
		local event, key, x, y = os.pullEvent()
		if event == "key" then
			if key == keys.enter then
				return buttons[selection].action
			elseif key == keys.up then
				if selection > math.floor(#buttons / 2) then
					buttons[selection].selected = false
					selection = selection - 2
					buttons[selection].selected = true
				end
			elseif key == keys.down then
				if selection <= math.floor(#buttons / 2) then
					buttons[selection].selected = false
					selection = selection + 2
					buttons[selection].selected = true
				end
			elseif key == keys.left then
				if selection > 0 then
					buttons[selection].selected = false
					selection = selection - 1
					buttons[selection].selected = true
				end
			elseif key == keys.right then
				if selection < #buttons then
					buttons[selection].selected = false
					selection = selection + 1
					buttons[selection].selected = true
				end
			end

			buttonGrid(buttons)
		elseif event == "mouse_click" then
			for _, button in pairs(buttons) do
				if x >= button.x and y >= button.y and x < button.x + button.w and y < button.y + button.h then
					return button.action
				end
			end
		end
	end
end


menu_items = function()
	local selection = 1
	local buttons = {
		{text = "New File", id = "button", selected = true, action = "new"},
		{text = "Open File", id = "button", selected = false, action = "open"},
		{text = "Settings", id = "button", selected = false, action = "settings"},
		{text = "Exit", id = "dangerButton", selected = false, action = "exit"},
	}

	clear()
	title("Lua IDE : Welcome")
	return manageButtonGrid(buttons)
end




--    Settings


settings = function()

end




--    Files


currentDirectory = ""
fileScroll = 0


fileSelect_draw = function()
	term.setBackgroundColor(theme.top)
	fill(2, 9, w - 2, h - 9)

	local files = fs.list(currentDirectory)
	if currentDirectory ~= "" then
		table.insert(files, 1, "Back [..]")
	end

	for i = fileScroll + 1, h - 10 + fileScroll do
		local name = files[i]
		if name then
			term.setCursorPos(3, (i - fileScroll) + 8)
			local path = currentDirectory .. "/" .. name
			if fs.isReadOnly(path) and name ~= "Back [..]" then
				term.setTextColor(theme.readOnly)
				term.write(name .. (fs.isDir(path) and "/" or ""))
			elseif fs.isDir(path) or name == "Back [..]" then
				term.setTextColor(theme.folder)
				term.write(name .. (name == "Back [..]" and "" or "/"))
			else
				term.setTextColor(theme.text)
				term.write(name)
			end
			term.setBackgroundColor(theme.top)
		end
	end
end


fileSelect_onEvent = function(text, event, key, x, y)
	local files = fs.list(currentDirectory)
	if currentDirectory ~= "" then
		table.insert(files, 1, "Back [..]")
	end

	edit_draw()
	if event == "key" then
		if key == keys.up and fileScroll > 0 then
			fileScroll = fileScroll - 1
			edit_draw()
		elseif key == keys.down and fileScroll + (h - 10) < #files then
			fileScroll = fileScroll + 1
			edit_draw()
		elseif key == keys.leftCtrl or key == keys.rightCtrl then
			return {text = nil, exit = true}
		end

	elseif event == "mouse_click" then
		if x >= 3 and x <= w - 4 and y >= 9 and y <= h - 2 then
			local selection = y - 8 + fileScroll
			local name = files[selection]

			if name == "Back [..]" and currentDirectory ~= "" then
				currentDirectory = currentDirectory:sub(1, currentDirectory:find(fs.getName(currentDirectory)) - 2)
				fileScroll = 0
				edit_draw()
				return {text = currentDirectory .. "/"}
			elseif fs.isDir(currentDirectory .. "/" .. name) then
				currentDirectory = currentDirectory .. "/" .. name
				fileScroll = 0
				edit_draw()
				return {text = currentDirectory .. "/"}
			elseif fileTypes:find("open") then
				return {text = currentDirectory .. "/" .. name, exit = true}
			end
		end

	elseif event == "mouse_fileScroll" then
		if key > 0 and fileScroll + (h - 10) < #files then
			fileScroll = fileScroll + 1
		elseif key < 0 and fileScroll > 0 then
			fileScroll = fileScroll - 1
		end
	end
end


fileSelect_main = function(selectType, callback)
	edit_draw()
	term.setBackgroundColor(theme.top)
	fill(2, 6, w - 2, 3)
	term.setCursorPos(3, 7)
	term.write("Path: ")

	if selectType:find("new") then
		local path = modifiedRead({startingText = "/", displayLength = w - 4, onEvent = file.select.onEvent})
		if path:sub(1, 1) ~= "/" then
			path = "/" .. path
		end

		return path

	elseif selectType:find("open") then
		local text = "/"

		term.setTextColor(theme.text)
		term.setCursorPos(9, 7)
		term.write(text)

		while true do
			local event, key, x, y = os.pullEvent()
			local action = onEvent(text, event, key, x, y)

			if action and action.text then
				text = action.text

				if text then
					term.setTextColor(theme.text)
					term.setCursorPos(9, 7)
					term.write(string.rep(" ", w - 11))
					term.setCursorPos(9, 7)
					term.write(text)
				end
			end

			if action and action.exit then
				return text
			end
		end
	end
end



file_newFile = function()
	clear()
	title("Lua IDE : New File")
	local path = selectFile("new")
	if not path then
		return "menu"
	end

	return "edit", path
end


file_openFile = function()
	clear()
	title("Lua IDE : Open File")
	local path = selectFile("open")
	if not path then
		return "menu"
	end

	return "edit", path
end




--    Languages


languages.lua = {}
languages.brainfuck = {}
languages.none = {}


languages.lua.keywords = {
	["and"] = "conditional",
	["break"] = "conditional",
	["do"] = "conditional",
	["else"] = "conditional",
	["elseif"] = "conditional",
	["end"] = "conditional",
	["for"] = "conditional",
	["function"] = "conditional",
	["if"] = "conditional",
	["in"] = "conditional",
	["local"] = "conditional",
	["not"] = "conditional",
	["or"] = "conditional",
	["repeat"] = "conditional",
	["return"] = "conditional",
	["then"] = "conditional",
	["until"] = "conditional",
	["while"] = "conditional",

	["true"] = "constant",
	["false"] = "constant",
	["nil"] = "constant",

	["print"] = "function",
	["write"] = "function",
	["sleep"] = "function",
	["pairs"] = "function",
	["ipairs"] = "function",
	["loadstring"] = "function",
	["loadfile"] = "function",
	["dofile"] = "function",
	["rawset"] = "function",
	["rawget"] = "function",
	["setfenclosing"] = "function",
	["getfenclosing"] = "function",
}


languages.lua.parseError = function(err)
	local parsedErr = {
		filename = "unknown",
		line = -1,
		display = "Unknown!",
		err = ""
	}

	if err and err ~= "" then
		parsedErr.err = err
		if err:find(":") then
			parsedErr.filename = err:sub(1, err:find(":") - 1):gsub("^%s*(.-)%s*$", "%1")

			err = (err:sub(err:find(":") + 1) .. ""):gsub("^%s*(.-)%s*$", "%1") .. ""
			if err:find(":") then
				parsedErr.line = err:sub(1, err:find(":") - 1)
				if tonumber(parsedError.line) then
					parsedError.line = tonumber(parsedError.line)
				end

				err = err:sub(err:find(":") + 2):gsub("^%s*(.-)%s*$", "%1") .. ""
			end
		end

		parsedErr.display = err:sub(1, 1):upper() .. err:sub(2, -1) .. "."
	end

	return parsedErr
end


languages.lua.getCompilerErrors = function(code)
	local _, err = loadstring(code)
	if err then
		local a = err:find("]", 1, true)
		if a then
			err = "string" .. err:sub(a + 1, -1)
		end

		return languages.lua.parseError(err)
	else
		return languages.lua.parseError(nil)
	end
end


languages.lua.run = function(path, arguments)
	local fn, err = loadfile(path)
	setfenclosing(fn, getfenclosing())
	if not err then
		_, err = pcall(function() fn(unpack(arguments)) end)
	end

	return err
end




languages.brainfuck.keywords = {}


languages.brainfuck.parseError = function(err)
	local parsedError = {filename = "unknown", line = -1, display = "Unknown!", err = ""}
	if err and err ~= "" then
		parsedError.err = err
		parsedError.line = err:sub(1, err:find(":") - 1)
		if tonumber(parsedError.line) then
			parsedError.line = tonumber(parsedError.line)
		end

		err = err:sub(err:find(":") + 2):gsub("^%s*(.-)%s*$", "%1") .. ""

		parsedError.display = err:sub(1, 1):upper() .. err:sub(2, -1) .. "."
	end

	return parsedError
end


languages.brainfuck.mapLoops = function(code)
	local loopLocations = {}
	local loc = 1
	local line = 1

	for let in string.gmatch(code, ".") do
		if let == "[" then
			loopLocations[loc] = true
		elseif let == "]" then
			local found = false
			for i = loc, 1, -1 do 
				if loopLocations[i] == true then
					loopLocations[i] = loc
					found = true
				end
			end

			if not found then
				return line .. ": No matching '['"
			end
		end

		if let == "\n" then
			line = line + 1
		end
		loc = loc + 1
	end

	return loopLocations
end


languages.brainfuck.getCompilerErrors = function(code)
	local a = languages.brainfuck.mapLoops(code)
	if type(a) == "string" then
		return languages.brainfuck.parseError(a)
	else
		return languages.brainfuck.parseError(nil)
	end
end


languages.brainfuck.run = function(path)
	local f = io.open(path, "r")
	local content = f:read("*a")
	f:close()

	local dataCells = {}
	local dataPointer = 1
	local instructionPointer = 1

	local loopLocations = languages.brainfuck.mapLoops(content)
	if type(loopLocations) == "string" then
		return loopLocations
	end

	local cdp = function()
		if not dataCells[tostring(dataPointer)] then
			dataCells[tostring(dataPointer)] = 0
		end
	end

	while true do
		local let = content:sub(instructionPointer, instructionPointer)

		if let == ">" then
			dataPointer = dataPointer + 1
			cdp()
		elseif let == "<" then
			cdp()
			dataPointer = dataPointer - 1
			cdp()
		elseif let == "+" then
			cdp()
			dataCells[tostring(dataPointer)] = dataCells[tostring(dataPointer)] + 1
		elseif let == "-" then
			cdp()
			dataCells[tostring(dataPointer)] = dataCells[tostring(dataPointer)] - 1
		elseif let == "." then
			cdp()
			if term.getCursorPos() >= w then print("") end
			write(string.char(math.max(1, dataCells[tostring(dataPointer)])))
		elseif let == "," then
			cdp()
			term.setCursorBlink(true)
			local e, key = os.pullEvent("char")
			term.setCursorBlink(false)
			dataCells[tostring(dataPointer)] = string.byte(key)

			if term.getCursorPos() >= w then
				print("")
			end
			write(key)
		elseif let == "/" then
			cdp()
			if term.getCursorPos() >= w then print("") end
			write(dataCells[tostring(dataPointer)])
		elseif let == "[" and dataCells[tostring(dataPointer)] == 0 then
			for k, closing in pairs(loopLocations) do
				if k == instructionPointer then
					instructionPointer = closing
				end
			end
		elseif let == "]" then
			for k, closing in pairs(loopLocations) do
				if closing == instructionPointer then
					instructionPointer = k - 1
				end
			end
		end

		instructionPointer = instructionPointer + 1
		if instructionPointer > content:len() then
			print("")
			break
		end
	end
end




languages.none.keywords = {}

languages.none.parseError = function(err)
	return {filename = "", line = -1, display = "", err = ""}
end

languages.none.getCompilerErrors = function(code)
	return languages.none.parseError(nil)
end

languages.none.run = function(path) end




--    File Save Management


file_save = function(path, lines)
	local dir = path:sub(1, path:len() - fs.getName(path):len())
	if not fs.exists(dir) then
		fs.makeDir(dir)
	end

	if not fs.isDir(path) and not fs.isReadOnly(path) then
		local contents = ""
		for _, closing in pairs(lines) do
			contents = contents .. closing .. "\n"
		end

		local f = io.open(path, "w")
		f:write(a)
		f:close()
		return true
	else
		return false
	end
end


file_load = function(path)
	if not fs.exists(path) then
		local dir = path:sub(1, path:len() - fs.getName(path):len())
		if not fs.exists(dir) then
			fs.makeDir(dir)
		end

		local f = io.open(path, "w")
		f:write("")
		f:close()
	end

	local lines = {}
	if fs.exists(path) and not fs.isDir(path) then
		local f = io.open(path, "r")
		if f then
			local line = f:read("*lines")
			while a do
				table.insert(lines, line)
				line = f:read("*lines")
			end
			f:close()
		end
	else
		return nil
	end

	if #lines == 0 then
		table.insert(lines, "")
	end

	return lines
end




--    Clipboard


local clipboard_cut = function(lines, y)
	clipboard = lines[y]
	table.remove(lines, y)
	return lines
end


local clipboard_copy = function(lines, y)
	clipboard = lines[y]
end


local clipboard_paste = function(lines, y)
	if clipboard then
		table.insert(lines, y, clipboard)
	end
	return lines
end


local removeLine = function(lines, y)
	table.remove(lines, y)
	return lines
end


local clearLine = function(lines, y)
	lines[y] = ""
	return lines
end

local setSyntax = function(lines)
	if currentLanguage == languages.brainfuck and lines[1] ~= "-- Syntax: Brainfuck" then
		table.insert(lines, 1, "-- Syntax: Brainfuck")
	end

	return lines
end




--    Reindenting


local reindent = function(lines)
	
end




--    Editor


local x = 1
local y = 1
local offsetX = 0
local offsetY = 1
local scrollX = 0
local scrollY = 0

local editorWidth = 0
local editorHeight = h - offsetY

local lines = {}

local autosaveClock = 0
local scrollClock = 0
local liveErrorClock = 0
local hasScrolled = false

local displayErrorCode = false
local liveError = currentLanguage.parseError(nil)

local liveCompletions = {
	["("] = ")",
	["{"] = "}",
	["["] = "]",
	["\""] = "\"",
	["'"] = "'",
}

local standardsCompletions = {
	"if%s+.+%s+then%s*$",
	"for%s+.+%s+do%s*$",
	"while%s+.+%s+do%s*$",
	"repeat%s*$",
	"function%s+[a-zA-Z_0-9]?\(.*\)%s*$",
	"=%s*function%s*\(.*\)%s*$",
	"else%s*$",
	"elseif%s+.+%s+then%s*$"
}




--    Menu


local menu_items = {
	{"File",
		"About",
		"Settings",
		"New File  ^+N",
		"Open File ^+O",
		"Save File ^+S",
		"Close     ^+W",
		"Print     ^+P",
		"Quit      ^+Q"
	}, {"Edit",
		"Cut Line   ^+X",
		"Copy Line  ^+C",
		"Paste Line ^+V",
		"Delete Line",
		"Clear Line"
	}, {"Functions",
		"Go To Line    ^+G",
		"Re-Indent     ^+I",
		"Set Syntax    ^+E",
		"Start of Line ^+<",
		"End of Line   ^+>"
	}, {"Run",
		"Run Program       ^+R",
		"Run w/ Args ^+Shift+R"
	}
}


local menu_shortcuts = {
	-- File
	["ctrl n"] = "New File  ^+N",
	["ctrl o"] = "Open File ^+O",
	["ctrl s"] = "Save File ^+S",
	["ctrl w"] = "Close     ^+W",
	["ctrl p"] = "Print     ^+P",
	["ctrl q"] = "Quit      ^+Q",

	-- Edit
	["ctrl x"] = "Cut Line   ^+X",
	["ctrl c"] = "Copy Line  ^+C",
	["ctrl v"] = "Paste Line ^+V",

	-- Functions
	["ctrl g"] = "Go To Line    ^+G",
	["ctrl i"] = "Re-Indent     ^+I",
	["ctrl e"] = "Set Syntax    ^+E",
	["ctrl 203"] = "Start of Line ^+<",
	["ctrl 205"] = "End of Line   ^+>",

	-- Run
	["ctrl r"] = "Run Program       ^+R",
	["ctrl shift r"] = "Run w/ Args ^+Shift+R"
}


local menu_functions = {
	-- Return Properties
	-- - action
	-- - lines
	-- - cursorY

	-- File
	["About"] = function() about() end,
	["Settings"] = function() return {action = "settings"} end,
	["New File  ^+N"] = function() return {action = "new"} end,
	["Open File ^+O"] = function() return {action = "open"} end,
	["Save File ^+S"] = function() end,
	["Close     ^+W"] = function() return {action = "menu_items"} end,
	["Print     ^+P"] = function() end,
	["Quit      ^+Q"] = function() return {action = "exit"} end,

	-- Edit
	["Cut Line   ^+X"] = function(path, lines, y) return {lines = clipboard_cut(lines, y)} end,
	["Copy Line  ^+C"] = function(path, lines, y) clipboard_copy(lines, y) end,
	["Paste Line ^+V"] = function(path, lines, y) return {lines = clipboard_paste(lines, y)} end,
	["Delete Line"] = function(path, lines, y) return {lines = removeLine(lines, y)} end,
	["Clear Line"] = function(path, lines, y) return {lines = clearLine(lines, y)} end,

	-- Functions
	["Go To Line    ^+G"] = function() return {"cursorY" = goto()} end,
	["Re-Indent     ^+I"] = function(path, lines) return {lines = reindent(lines)} end,
	["Set Syntax    ^+E"] = function(path, lines) return {lines = setSyntax(lines)} end,
	["Start of Line ^+<"] = function() os.queueEvent("key", keys.home) end,
	["End of Line   ^+>"] = function() os.queueEvent("key", keys.end) end,

	-- Run
	["Run Program       ^+R"] = function(path, lines) run(path, lines, false) end,
	["Run w/ Args ^+Shift+R"] = function(path, lines) run(path, lines, true) end,
}




--    Editor Setup


edit_setup = function(path)
	lines = loadFile(path)
	if not lines then
		return "menu_items"
	end

	if lines[1] == "-- Syntax: Brainfuck" then
		currentLanguage = languages.brainfuck
	end

	x = 1
	y = 1
	offsetX = 0
	offsetY = 1
	scrollX = 0
	scrollY = 0

	editorWidth = 0
	editorHeight = h - offsetY

	autosaveClock = os.clock()
	scrollClock = os.clock()
	liveErrorClock = os.clock()
	hasScrolled = false

	displayErrorCode = false
	liveError = currentLanguage.parseError(nil)

	edit_draw()
	term.setCursorPos(x + offsetX, y + offsetY)
	term.setCursorBlink(true)
end




--    Editor Menu


menu_draw = function(open)
	-- Top row
	term.setCursorPos(1, 1)
	term.setTextColor(theme.text)
	term.setBackgroundColor(theme.backgroundHighlight)
	term.clearLine()

	-- Main menu items
	local padding = 3
	local curX = 0
	for _, item in pairs(menu_items) do
		term.setCursorPos(padding + curX, 1)
		term.write(item[1])
		curX = curX + item[1]:len() + padding
	end

	if open then
		-- Get the main menu item
		local item = {}
		local x = 1
		for _, test in pairs(menu_items) do
			if open == test[1] then
				item = test
				break
			end

			x = x + test[1]:len() + padding
		end
		x = x + 1

		-- Get each item under the main menu item
		local items = {}
		for i = 2, #item do
			table.insert(items, item[i])
		end

		-- Get the maximum length of these items
		local width = 1
		for _, item in pairs(items) do
			if item:len() + 2 > width then
				width = item:len() + 2
			end
		end

		-- Draw items
		fill(x, offsetY + 1, width, #items)
		for i, item in pairs(items) do
			term.setCursorPos(x + 1, i + offsetY)
			term.write(item)
		end

		-- One more row for padding
		term.setCursorPos(x, #items + 2)
		term.write(string.rep(" ", width))

		return items, width
	end
end


menu_trigger = function(cx, cy)
	-- Determine clicked menu
	local padding = 3
	local curX = 0
	local clicked = nil
	for _, item in pairs(menu) do
		if cx >= curX + padding and cx <= curX + item[1]:len() + 2 then
			clicked = item[1]
			break
		end

		curX = curX + item[1]:len() + padding
	end

	local menuX = curX + 2
	if not clicked then
		return false
	end

	-- Flash menu item
	term.setCursorBlink(false)
	term.setCursorPos(menuX, 1)
	term.setBackgroundColor(theme.background)
	term.write(string.rep(" ", clicked:len() + 2))
	term.setCursorPos(menuX + 1, 1)
	term.write(clicked)
	sleep(0.1)

	local items, width = drawMenu(clicked)
	local action = nil
	local ox, oy = term.getCursorPos()

	while not action do
		local e, but, x, y = os.pullEvent()

		if e == "mouse_click" then
			-- Click outside menu bounds
			if x < menuX - 1 or x > menuX + width - 1 then
				break
			elseif y > #items + 2 then
				break
			elseif y == 1 then
				break
			end

			for i, v in ipairs(items) do
				if y == i + 1 and x >= menuX and x <= menuX + width - 2 then
					-- Flash
					term.setBackgroundColor(theme.background)
					fill(menuX, y, width, 1)
					term.setCursorPos(menuX + 1, y)
					term.write(v)
					sleep(0.1)

					drawMenu(clicked)

					action = v
					break
				end
			end
		end
	end

	term.setCursorPos(ox, oy)
	term.setCursorBlink(true)
	return action
end


menu_executeItem = function(item, path)
	if menu_functions[item] then
		file_save(path, lines)
		local actions = menu_functions[item](path, lines, y)

		term.setCursorBlink(false)
		if actions then
			if actions.action then
				return actions.action
			end
			if actions.lines then
				lines = actions.lines

				if #lines < 1 then
					table.insert(lines, "")
				end
				y = math.min(y, #lines)
				x = math.min(x, lines[y]:len() + 1)
			end
			if actions.cursorY then
				x = 1
				y = math.min(#lines, actions.cursorY)
				edit_setCursorLocation(x, y)
			end
		end

		term.setCursorBlink(true)
		draw()
		term.setCursorPos(x - scrollX + offsetX, y - scrollY + offsetY)
	end
end




--    Editor Drawing


edit_draw = function()
	clear()
	menu_draw()

	offsetX = tostring(#lines):len() + 1
	offsetY = 1
	editorWidth = w - offsetX
	editorHeight = h - 1

	for i = 1, editorHeight do
		local line = lines[scrollY + i]
		if line then
			-- Line number
			local lineNumber = string.rep(" ", offsetX - 1 - tostring(scrollY + i):len()) .. tostring(scrollY + i) .. ":"

			if liveError.line == scrollY + i then
				lineNumber = string.rep(" ", offsetX - 2) .. "!:"
			end

			term.setCursorPos(1, i + offsetY)
			term.setTextColor(theme.text)

			-- Line background
			term.setBackgroundColor(theme.background)
			if scrollY + i == y then
				if scrollY + i == liveError.line and os.clock() - lastEventClock > 3 then
					term.setBackgroundColor(theme.editor_errorLineHighlight)
				else
					term.setBackgroundColor(theme.editor_lineHightlight)
				end
			elseif scrollY + i == liveError.line then
				term.setBackgroundColor(theme.editor_errorLine)
			end
			term.clearLine()

			-- Text
			term.setCursorPos(1 - scrollX + offsetX, i + offsetY)
			if scrollY + i == liveError.line then
				if displayErrorCode then
					term.write(liveError.display)
				else
					term.write(line)
				end
			else
				writeHighlighted(line)
			end

			-- Line numbers
			term.setCursorPos(1, i + offsetY)
			if scrollY + i == y then
				if scrollY + i == liveError.line and os.clock() - lastEventClock > 3 then
					term.setBackgroundColor(theme.editor_errorLine)
				else
					term.setBackgroundColor(theme.editor_lineNumberHighlight)
				end
			elseif scrollY + i == liveError.line then
				term.setBackgroundColor(theme.editor_errorLineHighlight)
			else
				term.setBackgroundColor(theme.editor_lineNumber)
			end
			term.write(lineNumber)
		end
	end

	term.setCursorPos(x - scrollX + offsetX, y - scrollY + offsetY)
end


edit_drawLine = function(...)
	local linesToDraw = {...}
	offsetX = tostring(#lines):len() + 1

	for _, lineY in pairs(linesToDraw) do
		local line = lines[lineY]
		if line then
			-- Line number
			local lineNumber = string.rep(" ", offsetX - 1 - tostring(lineY):len()) .. tostring(lineY) .. ":"

			if liveError.line == lineY then
				lineNumber = string.rep(" ", offsetX - 2) .. "!:"
			end

			term.setCursorPos(1, (lineY - scrollY) + offsetY)
			term.setBackgroundColor(theme.background)

			-- Background color
			if lineY == y then
				if lineY == liveError.line and os.clock() - lastEventClock > 3 then
					term.setBackgroundColor(theme.editor_errorLineHighlight)
				else
					term.setBackgroundColor(theme.editor_lineHightlight)
				end
			elseif lineY == liveError.line then
				term.setBackgroundColor(theme.editor_errorLine)
			end
			term.clearLine()

			-- Text
			term.setCursorPos(1 - scrollX + offsetX, (lineY - scrollY) + offsetY)
			if lineY == liveError.line then
				if displayErrorCode then
					term.write(liveError.display)
				else
					term.write(line)
				end
			else
				writeHighlighted(line)
			end

			-- Line Number
			term.setCursorPos(1, (lineY - scrollY) + offsetY)
			if lineY == y then
				if lineY == liveError.line and os.clock() - lastEventClock > 3 then
					term.setBackgroundColor(theme.editor_errorLine)
				else
					term.setBackgroundColor(theme.editor_lineNumberHighlight)
				end
			elseif lineY == liveError.line then
				term.setBackgroundColor(theme.editor_errorLineHighlight])
			else
				term.setBackgroundColor(theme.editor_lineNumber)
			end
			term.write(lineNumber)
		end
	end

	term.setCursorPos(x - scrollX + offsetX, y - scrollY + offsetY)
end




--    Editor Event Handling


edit_setCursorLocation = function(nx, ny)
	local nScrollX, nScrollY = nx - scrollX, ny - scrollY
	local redraw = false

	if nScrollX < 1 then
		scrollX = nx - 1
		nScrollX = 1
		redraw = true
	elseif nScrollX > editorWidth then
		scrollX = nx - editorWidth
		nScrollX = editorWidth
		redraw = true
	end

	if nScrollY < 1 then
		scrollY = y - 1
		nScrollY = 1
		redraw = true
	elseif nScrollY > editorHeight then
		scrollY = y - editorHeight
		nScrollY = editorHeight
		redraw = true
	end

	if redraw or y - scrollY + offsetY < offsetY + 1 then
		edit_draw()
	end

	term.setCursorPos(nScrollX + offsetX, nScrollY + offsetY)
end


edit_handleKey = function(key)
	if key == keys.up and y > 1 then
		x = math.min(x, lines[y - 1]:len() + 1)
		y = y - 1
		edit_drawLine(y, y + 1)
		edit_setCursorLocation(x, y)

	elseif key == keys.down and y < #lines then
		x = math.min(x, lines[y + 1]:len() + 1)
		y = y + 1
		edit_drawLine(y, y - 1)
		edit_setCursorLocation(x, y)

	elseif key == keys.left and x > 1 then
		x = x - 1
		edit_setCursorLocation(x, y)

	elseif key == keys.right and x < lines[y]:len() + 1 then
		x = x + 1
		edit_setCursorLocation(x, y)

	elseif (key == keys.enter or key == keys.numPadEnter) then
		if displayErrorCode or y + scrollY - 1 == liveError.line then
			return
		end

		local completion = nil
		for _, completion in pairs(standardsCompletions) do
			if lines[y]:find(completion) and x == #lines[y] + 1 then -- If there is a completion, and the cursor is at the end of the line
				completion = completion
			end
		end

		-- Count the number of spaces at the start of the line
		local _, spaces = lines[y]:find("^[ ]+")
		if not spaces then
			spaces = 0
		end

		if completion then
			table.insert(lines, y + 1, string.rep(" ", spaces + 2))

			-- Insert the second line
			if not completion:find("else", 1, true) and not completion:find("elseif", 1, true) then
				local line = string.rep(" ", spaces)
				if completion:find("repeat", 1, true) then
					line = line .. "until "
				elseif completion:find("{", 1, true) then
					line = line .. "}"
				else
					line = line .. "end"
				end

				table.insert(lines, y + 2, line)
			end

			x = spaces + 3
			y = y + 1
			edit_setCursorLocation(x, y)
		else
			local oldLine = lines[y]
			lines[y] = lines[y]:sub(1, x - 1)
			table.insert(lines, y + 1, string.rep(" ", spaces) .. oldLine:sub(x, -1))

			x = spaces + 1
			y = y + 1
			edit_setCursorLocation(x, y)
		end

	elseif key == keys.backspace then
		if displayErrorCode or y + scrollY - 1 == liveError.line then
			return
		end

		if x > 1 then
			local f = false
			for k, closing in pairs(liveCompletions) do
				if lines[y]:sub(x - 1, x - 1) == k then f = true end
			end

			lines[y] = lines[y]:sub(1, x - 2) .. lines[y]:sub(x + (f and 1 or 0), -1)
			edit_drawLine(y)
			x = x - 1
			edit_setCursorLocation(x, y)
		elseif y > 1 then
			local prevLen = lines[y - 1]:len() + 1
			lines[y - 1] = lines[y - 1] .. lines[y]
			table.remove(lines, y)
			x, y = prevLen, y - 1

			edit_draw()
			edit_setCursorLocation(x, y)
		end

	elseif key == keys.home then
		x = 1
		edit_setCursorLocation(x, y)

	elseif key == keys["end"] then
		x = lines[y]:len() + 1
		edit_setCursorLocation(x, y)

	elseif key == keys.delete then
		if displayErrorCode or y + scrollY - 1 == liveError.line then
			return
		end

		if x < lines[y]:len() + 1 then
			lines[y] = lines[y]:sub(1, x - 1) .. lines[y]:sub(x + 1)
			edit_drawLine(y)
			edit_setCursorLocation(x, y)
		elseif y < #lines then
			lines[y] = lines[y] .. lines[y + 1]
			table.remove(lines, y + 1)
			edit_draw()
			edit_setCursorLocation(x, y)
		end

	elseif key == keys.tab then
		if displayErrorCode or y + scrollY - 1 == liveError.line then
			return
		end

		lines[y] = string.rep(" ", tabWidth) .. lines[y]
		x = x + 2
		edit_drawLine(y)
		edit_setCursorLocation(x, y)

	elseif key == keys.pageUp then
		y = math.min(math.max(y - editorHeight, 1), #lines)
		x = math.min(lines[y]:len() + 1, x)
		edit_setCursorLocation(x, y, true)

	elseif key == keys.pageDown then
		y = math.min(math.max(y + editorHeight, 1), #lines)
		x = math.min(lines[y]:len() + 1, x)
		edit_setCursorLocation(x, y, true)
	end
end


edit_handleChar = function(key)
	if displayErrorCode or y + scrollY - 1 == liveError.line then
		return
	end

	-- If we are typing the second character of a live completion (eg the second ")
	local shouldIgnore = false
	for opening, closing in pairs(liveCompletions) do
		if key == closing and lines[y]:find(opening, 1, true) and lines[y]:sub(x, x) == closing then
			shouldIgnore = true
		end
	end

	-- Whether to add the second character of a live completions (eg the second " after typing the first)
	local addOne = nil
	if not shouldIgnore then
		for opening, closing in pairs(liveCompletions) do
			if key == opening and lines[y]:sub(x, x) ~= opening then
				addOne = closing
			end
		end

		lines[y] = lines[y]:sub(1, x - 1) .. key .. (addOne and addOne or "") .. lines[y]:sub(x, -1)
	end

	x = x + key:len()
	edit_drawLine(y)
	edit_setCursorLocation(x, y)
end


edit_handleMouseClick = function(button, cx, cy)
	if cy > 1 then
		if cx <= offsetX and cy - offsetY == liveError.line - scrollY then
			-- Trigger showing the live error text
			displayErrorCode = not displayErrorCode
			edit_drawLine(liveError.line)
		else
			local oldy = y
			y = math.min(math.max(scrollY + cy - offsetY, 1), #lines)
			x = math.min(math.max(scrollX + cx - offsetX, 1), lines[y]:len() + 1)

			if oldy ~= y then
				edit_drawLine(oldy, y)
			end
			edit_setCursorLocation(x, y)
		end
	else
		local selectedMenu = triggerMenu(cx, cy)
		if selectedMenu then
			local action = menu_executeItem(selectedMenu, path)
			if action then
				return action
			end
		end
	end
end


edit_handleShortcut = function(modifier, key)
	local item = menu_shortcuts[modifier .. " " .. key]
	if item then
		-- Find the parent menu item
		local parent = nil
		local curX = 0
		for i, potentialParent in pairs(menu_items) do
			for _, subItem in pairs(potentialParent) do
				if subItem == item then
					parent = menu_items[i][1]
					break
				end
			end

			curX = curX + potentialParent[1]:len() + 3
		end
		local menuX = curX + 2

		-- Flash parent item
		term.setCursorBlink(false)
		term.setBackgroundColor(colors[theme.background])
		fill(menuX, 1, parent:len() + 2, 1)
		term.setCursorPos(menuX + 1, 1)
		term.write(parent)
		sleep(0.1)
		drawMenu()

		-- Execute
		local action = menu_executeItem(item, path)
		if action then
			return action
		end
	end
end


edit_handleMouseScroll = function(direction)
	if direction == -1 and scrollY > 0 then
		scrollY = scrollY - 1
	elseif direction == 1 and scrollY < #lines - editorHeight then
		scrollY = scrollY + 1
	end

	if os.clock() - scrollClock > 0.0005 then
		edit_draw()
		term.setCursorPos(x - scrollX + offsetX, y - scrollY + offsetY)
	end

	scrollClock = os.clock()
	hasScrolled = true
end


edit_loop = function()
	local e, key, cx, cy = os.pullEvent()

	if e == "key" and allowEditorEvent then
		edit_handleKey(key)
	elseif e == "char" and allowEditorEvent then
		edit_handleChar(key)
	elseif e == "mouse_click" and key == 1 then
		local action = edit_handleMouseClick(key, cx, cy)
		if action then
			return action
		end
	elseif e == "shortcut" then
		local action = edit_handleShortcut(key, cx)
		if action then
			return action
		end
	elseif e == "mouse_scroll" then
		edit_handleMouseScroll(key)
	end

	if hasScrolled and os.clock() - scrollClock > 0.1 then
		edit_draw()
		term.setCursorPos(x - scrollX + offsetX, y - scrollY + offsetY)
		hasScrolled = false
	end

	if os.clock() - autosaveClock > autosaveInterval then
		saveFile(path, lines)
		autosaveClock = os.clock()
	end

	if os.clock() - liveErrorClock > 1 then
		local previousLiveError = liveError
		liveError = currentLanguage.parseError(nil)
		local code = ""
		for _, closing in pairs(lines) do
			code = code .. closing .. "\n"
		end

		liveError = currentLanguage.getCompilerErrors(code)
		liveError.line = math.min(liveError.line - 2, #lines)
		if liveError ~= previousLiveError then
			edit_draw()
		end

		liveErrorClock = os.clock()
	end
end




--    Editor Main


edit = function(path)
	local action = edit_setup()
	if action then
		return action
	end
	
	while true do
		local action = edit_loop()
		if action then
			return action
		end
	end

	return "menu"
end




--    Main


local main = function(programArgs)
	local option = "menu"
	local args = nil

	if #programArgs > 0 then
		local path = "/" .. shell.resolve(programArgs[1])
		if fs.isDir(path) then
			print("Cannot edit a directory.")
			return
		else
			option = "edit"
			args = path
		end
	end


	while true do
		if option == "menu" then
			option = menu_items()
		end

		if option == "new" then
			option, args = file_newFile()
		end

		if option == "open" then
			option, args = file_openFile()
		end

		if option == "settings" then
			option = settings()
		end

		if option == "exit" then
			break
		end

		if option == "edit" and args then
			option = edit(args)
		end
	end
end


local success, err = pcall(function()
	main(args)
end)


term.setCursorBlink(false)
if err and not err:find("Terminated") then
	clear()
	title("Lua IDE : Crash Report")
	top("Lua IDE encountered an unexpected crash.", "Please report this error to GravityScore.")

	term.setBackgroundColor(theme.background)
	print(err)
	print("")

	bottom("Press any key to exit.")
	
	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end


term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
center("Thank You for Using Lua IDE " .. version)
center("Made by GravityScore")
