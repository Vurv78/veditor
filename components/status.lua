---@type Component
local Component = include("../component.lua")

---@class Status: Component
---@field position DLabel
local Status = Component.new("Status")

---@param ide IDE
---@param panel Panel
function Status:Init(ide, panel)
	panel:SetSize( ide:ScaleWidth(1), ide:ScaleHeight(0.02) )
	panel:Dock(BOTTOM)

	do
		local language = vgui.Create("DLabel", panel)
		language:SetWidth(ide:ScaleWidth(0.05))
		language:SetText("Lua")
		language:Dock(RIGHT)
		language:DockMargin(ide:ScaleWidth(0.1), 0, 0, 0)

		language:SetPaintBorderEnabled(false)
		language:SetTextColor(color_white)
	end

	do
		local position = vgui.Create("DLabel", panel)
		position:SetWidth(ide:ScaleWidth(0.1))
		position:SetText("Ln 1, Col 1")
		position:Dock(RIGHT)

		position:SetTextColor(color_white)

		self.position = position
	end

	function panel.Paint(_, width, height)
		-- Background
		surface.SetDrawColor(35, 35, 35, 255)
		surface.DrawRect(0, 0, width, height)

		-- Outline
		surface.SetDrawColor(60, 60, 60, 255)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	---@param editor Editor
	ide:WaitForComponent("editor", function(editor)
		editor:OnCallback("caret", function()
			if editor:HasSelection() then
				self.position:SetText(string.format("Ln %u, Col %u (%u selected)", editor.caret.endrow, editor.caret.endcol, #editor:GetSelection()))
			else
				self.position:SetText(string.format("Ln %u, Col %u", editor.caret.endrow, editor.caret.endcol))
			end
		end)
	end)
end

return Status