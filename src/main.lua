
--
--  LuaIDE
--  GravityScore
--


local environment = {}
setmetatable(environment, {__index = _G})

local currentProgram = shell.getRunningProgram()
local rootDirectory = currentProgram:sub(1, -fs.getName(currentProgram):len() - 2)
environment["rootDirectory"] = rootDirectory
environment["shell"] = shell

local args = {...}
local fn, err = loadfile(rootDirectory .. "/application.lua")

if err then
	error(err)
else
	setfenv(fn, environment)
	fn(unpack(args))
end
