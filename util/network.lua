---@class Network
---@overload fun(ip: string, port: integer, options?: Network.Options): self
local M = Class 'Network'

---@private
---@type 'new' | 'inited' | 'started' | 'connected' | 'disconnected' | 'error' | 'dead' | 'sleep'
M.state = 'new'

---@private
M._send_buffer = ''

---@class Network.Options
---@field buffer_size? integer # Network buffer size (bytes), default is 2MB
---@field timeout? number # Connection timeout (seconds), which is unlimited by default
---@field update_interval? number # Network update interval (seconds), default is 0.2
---@field retry_interval? number # Reconnection interval (seconds). The default value is 5

---@alias Network.OnConnected fun(self: Network)
---@alias Network.OnData fun(self: Network, data: string)
---@alias Network.OnDisconnected fun(self: Network)
---@alias Network.OnError fun(self: Network, error: string)

---@param ip string
---@param port integer
---@param options? Network.Options
function M:__init(ip, port, options)
    self.ip = ip
    self.port = port
    self.handle = KKNetwork()
    self.options = options or {}
    self.options.buffer_size = self.options.buffer_size or (1024 * 1024 * 2)
    self.options.update_interval = self.options.update_interval or 0.2
    self.options.retry_interval = self.options.retry_interval or 5
    log.debug('Network 初始化：', self)

    ---@private
    self.update_timer = clicli.ctimer.loop(self.options.update_interval, function ()
        self:update()
    end)
    clicli.ctimer.wait(0, function ()
        self:update()
    end)
    self.retry_timer = clicli.ltimer.loop(self.options.retry_interval, function (t)
        self:update()
        if  self.state ~= 'started'
        and self.state ~= 'sleep' then
            t:remove()
            return
        end
        log.debug('Network 重连：', self, self:is_connecting())
        if self.handle.reset and false then
            self.handle:reset()
        else
            self.handle:destroy()
            self.handle = KKNetwork()
        end
        self.state = 'new'
        self:update()
    end)
    if self.options.timeout and self.options.timeout > 0 then
        clicli.ltimer.wait(self.options.timeout, function ()
            self:update()
            if self.state ~= 'started' then
                return
            end
            self:make_error('连接超时')
        end)
    end
end

function M:__del()
    log.debug('Network 销毁：', self)
    self.state = 'dead'
    self.handle:destroy()
    self.update_timer:remove()
    self.retry_timer:remove()
end

function M:__tostring()
    return string.format('{Network|%s|%s|%s}'
        , self.ip
        , self.port
        , self.state
    )
end

---@private
---@param err any
function M:make_error(err)
    if self.state == 'dead' then
        return
    end
    log.debug('Network 错误：', self, err)
    self.state = 'error'
    self:callback('error', err)
    self:remove()
end

---@private
function M:update()
    if self.state == 'error' or self.state == 'dead' then
        self:remove()
        return
    end
    self.handle:run_once()
    if self.state == 'new' then
        local ok, suc, err = pcall(self.handle.init, self.handle, self.ip, self.port, self.options.buffer_size)
        if not ok then
            log.debug('Network 初始化失败：', self, suc)
            self.state = 'sleep'
            return
        end
        if not suc then
            self:make_error(err)
            return
        end
        self.state = 'inited'
    end
    if self.state == 'inited' then
        local suc = self.handle:start()
        if not suc then
            self:make_error('start failed')
            return
        end
        self.state = 'started'
        return
    end
    if self.state == 'started' then
        if self:is_connecting() then
            log.debug('Network 已连接：', self)
            self.state = 'connected'
            self:callback('connected')
        end
        return
    end
    if self.state == 'connected' then
        if not self:is_connecting() then
            log.debug('Network 断开连接：', self)
            self.state = 'disconnected'
            self.handle:stop()
            self:callback('disconnected')
            self:remove()
            return
        end
        local data = self.handle:recv(self.options.buffer_size)
        if data and #data > 0 then
            self:callback('data', data)
        end
        self:send_buffer()
        return
    end
    if self.state == 'disconnected' then
        return
    end
end

