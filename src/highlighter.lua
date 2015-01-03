
--
--  Syntax Highlighter
--

SyntaxHighlighter = {}
SyntaxHighlighter.__index = SyntaxHighlighter


--- Tags that specify the start and end of mapped data.
--- Must be iterated in order.
--- A nil end tag means the end of the line.
SyntaxHighlighter.tags = {
	{
		["start"] = "--[[",
		["end"] = "]]",
		["kind"] = "comment",
	},
	{
		["start"] = "--",
		["end"] = nil,
		["kind"] = "comment",
	},
	{
		["start"] = "[[",
		["end"] = "]]",
		["kind"] = "string",
	},
	{
		["start"] = "\"",
		["end"] = "\"",
		["kind"] = "string",
	},
	{
		["start"] = "'",
		["end"] = "'",
		["kind"] = "string",
	},
}

--- Characters that should trigger a full redraw of the screen.
SyntaxHighlighter.fullRedrawTriggers = "-[]\"'"

--- Characters that are a valid identifier.
SyntaxHighlighter.validIdentifiers = "0-9A-Za-z_"

--- All items highlighted on a line-by-line basis.
--- Can be Lua patterns.
--- Automatically wrapped in word separators.
SyntaxHighlighter.keywords = {
	["keywords"] = {
		"break",
		"do",
		"else",
		"for",
		"if",
		"elseif",
		"return",
		"then",
		"repeat",
		"while",
		"until",
		"end",
		"function",
		"local",
		"in",
	},
	["constants"] = {
		"true",
		"false",
		"nil",
	},
	["numbers"] = {
		"[0-9]+",
	},
	["operators"] = {
		"%+",
		"%-",
		"%%",
		"#",
		"%*",
		"/",
		"%^",
		"=",
		"==",
		"~=",
		"<",
		"<=",
		">",
		">=",
		"!",
		"and",
		"or",
		"not",
	},
	["functions"] = {
		"print",
		"write",
		"sleep",
		"pairs",
		"ipairs",
		"loadstring",
		"loadfile",
		"dofile",
		"rawset",
		"rawget",
		"setfenv",
		"getfenv",
		"assert",
		"getmetatable",
		"setmetatable",
		"pcall",
		"xpcall",
		"type",
		"unpack",
		"tonumber",
		"tostring",
		"select",
		"next",
	},
}


--- Create a new syntax highlighter.
function SyntaxHighlighter.new(...)
	local self = setmetatable({}, SyntaxHighlighter)
	self:setup(...)
	return self
end


function SyntaxHighlighter:setup()
	self.lines = nil

	--- A list of starting and ending locations for
	--- coloring tags that span multiple lines, such
	--- as strings.
	--- {
	---   kind = "string|comment"
	---   startY = "absolute line y position",
	---   startX = "x position on starting line",
	---   endY = "absolute line ending y position",
	---   endX = "x position on ending line",
	--- }
	self.map = {}
end


--- Update the syntax highlighter when the contents
--- of the lines being edited changes.
function SyntaxHighlighter:update(lines)
	self.lines = lines
	self:recalculateMappedData()
end


