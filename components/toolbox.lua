---@type Component
local Component = include("../component.lua")

local Toolbox = Component.new("Toolbox")

---@param editor Editor
---@param panel GPanel
function Toolbox:Init(editor, panel)
	panel:SetSize( editor:ScaleWidth(1), editor:ScaleHeight(0.08) )
	panel:Dock(TOP)
end

function Toolbox:Paint(width, height)
	surface.SetDrawColor(0, 0, 255, 255)
	surface.DrawRect(0, 0, width, height)

	draw.SimpleText("Toolbox", "DermaLarge", width / 2, height / 2, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

return Toolbox