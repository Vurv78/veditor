---@type Component
local Component = include("../component.lua")

local FileBrowser = Component.new("FileBrowser")

---@param editor Editor
---@param panel GPanel
function FileBrowser:Init(editor, panel)
	panel:SetSize( editor:ScaleWidth(0.2), editor:ScaleHeight(1) )
	panel:Dock(LEFT)

	--[[local scroll = vgui.Create("DVScrollBar", panel)
	scroll:Dock(LEFT)

	local files = vgui.Create("DTree", panel)
	files:Dock(FILL)

	---@param node GPanel
	function files:DoClick(node)
	end

	---@param node GPanel
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
	surface.SetDrawColor(255, 200, 255, 255)
	surface.DrawRect(0, 0, width, height)

	draw.SimpleText("File Browser", "DermaLarge", width / 2, height / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function FileBrowser:Update()

end

return FileBrowser