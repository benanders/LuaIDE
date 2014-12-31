
--
--  Compiler
--  By Oeed
--


local mainFile = "main.lua"

local file = [[

--
--  Firewolf
--  By GravityScore and 1lann
--
--  Credits:
--  * Files compiled together using Compilr by Oeed
--  * RC4 Implementation by AgentE382
--  * Base64 Implementation by KillaVanilla
--


]]

local files = {}

local function addFolder(path, tree)
	for i, v in ipairs(fs.list(path)) do
		local subPath = path .. "/" .. v

		local isProtectedFile = subPath == "/rom" or subPath == "/build"
		local isRunningFile = subPath == "/" .. shell.getRunningProgram()
		if v == ".DS_Store" or v == ".git" or isProtectedFile or isRunningFile then
			-- Ignore
		elseif fs.isDir(subPath) then
			tree[v] = {}
			addFolder(subPath, tree[v])
		else
			local h = fs.open(subPath, "r")
			if h then
				tree[v] = h.readAll()
				h.close()
			end
		end
	end
end

addFolder("", files)

if not files[mainFile] then
	error("You must have a file called " .. mainFile .. " to be executed at runtime.")
end

file = file .. "local files = " .. textutils.serialize(files) .. "\n"

file = file .. [[

local function run(args)
	local fnFile, err = loadstring(files[ ]] .. mainFile .. [[ ], "]] .. mainFile .. [[")
	if err then
		error(err)
	end

	local function split(str, pat)
		local t = {}
		local fpat = "(.-)" .. pat
		local last_end = 1
		local s, e, cap = str:find(fpat, 1)
		while s do
			if s ~= 1 or cap ~= "" then
				table.insert(t, cap)
			end
			last_end = e + 1
			s, e, cap = str:find(fpat, last_end)
		end

		if last_end <= #str then
			cap = str:sub(last_end)
			table.insert(t, cap)
		end
		return t
	end

	local function resolveTreeForPath(path, single)
		local _files = files
		local parts = split(path, "/")
		if parts then
			for i, v in ipairs(parts) do
				if #v > 0 then
					if _files[v] then
						_files = _files[v]
					else
						_files = nil
						break
					end
				end
			end
		elseif #path > 0 and path ~= "/" then
			_files = _files[path]
		end
		if not single or type(_files) == "string" then
			return _files
		end
	end

	local oldFs = fs
	local env
	env = {
		fs = {
			list = function(path)
				local list = {}
				if fs.exists(path) then
					list = fs.list(path)
				end
				for k, v in pairs(resolveTreeForPath(path)) do
					if not fs.exists(path .. "/" ..k) then
						table.insert(list, k)
					end
				end
				return list
			end,

			exists = function(path)
				if fs.exists(path) then
					return true
				elseif resolveTreeForPath(path) then
					return true
				else
					return false
				end
			end,

			isDir = function(path)
				if fs.isDir(path) then
					return true
				else
					local tree = resolveTreeForPath(path)
					if tree and type(tree) == "table" then
						return true
					else
						return false
					end
				end
			end,

			isReadOnly = function(path)
				if not fs.isReadOnly(path) then
					return false
				else
					return true
				end
			end,

			getName = fs.getName,
			getSize = fs.getSize,
			getFreespace = fs.getFreespace,
			makeDir = fs.makeDir,
			move = fs.move,
			copy = fs.copy,
			delete = fs.delete,
			combine = fs.combine,

			open = function(path, mode)
				if fs.exists(path) then
					return fs.open(path, mode)
				elseif type(resolveTreeForPath(path)) == "string" then
					local handle = {close = function()end}
					if mode == "r" then
						local content = resolveTreeForPath(path)
						handle.readAll = function()
							return content
						end

						local line = 1
						local lines = split(content, "\n")
						handle.readLine = function()
							if line > #lines then
								return nil
							else
								return lines[line]
							end
							line = line + 1
						end
						return handle
					else
						error("Cannot write to read-only file (compilr archived).")
					end
				else
					return fs.open(path, mode)
				end
			end
		},

		io = {
			input = io.input,
			output = io.output,
			type = io.type,
			close = io.close,
			write = io.write,
			flush = io.flush,
			lines = io.lines,
			read = io.read,
			open = function(path, mode)
				if fs.exists(path) then
					return io.open(path, mode)
				elseif type(resolveTreeForPath(path)) == "string" then
					local content = resolveTreeForPath(path)
					local f = fs.open(path, "w")
					f.write(content)
					f.close()
					if mode == "r" then
						return io.open(path, mode)
					else
						error("Cannot write to read-only file (compilr archived).")
					end
				else
					return io.open(path, mode)
				end
			end
		},

		loadfile = function(_sFile)
			local file = env.fs.open(_sFile, "r")
			if file then
				local func, err = loadstring(file.readAll(), fs.getName(_sFile))
				file.close()
				return func, err
			end
			return nil, "File not found: ".._sFile
		end,

		dofile = function(_sFile)
			local fnFile, e = env.loadfile(_sFile)
			if fnFile then
				setfenv(fnFile, getfenv(2))
				return fnFile()
			else
				error(e, 2)
			end
		end
	}

	setmetatable(env, { __index = _G })

	local tAPIsLoading = {}
	env.os.loadAPI = function(_sPath)
		local sName = fs.getName(_sPath)
		if tAPIsLoading[sName] == true then
			printError("API "..sName.." is already being loaded")
			return false
		end
		tAPIsLoading[sName] = true

		local tEnv = {}
		setmetatable(tEnv, { __index = env })
		local fnAPI, err = env.loadfile(_sPath)
		if fnAPI then
			setfenv(fnAPI, tEnv)
			fnAPI()
		else
			printError(err)
			tAPIsLoading[sName] = nil
			return false
		end

		local tAPI = {}
		for k,v in pairs(tEnv) do
			tAPI[k] =  v
		end

		env[sName] = tAPI
		tAPIsLoading[sName] = nil
		return true
	end

	env.shell = shell

	setfenv(fnFile, env)
	fnFile(unpack(args))
end

local function extract()
	local function node(path, tree)
		if type(tree) == "table" then
			fs.makeDir(path)
			for k, v in pairs(tree) do
				node(path .. "/" .. k, v)
			end
		else
			local f = fs.open(path, "w")
			if f then
				f.write(tree)
				f.close()
			end
		end
	end
	node("", files)
end

local args = {...}
if #args == 1 and args[1] == "--extract" then
	extract()
else
	run(args)
end
]]


fs.delete("/build")

local f = fs.open("/build", "w")
f.write(file)
f.close()
