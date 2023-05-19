---@type Component
local Component = include("../component.lua")

---@class Editor: Component
---
---@field rows string[]
---
---@field caret { startcol: integer, endcol: integer, startrow: integer, endrow: integer }
---
---@field top_row integer
---@field max_visible_rows integer
---
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
---
---@field code DPanel
local Editor = Component.new("Editor")

---@param ide IDE
---@param panel Panel
function Editor:Init(ide, panel)
	ide.editor = self

	do
		self.rows = {}
		self.top_row = 1
		self.fonts = {}
		self.caret = { startcol = 0, endcol = 0, startrow = 0, endrow = 0 }

		panel:SetSize(ide:ScaleWidth(0.8), ide:ScaleHeight(0.92))
		panel:Dock(RIGHT)

		self.width, self.height = panel:GetSize()

		self:SetFont("Consolas", 25)
	end

	do -- gutter
		self.gutter = vgui.Create("DPanel", panel)
		self.gutter:Dock(LEFT)

		self:UpdateGutter()
	end

	do -- scrolling & scrollbar
		local scrollbar = vgui.Create("DVScrollBar", panel)
		scrollbar:SetUp(1, 1)
		scrollbar:Dock(RIGHT)

		function panel.OnMouseWheeled(_, delta)
			if delta > 0 and (self.top_row - delta) < 1 then return end
			if delta < 0 and (self.top_row - delta + self.max_visible_rows - 2) > #self.rows then return end

			self.top_row = self.top_row - delta

			self:UpdateGutter()
			-- scrollbar:AddScroll(delta * 50)
		end
	end

	do -- actual editor part
		local code_panel = vgui.Create("DTextEntry", panel)
		code_panel:SetKeyboardInputEnabled(true)
		code_panel:Dock(FILL)

		function code_panel.OnLoseFocus(_, value)
			code_panel:RequestFocus()
		end

		function code_panel.OnKeyCode(_, keycode)
			if keycode == KEY_LWIN then return end
			if keycode == KEY_LSHIFT then return end
			if keycode == KEY_LCONTROL then return end
			if keycode == KEY_BACKQUOTE then return end

			local oldcol, oldrow = self.caret.endcol, self.caret.endrow
			-- Todo: When arrow keys used and input.IsShiftDown(), set startcol and startrow to these (so it selects)

			if keycode == KEY_RIGHT then
				local bottom_row, bottom_col = self:GetCaretBottom()
				if bottom_col < #self.rows[bottom_row] then -- There's room to move right.
					self:SetCaret(bottom_col + 1, bottom_row)
				elseif bottom_row < self.max_visible_rows and self.rows[bottom_row + 1] then -- Leaked onto next (bottom) line
					self:SetCaret(1, bottom_row + 1)
				end
			elseif keycode == KEY_LEFT then
				local top_row, top_col = self:GetCaretTop()
				if top_col > 1 then -- There's room to move left.
					self:SetCaret(top_col - 1, top_row)
				elseif top_row > 1 then -- Leaked onto previous (top) line
					self:SetCaret(#self.rows[top_row - 1], top_row - 1)
				end
			elseif keycode == KEY_UP then
				local top_row, top_col = self:GetCaretTop()
				if top_row > 1 then -- Not highest row, you can go up.
					self:SetCaret(math.min(top_col, #self.rows[top_row - 1]), top_row - 1)
				else -- Just move to column 1, no more rows above.
					self:SetCaret(1, 1)
				end
			elseif keycode == KEY_DOWN then
				local bottom_row, bottom_col = self:GetCaretBottom()
				if bottom_row < self.max_visible_rows then
					if self.rows[bottom_row + 1] then
						self:SetCaret(math.min(bottom_col, #self.rows[bottom_row + 1]), bottom_row + 1)
					else
						self:SetCaret(#self.rows[bottom_row] + 1, bottom_row)
					end
				end
			else
				if self:HasSelection() then
					-- Delete selection first.
					-- Same code as multiline caret select. Should try and reuse them in a single function?

					local topmost, bottommost = math.min(self.caret.startrow, self.caret.endrow),
						math.max(self.caret.startrow, self.caret.endrow)

					-- Draw first line
					if topmost == self.caret.startrow then
						-- surface.DrawRect(self.font_width * self.caret.startcol, self.caret.startrow * self.font_height, self.font_width * (#self.rows[self.caret.startrow] - self.caret.startcol), self.font_height)
					else -- topmost is ending caret
						--surface.DrawRect(self.font_width * self.caret.endcol, self.caret.endrow * self.font_height, self.font_width * (-self.caret.endcol), self.font_height)
					end

					for i = topmost + 1, bottommost - 1 do -- Each line draw the whole thing.
						local row = self.rows[i]
						if row then
							table.remove(self.rows, topmost + 1)
						end
					end

					-- Draw final line
					if bottommost == self.caret.endrow then
						-- surface.DrawRect(0, self.caret.endrow * self.font_height, self.font_width * self.caret.endcol, self.font_height)
					else
						-- surface.DrawRect(0, self.caret.startrow * self.font_height, self.font_width * self.caret.startcol, self.font_height)
					end

					local tl1, tl2 = self:GetCaretTop()

					self:SetCaret(tl2, tl1)
				end

				local col, row = self.caret.startcol, self.caret.startrow
				local rowcontent = self.rows[row]

				if keycode == KEY_BACKSPACE then
					if col > 1 then
						if rowcontent then
							self.rows[row] = rowcontent:sub(1, col - 2) .. rowcontent:sub(col)
						else -- This shouldn't be possible.. need to look into this.
							self.rows[row] = ""
						end

						self:SetCaret(col - 1, row)
					elseif row > 1 then -- deleted the line, move up
						local rest = self.rows[row]
						self.rows[row - 1] = self.rows[row - 1] .. rest -- Append rest of content to top line
						table.remove(self.rows, row)
						print(#self.rows[row - 1] - #rest + 1, rest)
						self:SetCaret(#self.rows[row - 1] - #rest, row - 1)
					else -- Todo: Don't delete the entire line
						table.remove(self.rows, row)
					end
				elseif keycode == KEY_ENTER then
					self.rows[row] = rowcontent and rowcontent:sub(1, col - 1) or ""
					table.insert(self.rows, row + 1, rowcontent and rowcontent:sub(col) or "")
					self:SetCaret(1, row + 1)
				elseif keycode == KEY_TAB then
					if rowcontent then
						self.rows[row] = rowcontent:sub(1, col - 1) .. "    " .. rowcontent:sub(col)
					else
						self.rows[row] = "    "
					end
					self:SetCaret(col + 4, row)
				else
					local key = keycode == KEY_SPACE and " " or input.GetKeyName(keycode)
					if input.IsShiftDown() then key = key:upper() end

					if rowcontent then
						self.rows[row] = rowcontent:sub(1, col - 1) .. key .. rowcontent:sub(col)
					else
						self.rows[row] = key
					end
					self:SetCaret(col + 1, row)
				end
			end

			return true
		end

		---@param x number
		---@param y number
		---@return integer x, integer row
		local function calculatePos(x, y)
			x = x - self.padding_left
			y = y - self.padding_top

			local col, row = math.ceil(x / self.font_width), math.ceil(y / self.font_height)
			col = math.max(col, 1)

			local row_content = self.rows[row]
			if row_content then
				col = math.min(#row_content, col)
				return col, row
			else
				repeat
					row = row - 1
					row_content = self.rows[row]
				until row_content or row < 1

				if row_content then
					col = math.min(#row_content, col)
					return col, row
				else
					return 1, 1
				end
			end
		end

		function code_panel.OnMousePressed(_, keycode)
			if keycode == MOUSE_FIRST then
				local x, y = code_panel:CursorPos()
				self:SetCaret(calculatePos(x, y))
			end
		end

		function code_panel.OnMouseReleased(_, keycode)
			if keycode == MOUSE_FIRST then
				local x, y = code_panel:CursorPos()
				local col, row = calculatePos(x, y)
				self.caret.endcol, self.caret.endrow = col, row
			end
		end

		code_panel.Paint = function(_, width, height)
			surface.SetDrawColor(50, 50, 50, 255)
			surface.DrawRect(0, 0, width, height)

			local bottom_row = self.top_row + self.max_visible_rows - 2

			for i = bottom_row, self.top_row, -1 do
				-- Offset self.font_height down, Plus row offset. Drawing down -> up.
				local row = self.rows[i]
				if row then
					local y = self.padding_top + i * self.font_height
					draw.SimpleText(row:Replace(" ", "-"), self.font, self.padding_left, y, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
			end

			surface.SetDrawColor(255, 255, 255, math.sin(SysTime() * 5 + 1) * 127.5)
			surface.DrawRect(self.caret.endcol * self.font_width, self.caret.endrow * self.font_height,
				self.font_width / 5, self.font_height)

			surface.SetDrawColor(82, 127, 199, 150)
			if self.caret.startrow == self.caret.endrow then
				-- Simple case, caret only goes horizontally?
				local leftmost, rightmost = math.min(self.caret.startcol, self.caret.endcol),
					math.max(self.caret.startcol, self.caret.endcol)
				surface.DrawRect(leftmost * self.font_width, self.caret.endrow * self.font_height,
					self.font_width * (rightmost - leftmost), self.font_height)
			else -- Okay, spans multiple rows.
				local topmost, bottommost = math.min(self.caret.startrow, self.caret.endrow),
					math.max(self.caret.startrow, self.caret.endrow)

				-- Draw first line
				if topmost == self.caret.startrow then
					surface.DrawRect(self.font_width * self.caret.startcol, self.caret.startrow * self.font_height,
						self.font_width * (#self.rows[self.caret.startrow] - self.caret.startcol), self.font_height)
				else -- topmost is ending caret
					surface.DrawRect(self.font_width * self.caret.endcol, self.caret.endrow * self.font_height,
						self.font_width * (-self.caret.endcol), self.font_height)
				end

				for i = topmost + 1, bottommost - 1 do -- Each line draw the whole thing.
					local row = self.rows[i]
					if row then
						surface.DrawRect(0, i * self.font_height, self.font_width * #row, self.font_height)
					end
				end

				-- Draw final line
				if bottommost == self.caret.endrow then
					surface.DrawRect(0, self.caret.endrow * self.font_height, self.font_width * self.caret.endcol,
						self.font_height)
				else
					surface.DrawRect(0, self.caret.startrow * self.font_height, self.font_width * self.caret.startcol,
						self.font_height)
				end
			end
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
			shadow = true
		})
		self.fonts[mangle] = true
	end

	surface.SetFont(mangle)
	self.font = mangle

	self.font_width, self.font_height = surface.GetTextSize(" ")
	self.max_visible_rows = math.floor(self.height / self.font_height - 1)

	self.padding_top = self.font_height / 2
	self.padding_left = self.font_width
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

--- Returns the bottom right part of the caret selection.
--- This could be either the initial or ending, so this function is necessary.
---@return integer row
---@return integer col
function Editor:GetCaretBottom()
	if self.caret.endrow > self.caret.startrow then
		return self.caret.endrow, self.caret.endcol
	else
		return self.caret.startrow, self.caret.startcol
	end
end

--- Returns the top left part of the caret selection.
--- This could be either the initial or ending, so this function is necessary.
---@return integer row
---@return integer col
function Editor:GetCaretTop()
	if self.caret.endrow < self.caret.startrow then
		return self.caret.endrow, self.caret.endcol
	else
		return self.caret.startrow, self.caret.startcol
	end
end

function Editor:HasSelection()
	return self.caret.startcol ~= self.caret.endcol
		or self.caret.startrow ~= self.caret.endrow
end

function Editor:UpdateGutter()
	local gutter = self.gutter
	self.gutter:SetWidth(self.font_width * 5)

	function gutter.Paint(_, width, height)
		surface.SetDrawColor(40, 40, 40, 255)
		surface.DrawRect(0, 0, width, height)

		local bottom_row = self.top_row + self.max_visible_rows - 1
		for i = self.top_row, bottom_row do
			-- Offset self.font_height down, Plus row offset. Drawing down -> up.
			local y = self.padding_top + i * self.font_height
			draw.SimpleText(tostring(i), self.font, 10, y, nil, TEXT_ALIGN_LEFT,
				TEXT_ALIGN_CENTER)
		end
	end
end

return Editor