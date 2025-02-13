--Sync local data to all players
---@class Sync
local M = Class 'Sync'

---@private
M.syncMap = {}

--Send local messages and use 'onSync' to synchronize receiving data
--Use this function in your local environment
---@param id string # Ids beginning with '$' are reserved for internal use
---@param data Serialization.SupportTypes
function M.send(id, data)
    local bin = clicli.dump.encode(data)
    broadcast_lua_msg(id, bin)
end

--The data is received synchronously, and the callback function is executed after synchronization
--Only one callback function can be registered with the same id, and the later ones will overwrite the earlier ones
---@param id string
---@param callback fun(data: Serialization.SupportTypes, source: Player)
function M.onSync(id, callback)
    M.syncMap[id] = callback
end

clicli.game:event('游戏-接收广播信息', function (trg, data)
    local id = data.broadcast_lua_msg_id
    local callback = M.syncMap[id]
    if not callback then
        return
    end
    local suc, value = pcall(clicli.dump.decode, data.broadcast_lua_msg_content)
    if not suc then
        return
    end
    xpcall(callback, log.error, value, data.player)
end)

return M
