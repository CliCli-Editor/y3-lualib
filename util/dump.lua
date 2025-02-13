local seri = require 'clicli.tools.serialization'

---@class Dump
local M = Class 'Dump'

---@private
function M.encodeHook(value)
    local luaType = clicli.class.type(value)
    if not luaType then
        return
    end
    if value.__encode then
        return value:__encode(), luaType
    else
        return value, luaType
    end
end

---@private
function M.decodeHook(value, tag)
    local class = clicli.class.get(tag)
    if class.__decode then
        return class:__decode(value) or clicli.class.new(tag, value)
    else
        return clicli.class.new(tag, value)
    end
end

--Serialized data
---@param data Serialization.SupportTypes
---@return string
function M.encode(data)
    local bin = seri.encode(data, M.encodeHook, true)
    return bin
end

--Deserialized data
---@param bin string
---@return any
function M.decode(bin)
    local value = seri.decode(bin, M.decodeHook)
    return value
end

return M
