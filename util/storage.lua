---@class Storage
---@overload fun(): self
local M = Class 'Storage'

--Store arbitrary values
---@param key any
---@param value any
---@return any
function M:storage_set(key, value)
    if not self.storage_table then
        ---@private
        self.storage_table = {}
    end
    self.storage_table[key] = value
    return value
end

--Gets the stored value
---@param key any
---@return any
function M:storage_get(key)
    if not self.storage_table then
        return nil
    end
    return self.storage_table[key]
end

--Gets the container for storing data
---@return table
function M:storage_all()
    if not self.storage_table then
        ---@private
        self.storage_table = {}
    end
    return self.storage_table
end
