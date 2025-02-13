---配置
---
---可以设置日志、同步等相关的配置
---@class Config
local M = Class 'Config'

---同步相关的配置，当设置为 `true` 后将启用同步，
---会产生额外的流量。  
---同步需要一定的时间，获取到的是一小段时间前的状态，
---因此启用同步后不能立即获取状态。  
---@class Config.Sync
---@field mouse boolean # Sync the player's mouse position
---@field key boolean # Sync the player's keyboard and mouse keys
---@field camera boolean # Sync the player's shots
M.sync = clicli.proxy.new({
    mouse  = false,
    key    = false,
    camera = false,
}, {
    updateRaw = true,
    setter = {
        mouse = function (self, raw, key, value, config)
            assert(type(value) == 'boolean', ('`Config.sync.%s` 的赋值类型必须是 `boolean`'):format(key))
            GameAPI.force_enable_mouse_sync(value)
            return value
        end,
        key = function (self, raw, key, value, config)
            assert(type(value) == 'boolean', ('`Config.sync.%s` 的赋值类型必须是 `boolean`'):format(key))
            GameAPI.force_enable_keyboard_sync(value)
            return value
        end,
        camera = function (self, raw, key, value, config)
            assert(type(value) == 'boolean', ('`Config.sync.%s` 的赋值类型必须是 `boolean`'):format(key))
            GameAPI.force_enable_camera_sync(value)
            return value
        end,
    },
})

--Yes No debug mode
---@type boolean|'auto'
M.debug = 'auto'

---@class Config.Log
---@field level Log.Level # The default log level is debug
---@field toFile boolean # Whether to print to a file. The default is true
---@field toDialog boolean # Whether to print to the Dialog window. The default is true
---@field toConsole boolean # Whether to print to the console, defaults to true
---@field toGame boolean # Whether to print to the game window, the default is' false '
---@field toHelper boolean # Whether to print to CliCli Development Assistant, the default is true
---@field logger fun(level: Log.Level, message: string, timeStamp: string): boolean # A custom log handler that returns' true 'will block the default log handler. This function is masked during the execution of the handler function.
--Log related configuration
M.log = clicli.proxy.new({
    level     = 'debug',
    toFile    = true,
    toDialog  = true,
    toConsole = true,
    toGmae    = false,
    toHelper  = true,
}, {
    updateRaw = true,
    setter = {
        level = function (self, raw, key, value, config)
            log.level = value
        end,
        toFile = function (self, raw, key, value, config)
            log.enable = value
        end,
    }
})

---每秒的逻辑帧率，请将其设置为与你地图中设置的一致。
---目前默认为30帧，未来默认会读取你地图中的设置。
---必须在游戏开始时就设置好，请勿中途修改。
M.logic_frame = GameAPI.api_get_logic_fps
            and GameAPI.api_get_logic_fps()
            or  30

---缓存相关的配置，一般要求你不在ECA中操作相关的对象才可以使用缓存。
M.cache = {
    ---是否对UI进行缓存。需要保证你没有在ECA中操作UI。
    ui = false,
}

---动态执行代码相关的设置
M.code = {
    ---在非debug模式下是否允许执行本地代码。
    enable_local = false,
    ---在非debug模式下是否允许执行其他玩家广播过来的远程代码。
    enable_remote = false,
}

---界面相关设置
M.ui = {
}

---运动器直接使用引擎接口注册
M.mover = {
    enable_internal_regist = false
}

return M
