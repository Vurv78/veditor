---@class IDE
---@field frame Panel
---@field components Component[]
---@field callbacks table<string, fun(component: Component)[]>
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

		components = {},
		callbacks = {}
	}, IDE)

	ide:RegisterComponent("toolbox", include("components/toolbox.lua"))
	ide:RegisterComponent("status", include("components/status.lua"))
	ide:RegisterComponent("editor", include("components/editor.lua"))
	ide:RegisterComponent("tree", include("components/files.lua"))

	return ide
end

---@param name string
---@param component Component
function IDE:RegisterComponent(name, component)
	assert(type(name) == "string", "Name must be a string")
	assert(component, "Missing component")
	assert(not self.components[name], "Cannot override component: " .. name)

	local panel = vgui.Create("DPanel", self.frame, string.format("ide:%p", component))
	component.inner, component.ide = panel, self
	component:Init(self, panel)

	table.insert(self.components, component)

	if self.callbacks[name] then
		for i, cb in ipairs(self.callbacks[name]) do
			cb(component)
		end
	end

	return component
end

---@param name string
---@param callback fun(component: Component)
function IDE:WaitForComponent(name, callback)
	if self.components[name] then callback(self.components[name]) end

	if self.callbacks[name] then
		self.callbacks[name][#self.callbacks[name] + 1] = callback
	else
		self.callbacks[name] = { callback }
	end
end

---@param ratio number
function IDE:ScaleHeight(ratio)
	return self.frame:GetTall() * ratio
end

---@param ratio number
function IDE:ScaleWidth(ratio)
	return self.frame:GetWide() * ratio
end

function IDE:GetSize()
	return self.frame:GetSize()
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