local network  = require 'clicli.util.network'
local console  = require 'clicli.develop.console'
local attr     = require 'clicli.develop.helper.attr'

local nextID = clicli.util.counter()

---@class Develop.Helper
local M = Class 'Develop.Helper'

---@type table<integer, fun(result: any)>
local requestMap = {}

---@type table<integer, fun(params: any): any>
local methodMap = {}

---@type Network
local client

---@param method string
---@param callback fun(params: any): any
function M.registerMethod(method, callback)
    methodMap[method] = callback
end

local function logger(...)
    do return end
    local default = clicli.config.log.toHelper
    clicli.config.log.toHelper = false
    log.debug(...)
    clicli.config.log.toHelper = default
end

--Send a request to the CliCli Development Assistant
---@param method string
---@param params table
---@param callback? fun(data: any) # Received return value
function M.request(method, params, callback)
    if not client then
        if callback then callback(nil) end
        return
    end

    local data = {
        method = method,
        id = nextID(),
        params = params,
    }

    local jsonContent = clicli.json.encode(data)
    logger('send:', jsonContent)
    client:send(string.pack('>s4', jsonContent))

    requestMap[data.id] = callback
end

--Sending requests (coroutines) to the CliCli Development Assistant
---@async
---@param method string
---@param params table
---@return any
function M.awaitRequest(method, params)
    if not client then
        return
    end
    return clicli.await.yield(function (resume)
        M.request(method, params, resume)
    end)
end

--Send notifications to the CliCli Development Assistant
---@param method string
---@param params table
function M.notify(method, params)
    if not client then
        return
    end

    local data = {
        method = method,
        params = params,
    }

    local jsonContent = clicli.json.encode(data)
    logger('send:', jsonContent)
    client:send(string.pack('>s4', jsonContent))
end

---@private
---@param id integer
---@param result any
---@param err? string
function M.response(id, result, err)
    if not client then
        return
    end

    local data = {
        id = id,
        result = result,
        error = err,
    }

    local jsonContent = clicli.json.encode(data)
    logger('resp:', jsonContent)
    client:send(string.pack('>s4', jsonContent))
end

local function handleBody(body)
    logger('recv:', body)
    local data = clicli.json.decode(body)
    local id = data.id
    if data.method then
        --request
        local callback = methodMap[data.method]
        if callback then
            local suc, res = xpcall(callback, log.error, data.params)
            if id then
                if suc then
                    M.response(id, res)
                else
                    M.response(id, nil, res)
                end
            end
        else
            if id then
                M.response(id, nil, '未找到方法：' .. tostring(data.method))
            end
        end
    else
        --response
        if data.error then
            logger(data.error)
        end
        local callback = requestMap[id]
        if callback then
            requestMap[id] = nil
            xpcall(callback, log.error, data.result)
        end
    end
end

local onReadyCallbacks = {}

---@param port integer
---@return Network 
local function createClient(port)
    client = network.connect('127.0.0.1', port, {
        update_interval = 0.05,
        timeout = nil,
    })

    client:on_connected(function (self)
        clicli.player.with_local(function (local_player)
            local arg = GameAPI.lua_get_start_args()
            M.notify('updatePlayer', {
                name = local_player:get_name(),
                id   = local_player:get_id(),
                multiMode = arg['lua_multi_mode'] == 'true',
            })
        end)
        M.print(console.getHelpInfo())

        local callbacks = onReadyCallbacks
        onReadyCallbacks = nil
        for _, callback in ipairs(callbacks) do
            xpcall(callback, log.error, client)
        end
    end)

    client:on_error(function (self, error)
        print('VSCode链接发生错误：', error)
        clicli.ctimer.wait(1, function ()
            createClient(port)
        end)
    end)

    client:on_disconnected(function (self)
        print('VSCode链接断开!')
        clicli.ctimer.wait(1, function ()
            createClient(port)
        end)
    end)

    ---@async
    client:data_reader(function (read)
        local head = read(4)
        local len = string.unpack('>I4', head)
        local body = read(len)
        xpcall(handleBody, log.error, body)
    end)

    return client
end

