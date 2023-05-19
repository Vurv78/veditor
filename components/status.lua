---@type Component
local Component = include("../component.lua")

---@class Status: Component
---@field position: DButton
local Status = Component.new("Status")

---@param ide IDE
---@param panel Panel
function Status:Init(ide, panel)
	panel:SetSize( ide:ScaleWidth(1), ide:ScaleHeight(0.02) )
	panel:Dock(BOTTOM)

	do
		local cornerstat = vgui.Create("DButton", panel)
		cornerstat:SetWidth(ide:ScaleWidth(0.05))
		cornerstat:Dock(LEFT)
	end

	do
		local language = vgui.Create("DButton", panel)
		language:SetWidth(ide:ScaleWidth(0.1))
		language:SetText("Text")
		language:Dock(RIGHT)
		language:DockMargin(ide:ScaleWidth(0.1), 0, 0, 0)
	end

	do
		local position = vgui.Create("DButton", panel)
		position:SetWidth(ide:ScaleWidth(0.15))
		position:SetText("Ln 29, Col 23")
		position:Dock(RIGHT)

		self.position = position
	end
end

function Status:OnTyped()
	local editor = self.ide.editor --[[@as Editor]]
	self.position:SetText(string.format("Ln %u, Col %u", editor.caret.startrow, editor.caret.startcol))
end

function Status:Paint(width, height)
	-- Background
	surface.SetDrawColor(35, 35, 35, 255)
	surface.DrawRect(0, 0, width, height)

	-- Outline
	surface.SetDrawColor(60, 60, 60, 255)
	surface.DrawOutlinedRect(0, 0, width, height, 1)
end

return Status