---@class Pool
---@field private pool table<any, integer>
---@overload fun(): self
local M = Class 'Pool'

function M:__init()
    ---@private
    self.pool = {}
    ---@private
    self.order = {}
    return self
end

function M:__encode()
    local data = {}
    for obj, w in self:pairs() do
        data[#data+1] = obj
        data[#data+1] = w
    end
    return data
end

function M:__decode(data)
    local pool = New 'Pool' ()
    for i = 1, #data, 2 do
        pool:add(data[i], data[i+1])
    end
    return pool
end

--Add object
---@param obj any
---@param w? integer
function M:add(obj, w)
    if self.pool[obj] then
        self.pool[obj] = self.pool[obj] + (w or 1)
    else
        self.pool[obj] = w or 1
        self.order[#self.order+1] = obj
    end
end

--Remove objects. Do not remove objects during traversal
---@param obj any
function M:del(obj)
    self.pool[obj] = nil
    for i, v in ipairs(self.order) do
        if v == obj then
            self.order[i] = self.order[#self.order]
            self.order[#self.order] = nil
            break
        end
    end
end

--Include object or not
---@param obj any
---@return boolean
function M:has(obj)
    return self.pool[obj] ~= nil
end

---@param other Pool
function M:merge(other)
    for obj, w in other:pairs() do
        self:add(obj, w)
    end
end

--Gets the weight of the object
---@param obj any
---@return integer
function M:get_weight(obj)
    return self.pool[obj] or 0
end

--Modify the weight of an object
---@param obj any
---@param w integer
function M:set_weight(obj, w)
    assert(self.pool[obj])
    self.pool[obj] = w
end

--Increases the weight of an object
---@param obj any
---@param w integer
function M:add_weight(obj, w)
    assert(self.pool[obj])
    self.pool[obj] = self.pool[obj] + w
end

--Emptying tank
function M:clear()
    self.pool = {}
    self.order = {}
end

--Pick an object at random
---@param filter? fun(obj: any): boolean
---@return any
function M:random(filter)
    local valid = {}
    local total = 0

    for _, obj in ipairs(self.order) do
        if not filter or filter(obj) == true then
            valid[#valid+1] = obj
            total = total + self.pool[obj]
        end
    end

    if total == 0 then
        return nil
    end

    local r = math.random(total)
    local sum = 0
    for i = 1, #valid do
        local obj = valid[i]
        sum = sum + self.pool[obj]
        if sum >= r then
            return obj
        end
    end

    error('unreachable')
end

--Multiple random objects are extracted without repetition
---@param num integer
---@param filter? fun(obj: any): boolean
---@return any[]
function M:random_n(num, filter)
    local results = {}
    local mark = {}
    for i = 1, num do
        local obj = self:random(function (obj)
            if mark[obj] then
                return false
            end
            if filter and not filter(obj) then
                return false
            end
            return true
        end)
        if not obj then
            break
        end
        results[i] = obj
        mark[obj] = true
    end
    return results
end

--Displays the contents of the pool for debugging purposes only
---@return string
function M:dump()
    local buf = {}
    for i, obj in ipairs(self.order) do
        buf[i] = ('%s: %d'):format(tostring(obj), self.pool[obj])
    end
    return table.concat(buf, '\n')
end

--Iterate over the pool object
---@return fun(): any, integer
function M:pairs()
    local i = 0
    return function ()
        i = i + 1
        local obj = self.order[i]
        return obj, self.pool[obj]
    end
end

---@class Pool.API
local API = {}

---@return Pool
function API.create()
    return New 'Pool' ()
end

return API
