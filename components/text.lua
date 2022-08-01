---@type Component
local Component = include("../component.lua")

---@class Text: Component
---@field rows string[]
---@field top_row integer
---@field font string
---@field fonts table<string, boolean?>
---@field font_height integer
---@field font_width integer
---@field height number
---@field width number
---@field gutter_len integer
local Text = Component.new("Text")

---@param s string
---@param length integer
---@return string
local function padString(s, length)
	local strlen = #s
	if strlen < length then
		return (" "):rep(length - strlen)
	end
	return s
end

---@param editor Editor
---@param panel GPanel
function Text:Init(editor, panel)
	do
		self.rows = {}
		self.top_row = 1
		self.fonts = {}

		panel:SetSize(editor:ScaleWidth(0.8), editor:ScaleHeight(0.92))
		panel:Dock(RIGHT)

		self.width, self.height = panel:GetSize()

		self:SetFont("Consolas", 14)
	end

	--#region gutter
	do
		self.gutter = vgui.Create("DPanel", panel)
		self.gutter:Dock(LEFT)

		self:UpdateGutter()
	end
	--#endregion

	local scrollbar = vgui.Create("DVScrollBar", panel)
	scrollbar:SetUp(1, 1)
	scrollbar:Dock(RIGHT)

	local code_panel = vgui.Create("DPanel", panel)
	code_panel:Dock(FILL)

	function code_panel.OnMousePressed(s, keycode)
		if keycode == MOUSE_FIRST then
			local gui_x, gui_y = s:CursorPos()

			local col, row = math.floor(gui_x / self.font_width) + 1, math.floor(gui_y / self.font_height) + 1

			print(col, row)
		end
	end

	code_panel.Paint = function(_, width, height)
		surface.SetDrawColor(255, 0, 0, 255)
		surface.DrawRect(0, 0, width, height)
	end

	function panel.OnMouseWheeled(_, delta)
		if delta > 0 and (self.top_row - delta) < 1 then return end
		if delta < 0 and (self.top_row - delta + self.max_visible_rows - 2) > #self.rows then return end

		self.top_row = self.top_row - delta

		self:UpdateGutter()
		-- scrollbar:AddScroll(delta * 50)
	end

	self:SetText(file.Read("veditor/example.txt", "LuaMenu"))
end

---@param fontname string
---@param size integer
function Text:SetFont(fontname, size)
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
end

function Text:SetText(txt)
	local rows = txt:Split("\n")
	self.rows = rows
end

local last_max_visible_rows = 0
function Text:UpdateGutter()
	if self.max_visible_rows == last_max_visible_rows then
		-- Don't need to update rendering.
		return
	end

	local gutter = self.gutter
	last_max_visible_rows = self.max_visible_rows

	local gutter_len = #tostring(self.max_visible_rows) + 2
	gutter:SetWidth( self.font_width * gutter_len )

	function gutter.Paint(_, width, height)
		surface.SetDrawColor(255, 255, 0, 255)
		surface.DrawRect(0, 0, width, height)

		local bottom_row = self.top_row + self.max_visible_rows - 1
		for i = self.top_row, bottom_row do
			draw.SimpleText(i, self.font, 10, (i - self.top_row) * self.font_height, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end

return Text