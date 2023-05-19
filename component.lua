---@class Component
---@field name string
---@field ide IDE
---@field inner Panel
---@field config Config
---@field Init fun(self: Component, ide: IDE, panel: Panel)
---@field Paint fun(self: Component, width: integer, height: integer)?
---@field OnTyped fun(self: Component)
local Component = {}
Component.__index = Component

---@alias Config {}

---@generic T: Component
---@param name `T`
---@param config Config?
---@return T
function Component.new(name, config)
	return setmetatable({ name = name, config = config or {} }, Component)
end

return Component