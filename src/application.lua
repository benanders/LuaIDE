
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

loadLibrary(rootDirectory .. "/util/util.lua")

loadLibrary(rootDirectory .. "/editor/controller.lua")
loadLibrary(rootDirectory .. "/editor/theme.lua")
loadLibrary(rootDirectory .. "/editor/editor.lua")
loadLibrary(rootDirectory .. "/editor/content.lua")
loadLibrary(rootDirectory .. "/editor/menu.lua")
loadLibrary(rootDirectory .. "/editor/tab.lua")



--
--  Main
--

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
	Util.clear(colors.black, colors.white)
	Util.center("Thanks for using LuaIDE " .. Global.version)
	Util.center("By GravityScore")
	print()
end
