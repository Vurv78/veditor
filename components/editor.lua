---@type Component
local Component = include("../component.lua")

---@class Editor: Component
---
---@field rows string[]
---@field row_styles { fg: Color?, bg: Color?, font: string?, len: integer? }[][]
---
---@field caret { startcol: integer, endcol: integer, startrow: integer, endrow: integer }
---
---@field top_row integer
---@field max_visible_rows integer
---
---@field caret_width number
---@field padding_top number # Vertical padding between toolbox and gutter/editor.
---@field padding_left number # Horizontal padding between gutter and editor text.
---
---@field font string
---@field fonts table<string, boolean?>
---@field font_height integer
---@field font_width integer
---
---@field height number
---@field width number
---
---@field gutter DPanel
---@field gutter_len integer
---@field gutter_padding_right number
---
---@field code DPanel
local Editor = Component.new("Editor")

local default_styling = { { len = nil } }

---@param ide IDE
---@param panel Panel
function Editor:Init(ide, panel)
	ide.editor = self

	do
		self.rows = {}
		self.row_styles = {}
		self.top_row = 1
		self.fonts = {}
		self.caret = { startcol = 1, endcol = 1, startrow = 1, endrow = 1 }

		panel:SetSize(ide:ScaleWidth(0.8), ide:ScaleHeight(0.92))
		panel:Dock(RIGHT)

		self.width, self.height = panel:GetSize()

		self:SetFont("Consolas", 25)
	end

	do -- gutter
		local gutter = vgui.Create("DPanel", panel)
		gutter:Dock(LEFT)

		self.gutter = gutter
		self:UpdateGutter()
	end

	local scroll_ratio = 0

	do -- actual editor part
		local code_panel = vgui.Create("DTextEntry", panel)
		code_panel:SetKeyboardInputEnabled(true)
		code_panel:SetEnterAllowed(true)
		code_panel:SetTabbingDisabled(true)
		code_panel:Dock(FILL)

		code_panel:RequestFocus()

		function code_panel.AllowInput(_, char)
			if char == "`" then return end

			local has_selection = self:HasSelection()
			if has_selection then
				-- Delete selection first.
				-- Same code as multiline caret select. Should try and reuse them in a single function?
				self:DeleteSelection()
			end

			local col, row = self.caret.endcol, self.caret.endrow
			local rowcontent = self.rows[row]


			if rowcontent then
				self.rows[row] = rowcontent:sub(1, col - 1) .. char .. rowcontent:sub(col)
			else
				self.rows[row] = char
			end

			self:SetCaret(col + 1, row)
		end
		function code_panel.OnKeyCode(_, keycode)
			if input.IsControlDown() then
				if keycode == KEY_A then -- Ctrl + A, select all
					self:SetCaret(1, 1, #self.rows[#self.rows], #self.rows)
					return
				elseif keycode == KEY_C then -- Ctrl + C, copy
					SetClipboardText(self:GetSelection() or "")
					return
				end
			end

			if keycode == KEY_RIGHT then
				local bottom_row, bottom_col = self:GetCaretBottomRight()
				if input.IsShiftDown() then
					if bottom_col <= #self.rows[bottom_row] then -- There's room to move right.
						self.caret.endcol = self.caret.endcol + 1
					elseif bottom_row < self.max_visible_rows and self.rows[bottom_row + 1] then -- Leaked onto next (bottom) line
						self.caret.endcol = 1
						self.caret.endrow = self.caret.endrow + 1
					end
				else
					if bottom_col <= #self.rows[bottom_row] then -- There's room to move right.
						self:SetCaret(bottom_col + 1, bottom_row)
					elseif bottom_row < self.max_visible_rows and self.rows[bottom_row + 1] then -- Leaked onto next (bottom) line
						self:SetCaret(1, bottom_row + 1)
					else
						self:SetCaret(#self.rows[bottom_row] + 1, bottom_row)
					end
				end
			elseif keycode == KEY_LEFT then
				local top_row, top_col = self:GetCaretTopLeft()
				if input.IsShiftDown() then
					if top_col > 1 then -- There's room to move left.
						self.caret.endcol = self.caret.endcol - 1
					elseif top_row > 1 then -- Leaked onto previous (top) line
						if top_row <= self.top_row then -- Scroll editor upward
							self.top_row = self.top_row - 1
							self:UpdateGutter()
						end
						self.caret.endcol = #self.rows[top_row - 1]
						self.caret.endrow = self.caret.endrow - 1
					end
				else
					if top_col > 1 then -- There's room to move left.
						self:SetCaret(top_col - 1, top_row)
					elseif top_row > 1 then -- Leaked onto previous (top) line
						self:SetCaret(#self.rows[top_row - 1] + 1, top_row - 1)
					else
						self:SetCaret(1, 1)
					end
				end
			elseif keycode == KEY_UP then
				local top_row, top_col = self:GetCaretTopLeft()
				if input.IsShiftDown() then
					if top_row > 1 then -- Not highest row, you can go up.
						self.caret.endcol = math.min(top_col, #self.rows[top_row - 1])
						self.caret.endrow = self.caret.endrow - 1
					else -- Just move to column 1, no more rows above.
						self.caret.endcol = 1
						self.caret.endrow = 1
					end
				else
					if top_row > 1 then -- Not highest row, you can go up.
						self:SetCaret(math.min(top_col, #self.rows[top_row - 1]), top_row - 1)
					else -- Just move to column 1, no more rows above.
						self:SetCaret(1, 1)
					end
				end
			elseif keycode == KEY_DOWN then
				local bottom_row, bottom_col = self:GetCaretBottom()
				if input.IsShiftDown() then
					if bottom_row < self.max_visible_rows then
						if self.rows[bottom_row + 1] then
							self.caret.endcol = math.min(bottom_col, #self.rows[bottom_row + 1])
							self.caret.endrow = self.caret.endrow + 1
						else
							self.caret.endcol = #self.rows[bottom_row] + 1
						end
					end
				else
					if bottom_row < self.max_visible_rows then
						if self.rows[bottom_row + 1] then
							self:SetCaret(math.min(bottom_col, #self.rows[bottom_row + 1] + 1), bottom_row + 1)
						else
							self:SetCaret(#self.rows[bottom_row] + 1, bottom_row)
						end
					end
				end
			elseif keycode == KEY_BACKSPACE then
				if self:DeleteSelection() then return end

				local col, row = self.caret.endcol, self.caret.endrow
				local rowcontent = self.rows[row]

				if col > 1 then
					self.rows[row] = rowcontent:sub(1, col - 2) .. rowcontent:sub(col)
					self:SetCaret(col - 1, row)
				elseif row > 1 then -- deleted the line, move up
					local rest = table.remove(self.rows, row)
					self:SetCaret(#self.rows[row - 1] + 1, row - 1) -- Set caret to end of top line
					self.rows[row - 1] = self.rows[row - 1] .. rest -- Append rest of content to top line
				end -- Do nothing, at top of editor.
			elseif keycode == KEY_ENTER then
				self:DeleteSelection()

				local col, row = self.caret.endcol, self.caret.endrow
				local rowcontent = self.rows[row]

				self.rows[row] = rowcontent and rowcontent:sub(1, col - 1) or ""
				table.insert(self.rows, row + 1, rowcontent and rowcontent:sub(col) or "")
				self:SetCaret(1, row + 1)
			elseif keycode == KEY_TAB then
				local col, row = self.caret.endcol, self.caret.endrow
				local rowcontent = self.rows[row]

				if rowcontent then
					self.rows[row] = rowcontent:sub(1, col - 1) .. "    " .. rowcontent:sub(col)
				else
					self.rows[row] = "    "
				end
				self:SetCaret(col + 4, row)
			end

			return true
		end

		---@param x number
		---@param y number
		---@return integer x, integer row
		local function calculatePos(x, y)
			x = math.max(0, x - self.padding_left)
			y = math.max(0, y - self.padding_top)

			local col, row = math.Round(x / self.font_width) + 1, math.Round(y / self.font_height) + self.top_row

			local row_content = self.rows[row]
			if row_content then
				col = math.min(#row_content + 1, col)
				return col, row
			else -- Clicked row is empty.
				for r = row, self.top_row, -1 do -- Go up until find a line with something on it.
					local content = self.rows[r]
					if content then
						return math.min(#content + 1, col), r
					end
				end

				return 1, 1 -- Completely empty file I guess
			end
		end

		local function cursorMoved(_, x, y)
			local col, row = calculatePos(x, y)
			self.caret.endcol, self.caret.endrow = col, row
		end

		function code_panel.OnMousePressed(_, keycode)
			if keycode == MOUSE_FIRST then
				local x, y = code_panel:CursorPos()
				self:SetCaret(calculatePos(x, y))
				code_panel.OnCursorMoved = cursorMoved
			end
		end

		function code_panel.OnMouseReleased(_, keycode)
			if keycode == MOUSE_FIRST then
				local x, y = code_panel:CursorPos()
				local col, row = calculatePos(x, y)
				self.caret.endcol, self.caret.endrow = col, row
				code_panel.OnCursorMoved = nil
			end
		end

		function code_panel.OnMouseWheeled(_, delta)
			self.top_row = math.Clamp(self.top_row - delta, 1, #self.rows)
			scroll_ratio = self.top_row / #self.rows
			self:UpdateGutter()
		end

		function code_panel.Paint(_, width, height)
			surface.SetDrawColor(50, 50, 50, 255)
			surface.DrawRect(0, 0, width, height)

			surface.SetFont(self.font)

			for i = 0, self.max_visible_rows - 1 do
				-- Offset self.font_height down, Plus row offset. Drawing down -> up.
				local row = i + self.top_row
				local content = self.rows[row]

				if content then
					local y = self.padding_top + i * self.font_height
					local x = self.padding_left

					surface.SetTextPos(x, y)

					local ptr = 1
					for _, style in ipairs(self.row_styles[row] or default_styling) do
						surface.SetTextColor(style.fg or color_white)
						surface.SetFont(style.font or self.font)

						if style.len then
							surface.DrawText(content:sub(ptr, style.len and (ptr + style.len - 1)))
							ptr = ptr + style.len
						else
							surface.DrawText(content)
						end
					end
				end
			end

			-- Draw caret blinker
			surface.SetDrawColor(255, 200, 255, math.sin(SysTime() * 7 + 1) * 127.5)
			surface.DrawRect(self.padding_left + (self.caret.endcol - 1) * self.font_width, self.padding_top + (self.caret.endrow - self.top_row) * self.font_height, self.caret_width, self.font_height)

			if self:HasSelection() then -- Draw caret selection.
				surface.SetDrawColor(82, 127, 199, 150)
				if self.caret.startrow == self.caret.endrow then
					-- Simple case, caret only goes horizontally?
					local leftmost, rightmost = math.min(self.caret.startcol, self.caret.endcol),
						math.max(self.caret.startcol, self.caret.endcol)

					surface.DrawRect(self.padding_left + (leftmost - 1) * self.font_width, self.padding_top + (self.caret.endrow - self.top_row) * self.font_height, self.font_width * (rightmost - leftmost), self.font_height)
				else -- Okay, spans multiple rows.
					local toprow, topcol = self:GetCaretTop()
					local bottomrow, bottomcol = self:GetCaretBottom()

					-- Draw top line
					surface.DrawRect(self.padding_left + self.font_width * (topcol - 1), self.padding_top + (toprow - self.top_row) * self.font_height, self.font_width * math.max(1, #self.rows[toprow] - topcol + 1), self.font_height)
					-- Draw bottom line
					surface.DrawRect(self.padding_left, self.padding_top + (bottomrow - self.top_row) * self.font_height, (bottomcol - 1) * self.font_width, self.font_height)

					-- Draw rest of lines in between (selecting whole lines.)
					for i = toprow + 1, bottomrow - 1 do
						local absi = i - self.top_row -- Get i in terms of 0 - max_visible_rows to draw properly
						local rowcontent = self.rows[i]
						if rowcontent then
							surface.DrawRect(self.padding_left, self.padding_top + absi * self.font_height, self.font_width * #rowcontent, self.font_height)
						end
					end
				end
			end
		end
	end

	do -- scrollbar
		local scroll = vgui.Create("DPanel", panel)
		scroll:SetWidth(panel:GetWide() * 0.015)
		scroll:Dock(RIGHT)

		local function cursorMoved(_, x, y)
			scroll_ratio = y / panel:GetTall()
			self.top_row = math.max(1, math.ceil(#self.rows * scroll_ratio))
			self:UpdateGutter()
		end

		function scroll.OnCursorExited(_)
			scroll.OnCursorMoved = nil
		end

		function scroll.OnMousePressed(_, keycode)
			if keycode == MOUSE_FIRST then
				scroll.OnCursorMoved = cursorMoved
			end
		end

		function scroll.OnMouseWheeled(_, delta)
			self.top_row = math.Clamp(self.top_row - delta, 1, #self.rows)
			scroll_ratio = self.top_row / #self.rows
		end

		function scroll.OnMouseReleased(_, keycode)
			if keycode == MOUSE_FIRST then
				scroll.OnCursorMoved = nil
			end
		end

		function scroll.Paint(_, width, height)
			surface.SetDrawColor(100, 100, 100, 255)
			surface.DrawRect(0, 0, width, height)

			surface.SetDrawColor(150, 150, 150, 255)
			surface.DrawRect(0, scroll_ratio * height, width, 50)
		end
	end

	self:SetText(assert(file.Read("veditor/example.txt", "LUA"), "Missing veditor/example.txt"))
end

---@param fontname string
---@param size integer
function Editor:SetFont(fontname, size)
	local mangle = "veditor_" .. fontname .. "_" .. size
	if not self.fonts[mangle] then
		surface.CreateFont(mangle, {
			font = fontname,
			size = size,
			antialias = true,
			shadow = true,
			extended = true
		})
		self.fonts[mangle] = true
	end

	surface.SetFont(mangle)
	self.font = mangle

	self.font_width, self.font_height = surface.GetTextSize(" ")
	self.max_visible_rows = math.floor(self.height / self.font_height - 1)

	self.padding_top = self.font_height * 0.3
	self.padding_left = self.font_width * 2
	self.caret_width = self.font_width * 0.2
	self.gutter_padding_right = self.font_width * 1
end

---@param txt string
function Editor:SetText(txt)
	self.rows = txt:Split("\n")
end

---@param col integer
---@param row integer
---@param endcol integer?
---@param endrow integer?
function Editor:SetCaret(col, row, endcol, endrow)
	assert(col)
	assert(row)

	col, row = math.max(1, col), math.max(1, row)
	if endcol then endcol = math.max(1, endcol) end
	if endrow then endrow = math.max(1, endrow) end

	self.caret = { startcol = col, endcol = endcol or col, startrow = row, endrow = endrow or row }
end

---@param percent number
function Editor:SetScroll(percent)
	self.top_row = #self.rows * percent
end

--- Returns the bottom right part of the caret selection.
--- This will usually be bottom right, unless the caret is on a single line, where it is not guaranteed.
---@see Editor.GetCaretBottomRight if you want that case covered.
---@return integer row
---@return integer col
function Editor:GetCaretBottom()
	if self.caret.endrow > self.caret.startrow then
		return self.caret.endrow, self.caret.endcol
	else
		return self.caret.startrow, self.caret.startcol
	end
end

--- Returns the bottom right part of the caret selection.
---@return integer row
---@return integer col
function Editor:GetCaretBottomRight()
	if self.caret.endrow > self.caret.startrow then
		return self.caret.endrow, self.caret.endcol
	elseif self.caret.endrow == self.caret.startrow then
		return self.caret.startrow, math.max(self.caret.startcol, self.caret.endcol)
	else
		return self.caret.startrow, self.caret.startcol
	end
end

--- Returns the top part of the caret selection.
--- This will usually be top left, unless the caret is on a single line, where it is not guaranteed.
---@see Editor.GetCaretTopLeft if you want that case covered.
---@return integer row
---@return integer col
function Editor:GetCaretTop()
	if self.caret.endrow < self.caret.startrow then
		return self.caret.endrow, self.caret.endcol
	else
		return self.caret.startrow, self.caret.startcol
	end
end

--- Returns the top left part of the caret selection.
--- This could be either the initial or ending, so this function is necessary.
---@return integer row
---@return integer col
function Editor:GetCaretTopLeft()
	if self.caret.endrow < self.caret.startrow then
		return self.caret.endrow, self.caret.endcol
	elseif self.caret.endrow == self.caret.startrow then
		return self.caret.startrow, math.min(self.caret.startcol, self.caret.endcol)
	else
		return self.caret.startrow, self.caret.startcol
	end
end

function Editor:HasSelection()
	return self.caret.startcol ~= self.caret.endcol
		or self.caret.startrow ~= self.caret.endrow
end

function Editor:GetSelection()
	if not self:HasSelection() then return end

	local toprow, topcol = self:GetCaretTopLeft()
	local bottomrow, bottomcol = self:GetCaretBottomRight()

	local buf, nbuf = { self.rows[toprow]:sub(topcol) }, 1

	if toprow ~= bottomrow then  -- Copy every row in between
		for i = toprow + 1, bottomrow do
			nbuf = nbuf + 1
			buf[nbuf] = self.rows[i]
		end
	end

	nbuf = nbuf + 1
	buf[nbuf] = self.rows[bottomrow]:sub(1, bottomcol)

	return table.concat(buf, "", 1, nbuf)
end

function Editor:DeleteSelection()
	if not self:HasSelection() then return false end

	local toprow, topcol = self:GetCaretTopLeft()
	local bottomrow, bottomcol = self:GetCaretBottomRight()

	self.rows[toprow] = self.rows[toprow]:sub(1, topcol - 1) .. self.rows[bottomrow]:sub(bottomcol)

	if toprow ~= bottomrow then -- Delete every row besides first row. Pretty bad O(n) operation
		for _ = toprow + 1, bottomrow do
			table.remove(self.rows, toprow + 1)
		end
	end

	self:SetCaret(topcol, toprow)
	return true
end

function Editor:UpdateGutter()
	local gutter = self.gutter

	local font, font_width, font_height = self.font, self.font_width, self.font_height
	local top_row, max_visible_rows = self.top_row, self.max_visible_rows
	local padding_top = self.padding_top

	gutter:SetWidth(font_width * 6 + self.gutter_padding_right)

	function gutter.Paint(_, width, height)
		self:Highlight()

		surface.SetDrawColor(40, 40, 40, 255)
		surface.DrawRect(0, 0, width, height)

		surface.SetFont(font)
		surface.SetTextColor(200, 200, 200, 255)

		for i = 0, max_visible_rows - 1 do
			local row = i + top_row
			-- Offset self.font_height down, Plus row offset. Drawing down -> up.

			if not self.rows[row] then
				break
			end

			local linestr = tostring(row)

			local y = padding_top + i * font_height
			local x = (6 - #linestr) * self.font_width - self.gutter_padding_right

			surface.SetTextPos(x, y)
			surface.DrawText(linestr)
		end
	end
end

local color_number = Color(129, 204, 122)
local color_ident = Color(156, 220, 254)
local color_keyword = Color(197, 134, 192)
local color_string = Color(206, 145, 120)

local keywords = {
	["function"] = true, ["local"] = true, ["end"] = true, ["true"] = true, ["false"] = true,
	["while"] = true, ["for"] = true, ["in"] = true, ["repeat"] = true, ["if"] = true, ["else"] = true,
	["elseif"] = true, ["until"] = true, ["goto"] = true, ["do"] = true
}

function Editor:Highlight()
	for i, row in ipairs(self.rows) do
		local styles = {}
		local ptr, len = 1, #row
		while ptr <= len do
			local _, ed, num = row:find("^(%d+%.%d+)", ptr)
			if num then
				styles[#styles + 1] = { fg = color_number, len = ed - ptr + 1 }
				ptr = ed + 1
				goto cont
			end

			local _, ed, num = row:find("^(%d+)", ptr)
			if num then
				styles[#styles + 1] = { fg = color_number, len = ed - ptr + 1 }
				ptr = ed + 1
				goto cont
			end

			local _, ed, str = row:find("^('[^']*')", ptr)
			if str then
				styles[#styles + 1] = { fg = color_string, len = ed - ptr + 1 }

				ptr = ed + 1
				goto cont
			end

			local _, ed, str = row:find("^(\"[^\"]*\")", ptr)
			if str then
				styles[#styles + 1] = { fg = color_string, len = ed - ptr + 1 }

				ptr = ed + 1
				goto cont
			end

			local _, ed, ident = row:find("^([%w_]+)", ptr)
			if ident then
				if keywords[ident] then
					styles[#styles + 1] = { fg = color_keyword, len = ed - ptr + 1 }
				else
					styles[#styles + 1] = { fg = color_ident, len = ed - ptr + 1 }
				end

				ptr = ed + 1
				goto cont
			end

			styles[#styles + 1] = { fg = color_white, len = 1 }
			ptr = ptr + 1

			::cont::
		end

		self.row_styles[i] = styles
	end
end

return Editor