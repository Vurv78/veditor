---@class IDE
---@field frame Panel
---@field components Component[]
local IDE = {}
IDE.__index = IDE

---@param width integer?
---@param height integer?
---@return IDE
function IDE.new(width, height)
	width = width or ScrW() * 0.8
	height = height or ScrH() * 0.8

	local frame = vgui.Create("DFrame", nil, nil)
	frame:SetSize(width, height)
	frame:SetPos((ScrW() - width) / 2, (ScrH() - height) / 2)

	frame:MakePopup()

	local ide = setmetatable({
		frame = frame,
		width = width,
		height = height,
		components = {}
	}, IDE)

	ide:Init()

	return ide
end

function IDE:Init()
	self:RegisterComponent( include("components/toolbox.lua") )
	self:RegisterComponent( include("components/status.lua") )
	self:RegisterComponent( include("components/editor.lua") )
	self:RegisterComponent( include("components/files.lua") )
end

---@param component Component
---@return Component
function IDE:RegisterComponent(component)
	assert(component, "Missing component")

	local panel = vgui.Create("DPanel", self.frame, tostring(component))

	component.inner = panel
	component.ide = self

	component:Init(self, panel)

	panel.Paint = component.Paint and function(_, w, h) component:Paint(w, h) end

	table.insert(self.components, component)

	return component
end

---@param ratio number
---@return number
function IDE:ScaleHeight(ratio)
	local _, h = self.frame:GetSize()
	return h * ratio
end

---@param ratio number
---@return number
function IDE:ScaleWidth(ratio)
	local w = self.frame:GetSize()
	return w * ratio
end

function IDE:GetSize()
	return self.frame:GetSize()
end

do
	local select = select

	---@return number
	function IDE:GetHeight()
		return select(2, self.frame:GetSize())
	end

	---@return number
	function IDE:GetWidth()
		return select(1, self.frame:GetSize())
	end
end

function IDE:Popup()
	self.frame:MakePopup()
end

function IDE:Remove()
	self.frame:Remove()
end

if GlobalIDE then
	GlobalIDE:Remove()
end

GlobalIDE = IDE.new()
GlobalIDE:Popup()