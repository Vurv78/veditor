---@class Component
---@field name string
---@field editor Editor
---@field inner GPanel
---@field config Config
---@field Init fun(self: Component, editor: Editor, panel: GPanel)
---@field Paint fun(self: Component, width: integer, height: integer)?
local Component = {}
Component.__index = Component

---@alias Config {}

---@param name string
---@param config Config?
---@return Component
function Component.new(name, config)
	return setmetatable({ name = name, config = config or {} }, Component)
end

return Component