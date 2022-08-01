---@class Editor
---@field frame GPanel
---@field components Component[]
local Editor = {}
Editor.__index = Editor

---@param width integer
---@param height integer
---@return Editor
function Editor.new(width, height)
	width = width or ScrW() * 0.8
	height = height or ScrH() * 0.8

	local frame = vgui.Create("DFrame", nil, nil)
	frame:SetSize(width, height)
	frame:SetPos((ScrW() - width) / 2, (ScrH() - height) / 2)

	frame:MakePopup()

	local editor = setmetatable({
		frame = frame,
		width = width,
		height = height,
		components = {}
	}, Editor)

	editor:Init()

	return editor
end

function Editor:Init()
	self:RegisterComponent( include("components/toolbox.lua") )
	self:RegisterComponent( include("components/text.lua") )
	self:RegisterComponent( include("components/files.lua") )
end

---@param component Component
---@return Component
function Editor:RegisterComponent(component)
	assert(component, "Missing component")

	local panel = vgui.Create("DPanel", self.frame, tostring(component))

	component.inner = panel
	component.editor = self

	component:Init(self, panel)

	panel.Paint = component.Paint and function(_, w, h) component:Paint(w, h) end

	table.insert(self.components, component)

	return component
end

---@param ratio number
---@return number
function Editor:ScaleHeight(ratio)
	local _, h = self.frame:GetSize()
	return h * ratio
end

---@param ratio number
---@return number
function Editor:ScaleWidth(ratio)
	local w = self.frame:GetSize()
	return w * ratio
end

---@return number
---@return number
function Editor:GetSize()
	return self.frame:GetSize()
end

do
	local select = select

	---@return number
	function Editor:GetHeight()
		return select(2, self.frame:GetSize())
	end

	---@return number
	function Editor:GetWidth()
		return select(1, self.frame:GetSize())
	end
end

function Editor:Popup()
	self.frame:MakePopup()
end

function Editor:Remove()
	self.frame:Remove()
end

if GlobalEditor then
	GlobalEditor:Remove()
end

GlobalEditor = Editor.new()
GlobalEditor:Popup()