--Called when the CliCli Development Assistant is ready
---@param callback fun()
function M.onReady(callback)
    if not onReadyCallbacks then
        xpcall(callback, log.error)
        return
    end
    onReadyCallbacks[#onReadyCallbacks+1] = callback
end

--Is CliCli Development Assistant ready
---@return boolean
function M.isReady()
    return client ~= nil
end

--Print a message on the terminal of the CliCli Development Assistant
---@param message string
function M.print(message)
    M.notify('print', {
        message = message:sub(1, 10000)
    })
end

---@class Develop.Helper.RestartOptions
---@field debugger? boolean # Whether to start the debugger. If omitted, it determines whether a debugger is needed based on whether it is currently attached.
---@field id? integer  多开模式下自己的id

--Ready to restart the game
function M.prepareForRestart()
    local arg = GameAPI.lua_get_start_args()
    clicli.player.with_local(function (local_player)
        M.notify('prepareForRestart', {
            debugger = LDBG
                and (arg['lua_wait_debugger'] == 'true'
                  or arg['lua_multi_wait_debugger'] == 'true'),
            id = LDBG
                and arg['lua_multi_mode'] == 'true'
                ---@diagnostic disable-next-line: deprecated
                and local_player:get_id()
                or nil,
        })
    end)
end

---@param command string
---@param args? any[]
---@param callback? fun(result: any)
function M.requestCommand(command, args, callback)
    M.request('command', {
        command = command,
        args = args,
    }, callback)
end

---@private
---@type table<string, Develop.Helper.TreeView>
M.treeViewMap = {}

--Create a tree view on the CliCli Development Assistant view
---@param name string
---@param root Develop.Helper.TreeNode
---@return Develop.Helper.TreeView
function M.createTreeView(name, root)
    if M.treeViewMap[name] then
        M.treeViewMap[name]:remove()
    end
    local treeView = New 'Develop.Helper.TreeView' (name, root)
    M.treeViewMap[name] = treeView
    return treeView
end

--Create a node on the tree view of the CliCli Development Assistant
---@param name string
---@param optional? Develop.Helper.TreeNode.Optional
---@return Develop.Helper.TreeNode
function M.createTreeNode(name, optional)
    local treeNode = New 'Develop.Helper.TreeNode' (name, optional)
    return treeNode
end

---在《CliCli开发助手》上创建一个输入框
---@param optional? Develop.Helper.InputBox.Optional
---@return Develop.Helper.InputBox
function M.createInputBox(optional)
    local inputBox = New 'Develop.Helper.InputBox' (optional)
    return inputBox
end

---在《CliCli开发助手》上创建一个属性监视器
---@param unit Unit # Units to be monitored
---@param attrType clicli.Const.UnitAttr # Attribute name
---@param condition? Develop.Attr.Accept # Breakpoint expressions, such as' >= 100 ', '<=' maximum life / 2 '
---@return Develop.Helper.TreeNode
function M.createAttrWatcher(unit, attrType, condition)
    return attr.add(unit, attrType, condition)
end

---@private
M._inited = false

--Initializes the connection to the CliCli Development Assistant. If you start the game with VSCode, it will connect automatically.
--In other cases, you can call this function connection if required.
---@param port? integer # Destination port number. If not specified, use the random port delivered by the CliCli Development Assistant
---@param force? boolean # Whether to allow repeated connections
---@return { network: Network, explorer: Develop.Helper.TreeView }?
function M.init(port, force)
    local explorer = require 'clicli.develop.helper.explorer'
    if M._inited and not force then
        return nil
    end
    M._inited = true
    local result = {}
    if port then
        result.network = createClient(port)
        result.explorer = explorer.create()
    else
        local suc, port = pcall(require, 'log.helper_port')
        if not suc or math.type(port) ~= 'integer' then
            return nil
        end

        result.network = createClient(port)
        result.explorer = explorer.create()
    end
    return result
end

--Register a method
M.registerMethod('command', function (params)
    clicli.develop.console.input(params.data)
end)

clicli.game:event_on('$CliCli-初始化', function ()
    if not clicli.game.is_debug_mode() then
        return
    end
    local arg = GameAPI.lua_get_start_args()
    if not arg['lua_dummy'] then
        return
    end

    M.init()
end)

clicli.game:event_on('$CliCli-即将切换关卡', function ()
    M.prepareForRestart()
end)

return M
