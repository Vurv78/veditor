---@type Component
local Component = include("../component.lua")

---@class FileBrowser
local FileBrowser = Component.new("FileBrowser")

---@param ide IDE
---@param panel Panel
function FileBrowser:Init(ide, panel)
	panel:SetSize(ide:ScaleWidth(0.2), ide:ScaleHeight(1))
	panel:Dock(LEFT)

	function panel.Paint(_, width, height)
		-- Background
		surface.SetDrawColor(30, 30, 30, 255)
		surface.DrawRect(0, 0, width, height)

		-- Outline
		surface.SetDrawColor(60, 60, 60, 255)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end
end

return FileBrowser
