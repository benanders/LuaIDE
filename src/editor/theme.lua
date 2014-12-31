
--
--  Theme
--


Theme = {}


--- Load the theme
Theme.load = function()
	if term.isColor() then
		-- Menu bar
		Theme["menu bar background"] = colors.white
		Theme["menu bar text"] = colors.black

		-- Tab bar
		Theme["tab bar background"] = colors.white
		Theme["tab bar background focused"] = colors.white
		Theme["tab bar background blurred"] = colors.white
		Theme["tab bar background close"] = colors.white
		Theme["tab bar text focused"] = colors.black
		Theme["tab bar text blurred"] = colors.lightGray
		Theme["tab bar text close"] = colors.red

		-- Editor
		Theme["editor background"] = colors.white
		Theme["editor text"] = colors.black

		-- Gutter
		Theme["gutter background"] = colors.white
		Theme["gutter background focused"] = colors.white
		Theme["gutter background error"] = colors.white
		Theme["gutter text"] = colors.lightGray
		Theme["gutter text focused"] = colors.gray
		Theme["gutter text error"] = colors.red
		Theme["gutter separator"] = " "
	else

	end
end
