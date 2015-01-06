
--
--  Globals
--

Global = {}

Global.version = "2.0"
Global.debug = true



--
--  Libraries
--

local function loadLibrary(path)
	local fn, err = loadfile(path)
	if err then
		error(err .. "\nFor file: " .. path)
	end

	local currentEnvironment = getfenv(1)
	setfenv(fn, currentEnvironment)
	fn()
end

loadLibrary(rootDirectory .. "/controller.lua")
loadLibrary(rootDirectory .. "/theme.lua")

loadLibrary(rootDirectory .. "/editor/content.lua")
loadLibrary(rootDirectory .. "/editor/editor.lua")
loadLibrary(rootDirectory .. "/editor/highlighter.lua")
loadLibrary(rootDirectory .. "/editor/file.lua")

loadLibrary(rootDirectory .. "/ui/menu.lua")
loadLibrary(rootDirectory .. "/ui/tab.lua")
loadLibrary(rootDirectory .. "/ui/responder.lua")
loadLibrary(rootDirectory .. "/ui/dialogue.lua")
loadLibrary(rootDirectory .. "/ui/panel.lua")
loadLibrary(rootDirectory .. "/ui/textfield.lua")



--
--  Main
--

--- Print `text` centered on the current cursor line.
--- Moves the cursor to the line below it after writing.
local function center(text)
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

local displayEnding = false

local function main(args)
	local controller = Controller.new(args)
	if controller then
		displayEnding = true
		controller:run()
	end
end

local args = {...}
local originalTerminal = term.current()
local _, err = pcall(main, args)
term.redirect(originalTerminal)

if err then
	printError(err)
	os.pullEvent("key")
	os.queueEvent("")
	os.pullEvent()
end

if displayEnding then
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)

	center("Thanks for using LuaIDE " .. Global.version)
	center("By GravityScore")
	print()
end