--- Recalculate the mapped data.
function SyntaxHighlighter:recalculateMappedData()
	self.map = {}
	local current = nil
	local currentEnding = nil

	for y = 1, #self.lines do
		local line = self.lines[y]
		local position = 1

		while true do
			if current then
				if not currentEnding then
					-- Tag ends at the end of this line.
					current["endY"] = y
					current["endX"] = line:len()
					table.insert(self.map, current)
					current = nil
					currentEnding = nil
					break
				else
					-- Look for an ending tag
					local start, finish = line:find(currentEnding, position, true)

					if not start or not finish then
						-- Ending tag not on this line
						break
					else
						-- Found ending tag
						current["endY"] = y
						current["endX"] = finish
						table.insert(self.map, current)
						current = nil
						currentEnding = nil
						position = finish + 1
					end
				end
			else
				local start = nil
				local finish = nil
				local tag = nil

				-- Attempt to find a starting tag
				for _, possible in pairs(SyntaxHighlighter.tags) do
					start, finish = line:find(possible["start"], position, true)
					if start and finish then
						tag = possible
						break
					end
				end

				if not start or not finish then
					-- Could not find another starting tag
					break
				else
					-- Found starting tag
					currentEnding = tag["end"]
					current = {
						["kind"] = tag["kind"],
						["startY"] = y,
						["startX"] = start,
					}
					position = finish + 1
				end
			end
		end
	end

	if current then
		-- End the current tag at the end of the file
		current["endY"] = #self.lines
		current["endX"] = self.lines[#self.lines]:len()
		table.insert(self.map, current)
	end
end


--- Returns highlight data for a line, starting at
--- a given x scroll position.
--- The y position is absolute in the latest `lines` array.
--- Returns an array of:
--- * `text`, data - render the text
--- * `kind`, kind - change the text color for all future text.
--- `kind` is one of the indices in the keywords list, or "text" for plain text.
function SyntaxHighlighter:data(y, horizontalScroll, width)
	-- Check if covers whole line
	-- Check if covering start of line
	-- Check if covering end of line
	-- Extract text in middle
	-- Apply highlighting for start of line
	-- While true
	--  Look for first mapped data in text
	--  If not found then break
	--  Else
	--   Apply keyword highlighting to text between start and mapped data
	--   Apply highlighting for mapped data
	--   update position for mapped data
	-- Apply keyword highlighting for rest of string
	-- Apply highlighting for end of line

	local lineStart = horizontalScroll + 1
	local lineFinish = horizontalScroll + width
	local line = self.lines[y]:sub(lineStart, lineFinish)

	local startText = nil
	local startKeyword = nil
	local endText = nil
	local endKeyword = nil

	for _, data in pairs(self.map) do
		-- Covering whole line
		local onLine = data.startY == y and data.endY == y and data.startX <= lineStart
			and data.endX >= lineFinish
		local beforeLine = data.startY < y and data.endY == y and data.endX >= lineFinish
		local afterLine = data.startY == y and data.endY > y and data.startX <= lineStart
		local encaseLine = data.startY < y and data.endY > y

		-- Covers start of line
		local onStartLine = data.startY == y and data.startX <= lineStart
		local beforeStartLine = data.startY < y and data.endY == y

		-- Covers end of line
		local onEndLine = data.startY == y and data.endY == y and data.endX >= lineFinish
		local afterEndLine = data.startY == y and data.endY > y

		if onLine or beforeLine or afterLine or encaseLine then
			-- Covers whole line
			return {
				{["kind"] = "color", ["data"] = data.kind},
				{["kind"] = "text", ["data"] = line},
			}
		elseif onStartLine or beforeStartLine then
			-- Covers start of line
			startText = line:sub(1, data.endX - lineStart + 1)
			startKeyword = data.kind
		elseif onEndLine or afterEndLine then
			-- Covers end of line
			endText = line:sub(data.startX - lineStart + 1)
			endKeyword = data.kind
		end
	end

	local result = {}

	-- Apply starting text
	if startText and startText:len() > 0 then
		table.insert(result, {["kind"] = "color", ["data"] = startKeyword})
		table.insert(result, {["kind"] = "text", ["data"] = startText})
	end

	-- Add dummy start and end text so we don't have to special case the
	-- nil whenever we call len.
	if not startText then
		startText = ""
	end
	if not endText then
		endText = ""
	end

	-- Extract inner text
	line = line:sub(startText:len() + 1, -endText:len() - 1)

	if line:len() > 0 then
		local position = 1

		while true do
			-- Find first occurrence of mapped data on this line
			-- Relative to the start of the extracted inner text
			local start = nil
			local finish = nil
			local mapped = nil

			for _, data in pairs(self.map) do
				if data.startY == y and data.endY == y then
					-- Only on this line
					potentialStart = data.startX - lineStart - startText:len() + 1
					potentialFinish = data.endX - lineStart - startText:len() + 1

					if potentialStart >= position and potentialFinish >= position then
						-- Found the next mapped data
						start = potentialStart
						finish = potentialFinish
						mapped = data
						break
					end
				end
			end

			if not start or not finish or not mapped then
				-- No more mapped data left
				break
			end

			-- Extract the text between the start of the line and the mapped data
			local text = line:sub(position, start - 1)

			-- Append the text to the result, highlighting while ignoring mapped data
			self:highlight(result, text)

			-- Append the mapped data
			local mappedText = line:sub(start, finish)
			table.insert(result, {["kind"] = "color", ["data"] = mapped.kind})
			table.insert(result, {["kind"] = "text", ["data"] = mappedText})

			-- Update the position
			position = finish + 1
		end

		-- Append the final text
		local text = line:sub(position)
		self:highlight(result, text)
	end

	-- Apply ending text
	if endText and endText:len() > 0 then
		table.insert(result, {["kind"] = "color", ["data"] = endKeyword})
		table.insert(result, {["kind"] = "text", ["data"] = endText})
	end

	return result
end


--- Returns the kind for a word.
function SyntaxHighlighter:kind(word)
	-- Look for the word in each section of the keywords list
	for section, options in pairs(SyntaxHighlighter.keywords) do
		for _, option in pairs(options) do
			if word:find("^" .. option .. "$") then
				return section
			end
		end
	end

	return "text"
end


--- Highlights a piece of text, ignoring any mapped data.
function SyntaxHighlighter:highlight(result, text)
	-- Split into identifiers (letters/numbers), operators, and whitespace.
	local position = 1
	local currentKind = nil

	while position <= text:len() do
		local char = text:sub(position, position)
		local index = true
		local after = nil

		if char:match("^%s$") then
			-- Whitespace is next
			after = text:find("[^%s]", position)
			index = false
		elseif char:match("^[" .. SyntaxHighlighter.validIdentifiers .. "]$") then
			-- A word is next
			after = text:find("[^" .. SyntaxHighlighter.validIdentifiers .. "]", position)
		else
			-- Some other operator
			after = text:find("[" .. SyntaxHighlighter.validIdentifiers .. "%s]", position)
		end

		if not after then
			after = text:len() + 1
		end

		local data = text:sub(position, after - 1)

		if index then
			local kind = SyntaxHighlighter:kind(data)
			if kind ~= currentKind then
				table.insert(result, {["kind"] = "color", ["data"] = kind})
				currentKind = kind
			end
		end

		table.insert(result, {["kind"] = "text", ["data"] = data})
		position = after
	end
end
