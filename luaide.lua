
--  
--  Lua IDE
--  Made by GravityScore
--  


--  -------- Variables

-- Version
local version = "1.0"
local args = {...}

-- Updating
local autoupdate = true

-- Geometry
local w, h = term.getSize()


--  -------- Drawing

local function centerPrint(text, y)
	local x, y = term.getCursorPos()
	term.setCursorPos(w/2 - text:len()/2, ny or y)
	print(text)
end


--  -------- Saving and Loading

local function saveFile(path, content)

end

local function loadFile(path)
	path = "/" .. shell.resolve(path)
end


--  -------- Compiler Errors

-- Error syntax:
-- {line = 4, display = "End Expected", err = "test:4:end expected"}

local function compilerErrors(code)

end

local function viewErrors(errs)

end


--  -------- Editing

local function edit(path)

end


--  -------- Open File

local function newFile()

end

local function openFile()

end


--  -------- Settings

local function settings()

end


--  -------- Menu

local function menu()

end


--  -------- Main

local function main(ar)
	local opt, data = "menu", nil

	-- Check arguments
	if type(ar) == "table" and #ar > 0 then
		opt, data = "edit", ar[1]
	end

	-- Main run loop
	while true do
		-- Show menu
		if opt == "menu" then opt, data = menu() end

		-- Run
		if opt == "new" then
			data = newFile()
			if data then opt = "edit" end
		elseif opt == "open" then
			data = openFile()
			if data then opt = "edit" end
		elseif opt == "settings" then
			settings()
		elseif opt == "exit" then
			break
		end

		-- Edit
		if opt == "edit" and data then
			opt = edit(data)
			if opt == "close" then opt = "menu"
			elseif opt == "exit" then break end
		end
	end
end

-- Run
main(args)

-- Exit
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
centerPrint("Thank You for Using Lua IDE " .. version)
centerPrint("Made by GravityScore")
