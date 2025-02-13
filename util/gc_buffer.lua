---@overload fun(atLeast: number, gcObject: Class.Base):GCBuffer
---@class GCBuffer
local M = Class 'GCBuffer'

---@package
M.passedTime = 0

---@param atLeast number # At least wait that long before removing it
---@param gcObject Class.Base # The object to remove
function M:__init(atLeast, gcObject)
    ---@package
    self.atLeast = atLeast
    ---@package
    self.gcObject = gcObject
end

function M:__del()
    M.startTimer()
    self.queue[#self.queue+1] = self
end

---@package
function M.startTimer()
    if M.timer then
        return
    end
    local needDelete = {}
    ---@package
    M.queue = {}
    ---@private
    M.timer = clicli.ltimer.loop(1, function ()
        local c = 0
        for i, buffer in pairs(M.queue) do
            c = c + 1
            if c > 10000 then
                break
            end
            buffer.passedTime = buffer.passedTime + 1
            if buffer.passedTime > buffer.atLeast then
                M.queue[i] = nil
                needDelete[#needDelete+1] = buffer.gcObject
            end
        end
        for i, gcObject in ipairs(needDelete) do
            gcObject:remove()
            needDelete[i] = nil
        end
    end)
end
