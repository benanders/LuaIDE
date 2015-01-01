
--
--  Editor
--

--- An editor.
--- Controls the state of an editor for a single file.
Editor = {}
Editor.__index = Editor


--- Create a new editor from the lines of text to edit, and its size.
function Editor.new(...)
	local self = setmetatable({}, Editor)
	self:setup(...)
	return self
end


function Editor:setup(lines, width, height)

end


--- Move the cursor to an absolute position within the document.
function Editor:moveCursorTo(x, y)

end


--- Move the cursor to a position relative to the top left of
--- the editor window.
function Editor:moveCursorToRelative(x, y)

end


--- Move the cursor up a single line.
function Editor:moveCursorUp()

end


--- Move the cursor down a single line.
function Editor:moveCursorDown()

end


--- Move the cursor left one character.
function Editor:moveCursorLeft()

end


--- Move the cursor right one character.
function Editor:moveCursorRight()

end


--- Scroll up one line.
function Editor:scrollUp()

end


--- Scroll down one line.
function Editor:scrollDown()

end


--- Move the cursor to the start of the current line.
function Editor:moveCursorToStartOfLine()

end


--- Move the cursor to the end of the current line.
function Editor:moveCursorToEndOfLine()

end


--- Move the cursor to the start of the file.
function Editor:moveCursorToStartOfFile()

end


--- Move the cursor to the end of the file.
function Editor:moveCursorToEndOfFile()

end


--- Move the cursor to the start of a particular line.
--- The line number is given as absolute within the file.
function Editor:moveCursorToLine(y)

end


--- Move up one page. A page's height is equal to the
--- height of the editor.
function Editor:pageUp()

end


--- Move down one page. A page's height is equal to the
--- height of the editor.
function Editor:pageDown()

end


--- Returns the x and y location of the cursor on screen,
--- relative to the top left of the editor's window.
function Editor:cursorPosition()

end


--- Delete the character behind the current cursor position.
function Editor:backspace()

end


--- Delete the character in front of the current cursor position.
function Editor:forwardDelete()

end


--- Insert a character at the current cursor position.
function Editor:insertCharacter(character)

end


--- Insert a newline at the current cursor position.
function Editor:insertNewline()

end


--- Returns the size of the gutter.
function Editor:gutterSize()

end


--- Returns what needs to be redrawn.
--- The first return argument is a string, and the second is
--- data. Can be:
--- * `full`, nil - Entire screen needs redrawing.
--- * `line`, lines - A line or lines needs redrawing
--- * `gutter`, lines - The gutter on a line or lines needs redrawing
function Editor:dirty()

end



--
--  Tests
--

--- Test the editor.
function Editor.test()
	Editor.testCursorMovement()
end


--- Assert the location of an editor's cursor.
function Editor.assertCursor(editor, x, y, sx, sy)
	if not sx then
		sx = 0
	end
	if not sy then
		sy = 0
	end

	local cx, cy = editor:cursorPosition()
	assert(cx == x)
	assert(cy == y)
	assert(editor.cursor.x == x)
	assert(editor.cursor.y == y)
	assert(editor.scroll.x == sx)
	assert(editor.scroll.y == sy)
end


--- Test cursor movement.
---
--- Test moving left, right, up down
--- Test not moving off the edge (right) of a line
--- Test not moving before the start of a line
--- Test moves to end of line when moving from longer line.
function Editor.testCursorMovement()
	local editor = Editor.new({
		"to",
		"a",
		"third line!",
	}, 20, 5)

	-- Ensure the initial state
	local x, y = editor:cursorPosition()
	Editor.assertCursor(editor, 1, 1)

	-- Test movement
	editor:moveCursorLeft()
	Editor.assertCursor(editor, 2, 1)
	editor:moveCursorDown()
	Editor.assertCursor(editor, 2, 2)
	editor:moveCursorUp()
	Editor.assertCursor(editor, 2, 1)
	editor:moveCursorRight()
	Editor.assertCursor(editor, 3, 1)

	-- Test not moving off right edge
	for i = 1, 5 do
		editor:moveCursorRight()
		Editor.assertCursor(editor, 3, 1)
	end

	-- Test moves to end of line when moving from a longer one
	editor:moveCursorDown()
	Editor.assertCursor(editor, 2, 2)
	editor:moveCursorDown()
	for i = 1, 3 do
		editor:moveCursorRight()
	end
	editor:moveCursorUp()
	Editor.assertCursor(editor, 2, 2)

	-- Test not moving off left edge
	editor:moveCursorLeft()
	for i = 1, 5 do
		editor:moveCursorLeft()
		Editor.assertCursor(editor, 1, 2)
	end
end
