
--
--  File
--

File = {}


--- Returns the contents of a file at path as an array of lines.
--- Returns nil on failure, with an error message as the second argument.
function File.load(path)
	if not fs.exists(path) then
		return nil, "File does not exist"
	elseif fs.isDir(path) then
		return nil, "Cannot edit a directory"
	else
		local f = fs.open(path, "r")

		if f then
			local lines = {}
			local line = f.readLine()

			while line do
				table.insert(lines, line)
				line = f.readLine()
			end

			f.close()

			if #lines == 0 then
				table.insert(lines, "")
			end

			return lines
		else
			return nil, "Failed to open file"
		end
	end
end


--- Saves a set of lines to the file at path.
--- Returns nil on success, and an error message on failure.
function File.save(lines, path)
	if fs.isDir(path) then
		return "Cannot save to a directory"
	elseif fs.isReadOnly(path) then
		return "Cannot save to a read only file"
	else
		local f = fs.open(path, "w")
		if f then
			f.write(table.concat(lines, "\n"))
			f.close()
		else
			return "Failed to open file"
		end
	end

	return nil
end