---@private
function M:send_buffer()
    local send_buffer = self._send_buffer
    if #send_buffer > 0 then
        self._send_buffer = ''
        local suc, err = self.handle:send(send_buffer, #send_buffer)
        if not suc then
            self:make_error(err)
        end
    end
end

function M:remove()
    Delete(self)
end

---@private
---@param key 'connected' | 'data' | 'disconnected' | 'error'
---@param ... any
function M:callback(key, ...)
    local func = self['_on_' .. key]
    if not func then
        return
    end
    xpcall(func, log.error, self, ...)
end

--Callback after successful connection
---@param on_connected Network.OnConnected
function M:on_connected(on_connected)
    ---@private
    self._on_connected = on_connected
end

--Callback after receiving data
---@param on_data Network.OnData
function M:on_data(on_data)
    ---@private
    self._on_data = on_data
end

--Create a 'blocking' data reader that loops through the 'callback'
--> is mutually exclusive with on_data
--
--The callback will give you a read function 'read', here is its description:
--
--Read the data according to the incoming rules, and if the data does not meet the rules,
--The reader then sleeps until it receives data that satisfies the rule and returns
--* If no arguments are passed:
--Read all received data, similar to 'on_data'
--* If an integer is passed:
--Reads a specified number of bytes of data.
--* If passed 'l' :
--Reads a row of data, excluding newlines.
--* If passed 'L' :
--Reads a row of data, including newlines.
---@param callback async fun(read: async fun(len: nil|integer|'l'|'L'): string)
function M:data_reader(callback)
    local buffer = ''
    local read_once

    ---@async
    local co = coroutine.create(function (reader)
        while true do
            read_once = false
            xpcall(callback, log.error, reader)
            if not read_once then
                log.error([[
数据读取器在本次循环中没有读取任何数据！
请确保你在读取器中至少调用过一次有效的 `read` 函数！
读取器已休眠，将在收到新数据后重新激活。
]])
                coroutine.yield()
            end
        end
    end)

    self:on_data(function (_, data)
        buffer = buffer .. data
        if #buffer > self.options.buffer_size then
            self:make_error('缓冲区溢出!')
            return
        end
        coroutine.resume(co)
    end)

    ---@async
    ---@param what nil|integer|'l'|'L' # 要读取的内容
    ---@return string
    local function read(what)
        if what == nil then
            if #buffer == 0 then
                coroutine.yield()
                --一定是收到数据后才被唤醒的，因此不用再判断缓存了
            end
            read_once = true
            buffer = ''
            return buffer
        end
        if what == 'l'
        or what == 'L' then
            local pos
            local init = 1
            while true do
                pos = buffer:find('\n', init, true)
                if pos then
                    break
                end
                init = #buffer + 1
                coroutine.yield()
            end
            read_once = true
            local data = buffer:sub(1, pos)
            buffer = buffer:sub(pos + 1)
            if what == 'l' then
                if data:sub(-2) == '\r\n' then
                    data = data:sub(1, -3)
                else
                    data = data:sub(1, -2)
                end
                return data
            else
                return data
            end
        end
        if math.type(what) == 'integer' then
            ---@cast what integer
            if what <= 0 then
                return ''
            end
            while what > #buffer do
                coroutine.yield()
            end
            read_once = true
            local data = buffer:sub(1, what)
            buffer = buffer:sub(what + 1)
            return data
        end
        error('无效的读取规则:' .. tostring(what))
    end

    coroutine.resume(co, read)
end

--Callback after disconnection
---@param on_disconnected Network.OnDisconnected
function M:on_disconnected(on_disconnected)
    ---@private
    self._on_disconnected = on_disconnected
end

--A callback after an error occurs
---@param on_error Network.OnError
function M:on_error(on_error)
    ---@private
    self._on_error = on_error
end

--Whether connected
---@return boolean
function M:is_connecting()
    return self.handle:is_connecting()
end

---@param data string
function M:send(data)
    self._send_buffer = self._send_buffer .. data
    if self:is_connecting() then
        self:send_buffer()
    end
end

---@class Network.API
local API = {}

--Create a socket client and connect to the target server
---@param ip string # IP address
---@param port integer # Port number
---@param options? Network.Options # disposition
---@return Network
function API.connect(ip, port, options)
    local network = New 'Network' (ip, port, options)
    return network
end

return API
