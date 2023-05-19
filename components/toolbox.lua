---@type Component
local Component = include("../component.lua")

---@class Toolbox
local Toolbox = Component.new("Toolbox")

---@param ide IDE
---@param panel Panel
function Toolbox:Init(ide, panel)
	panel:SetSize( ide:ScaleWidth(1), ide:ScaleHeight(0.08) )
	panel:Dock(TOP)
end

---@param width integer
---@param height integer
function Toolbox:Paint(width, height)
	-- Background
	surface.SetDrawColor(35, 35, 35, 255)
	surface.DrawRect(0, 0, width, height)

	-- Outline
	surface.SetDrawColor(60, 60, 60, 255)
	surface.DrawOutlinedRect(0, 0, width, height, 1)

	-- draw.SimpleText("Toolbox", "DermaLarge", width / 2, height / 2, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

return Toolbox