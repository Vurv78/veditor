---@type Component
local Component = include("../component.lua")

---@class FileBrowser
local FileBrowser = Component.new("FileBrowser")

---@param ide IDE
---@param panel Panel
function FileBrowser:Init(ide, panel)
	panel:SetSize( ide:ScaleWidth(0.2), ide:ScaleHeight(1) )
	panel:Dock(LEFT)

	--[[local scroll = vgui.Create("DVScrollBar", panel)
	scroll:Dock(LEFT)

	local files = vgui.Create("DTree", panel)
	files:Dock(FILL)

	---@param node Panel
	function files:DoClick(node)
	end

	---@param node Panel
	function files:DoRightClick(node)

	end

	self:Update()

	local searchbox = vgui.Create("DTextEntry", panel)
	searchbox:Dock(TOP)

	local update = vgui.Create("DButton", panel)
	update:Dock(BOTTOM)
	]]
end

local color = Color(0, 0, 255, 255)
function FileBrowser:Paint(width, height)
	-- Background
	surface.SetDrawColor(30, 30, 30, 255)
	surface.DrawRect(0, 0, width, height)

	-- Outline
	surface.SetDrawColor(60, 60, 60, 255)
	surface.DrawOutlinedRect(0, 0, width, height, 1)

	-- draw.SimpleText("File Browser", "DermaLarge", width / 2, height / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function FileBrowser:Update()

end

return FileBrowser