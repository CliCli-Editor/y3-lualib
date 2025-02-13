---@class Proxy
local M = {}

local RAW       = {'<RAW>'}
local CONFIG    = {'<CONFIG>'}
local CUSTOM    = {'<CUSTOM>'}

---@alias Proxy.Setter fun(self: table, raw: any, key: any, value: any, config: Proxy.Config, custom: any): any
---@alias Proxy.Getter fun(self: table, raw: any, key: any, config: Proxy.Config, custom: any): any

---@class Proxy.Config
---@field cache? boolean # The result of the read/write is cached, and the next read/write will not trigger the setter, getter (unless the last result was nil)
---@field updateRaw? boolean # Whether to write the assignment to 'raw'
---@field recursive? boolean # Recursive proxy or not
---@field setter? { [any]: Proxy.Setter }
---@field getter? { [any]: Proxy.Getter }
---@field anySetter? Proxy.Setter # anySetter is triggered only if there is no corresponding setter
---@field anyGetter? Proxy.Getter # 'anyGetter' is triggered only if there is no corresponding 'getter'
---@field package _recursiveState? table
local defaultConfig = {
    cache     = true,
}

local metatable = {
    __newindex = function (self, key, value)
        local raw    = rawget(self, RAW)
        ---@type Proxy.Config
        local config = rawget(self, CONFIG)
        local custom = rawget(self, CUSTOM)
        local setter = config.setter and config.setter[key]
        local nvalue
        if setter then
            nvalue = setter(self, raw, key, value, config, custom)
        elseif config.anySetter then
            nvalue = config.anySetter(self, raw, key, value, config, custom)
        else
            nvalue = value
        end
        if config.cache then
            rawset(self, key, nvalue)
        end
        if config.updateRaw then
            raw[key] = nvalue
        end
    end,
    __index = function (self, key)
        local raw    = rawget(self, RAW)
        ---@type Proxy.Config
        local config = rawget(self, CONFIG)
        local custom = rawget(self, CUSTOM)
        local getter = config.getter and config.getter[key]
        local value
        if getter then
            value = getter(self, raw, key, config, custom)
        elseif config.anyGetter then
            value = config.anyGetter(self, raw, key, config, custom)
        else
            value = raw[key]
        end
        if config.cache then
            rawset(self, key, value)
        end
        return value
    end,
    __pairs = function (self)
        local raw = rawget(self, RAW)
        local t = {}
        for k in pairs(raw) do
            t[k] = self[k]
        end
        for k in next, self do
            if k ~= RAW and k ~= CONFIG and k ~= CUSTOM then
                t[k] = self[k]
            end
        end
        return next, t, nil
    end,
    __len = function (self)
        local raw = rawget(self, RAW)
        return #raw
    end
}

local metaKV = { __mode = 'kv' }

---@generic T
---@param obj T # The object to proxy
---@param config? Proxy.Config # disposition
---@param custom? any # Custom data
---@return T
function M.new(obj, config, custom)
    local tp = type(obj)
    if tp ~= 'table' and tp ~= 'userdata' then
        error('只有table和userdata可以被代理')
    end
    config = config or defaultConfig

    if config.recursive then
        if not config._recursiveState then
            config._recursiveState = setmetatable({}, metaKV)
        end
        if config._recursiveState[obj] then
            return config._recursiveState[obj]
        end
    end

    local proxy = setmetatable({
        [RAW]    = obj,
        [CONFIG] = config,
        [CUSTOM] = custom,
    }, metatable)

    if config.recursive then
        config._recursiveState[obj] = proxy
    end

    return proxy
end

---@param proxyObj table
---@return any
function M.raw(proxyObj)
    return proxyObj[RAW]
end

---@param proxyObj table
---@return any
function M.rawRecusive(proxyObj)
    local obj = proxyObj[RAW] or proxyObj
    for k, v in pairs(obj) do
        if type(v) == 'table' then
            obj[k] = M.rawRecusive(v)
        end
    end
    return obj
end

---@param proxyObj table
---@return table
function M.config(proxyObj)
    return proxyObj[CONFIG]
end

return M
