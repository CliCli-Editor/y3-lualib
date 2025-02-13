---@type table<string, string>
arg = GameAPI.lua_get_start_args()

require 'clicli.debugger'

--The global method class provides a variety of global methods
---@class CliCli
clicli = {}

clicli.version = 250116

clicli.proxy   = require 'clicli.tools.proxy'
clicli.class   = require 'clicli.tools.class'
clicli.util    = require 'clicli.tools.utility'
clicli.json    = require 'clicli.tools.json'
clicli.inspect = require 'clicli.tools.inspect'
clicli.await   = require 'clicli.tools.await'
pcall(function ()
    clicli.doctor = require 'clicli.tools.doctor'
end)

Class   = clicli.class.declare
New     = clicli.class.new
---@deprecated
---@diagnostic disable-next-line: deprecated
Super   = clicli.class.super
Extends = clicli.class.extends
Delete  = clicli.class.delete
IsValid = clicli.class.isValid
Type    = clicli.class.type
Alias   = clicli.class.alias
IsInstanceOf = clicli.class.isInstanceOf

require 'clicli.util.log'
clicli.reload  = require 'clicli.tools.reload'
clicli.sandbox = require 'clicli.tools.sandbox'
clicli.hash    = require 'clicli.tools.SDBMHash'
clicli.linked_table = require 'clicli.tools.linked-table'
---@deprecated
clicli.linkedTable = clicli.linked_table
Alias('LinkedTable', clicli.linkedTable.create)

---@diagnostic disable-next-line: lowercase-global
include  = clicli.reload.include

clicli.pool = require 'clicli.tools.pool'
require 'clicli.tools.gc'
require 'clicli.tools.synthesis'

require 'clicli.util.patch'
require 'clicli.util.eca_function'
clicli.trigger = require 'clicli.util.trigger'
require 'clicli.util.event'
require 'clicli.util.event_manager'
require 'clicli.util.custom_event'
require 'clicli.util.ref'
require 'clicli.util.storage'
require 'clicli.util.gc_buffer'

clicli.ctimer       = require 'clicli.util.client_timer'
clicli.const        = require 'clicli.game.const'
clicli.math         = require 'clicli.game.math'
clicli.game         = require 'clicli.game.game'
clicli.py_converter = require 'clicli.game.py_converter'
clicli.helper       = require 'clicli.game.helper'
clicli.ground       = require 'clicli.game.ground'
clicli.config       = require 'clicli.game.config'
clicli.kv           = require 'clicli.game.kv'
clicli.steam        = require 'clicli.game.steam'
clicli.timer        = require 'clicli.object.runtime_object.timer'
clicli.ltimer       = require 'clicli.util.local_timer'
clicli.py_event_sub = require 'clicli.game.py_event_subscribe'

clicli.unit         = require 'clicli.object.editable_object.unit'
clicli.ability      = require 'clicli.object.editable_object.ability'
clicli.destructible = require 'clicli.object.editable_object.destructible'
clicli.item         = require 'clicli.object.editable_object.item'
clicli.buff         = require 'clicli.object.editable_object.buff'
clicli.projectile   = require 'clicli.object.editable_object.projectile'
clicli.technology   = require 'clicli.object.editable_object.technology'

clicli.beam         = require 'clicli.object.runtime_object.beam'
clicli.item_group   = require 'clicli.object.runtime_object.item_group'
clicli.mover        = require 'clicli.object.runtime_object.mover'
clicli.force        = require 'clicli.object.runtime_object.force'
clicli.particle     = require 'clicli.object.runtime_object.particle'
clicli.player       = require 'clicli.object.runtime_object.player'
clicli.player_group = require 'clicli.object.runtime_object.player_group'
clicli.unit_group   = require 'clicli.object.runtime_object.unit_group'
clicli.projectile_group = require 'clicli.object.runtime_object.projectile_group'
clicli.selector     = require 'clicli.object.runtime_object.selector'
clicli.cast         = require 'clicli.object.runtime_object.cast'
clicli.damage_instance = require 'clicli.object.runtime_object.damage_instance'
clicli.heal_instance   = require 'clicli.object.runtime_object.heal_instance'
clicli.sound        = require 'clicli.object.runtime_object.sound'

require 'clicli.object.runtime_object.local_player'
require 'clicli.object.runtime_object.current_select'

clicli.area         = require 'clicli.object.scene_object.area'
clicli.camera       = require 'clicli.object.scene_object.camera'
clicli.light        = require 'clicli.object.scene_object.light'
clicli.road         = require 'clicli.object.scene_object.road'
clicli.point        = require 'clicli.object.scene_object.point'
clicli.scene_ui     = require 'clicli.object.scene_object.scene_ui'
clicli.ui           = require 'clicli.object.scene_object.ui'
clicli.ui_prefab    = require 'clicli.object.scene_object.ui_prefab'
clicli.shape        = require 'clicli.object.scene_object.shape'

clicli.object       = require 'clicli.util.object'
clicli.save_data    = require 'clicli.util.save_data'
clicli.dump         = require 'clicli.util.dump'
clicli.sync         = require 'clicli.util.sync'
clicli.network      = require 'clicli.util.network'
clicli.eca          = require 'clicli.util.eca_helper'
clicli.base64       = require 'clicli.util.base64'
clicli.aes          = require 'clicli.util.aes'
clicli.local_ui     = require 'clicli.util.local_ui'
clicli.fs           = require 'clicli.util.fs'
clicli.rt           = require 'clicli.util.eca_runtime'
clicli.rsa          = require 'clicli.util.rsa'

pcall(function ()
    require 'clicli-helper.meta'
end)

clicli.develop = {}
clicli.develop.command = include 'clicli.develop.command'
clicli.develop.code    = require 'clicli.develop.code'
clicli.develop.console = include 'clicli.develop.console'
clicli.develop.helper  = require 'clicli.develop.helper'

--Do some configuration on await
clicli.await.setErrorHandler(log.error)
clicli.await.setSleepWaker(clicli.ltimer.wait)

log.info('LuaLib版本：', clicli.version)

clicli.game:event_dispatch('$CliCli-初始化')

if LDBG then
    clicli.ltimer.loop_frame(1, function ()
        LDBG:event 'update'
    end)
end

if arg['lua_tracy'] == 'true' then
    clicli.ltimer.wait_frame(0, function ()
        enable_lua_profile(true)
    end)
end

--Own control of GC
GlobalAPI.api_stop_luagc_control()
--collectgarbage('generational')
--collectgarbage('incremental')
--collectgarbage('restart')
local collector = require 'clicli.tools.collector'
collector.start()
