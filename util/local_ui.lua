--Native UI logic framework
---@class LocalUILogic
---@field private _main? UI
---@overload fun(main?: string | UI): self
local M = Class 'LocalUILogic'

---@class LocalUILogic: Storage
Extends('LocalUILogic', 'Storage')
---@class LocalUILogic: GCHost
Extends('LocalUILogic', 'GCHost')

---@type table<LocalUILogic, boolean>
local all_instances = setmetatable({}, { __mode = 'k' })

---@diagnostic disable-next-line: deprecated
local local_player = clicli.player.get_local()

---@class LocalUILogic.OnRefreshInfo
---@field name string
---@field on_refresh fun(ui: UI, local_player: Player, instance: LocalUILogic)

---@class LocalUILogic.OnInitInfo
---@field name string
---@field on_init fun(ui: UI, local_player: Player, instance: LocalUILogic)

---@class LocalUILogic.OnEventInfo
---@field name string
---@field event clicli.Const.UIEvent
---@field on_event fun(ui: UI, local_player: Player, instance: LocalUILogic)

---@class LocalUILogic.PrefabInfo
---@field child_name string
---@field prefab_logic LocalUILogic
---@field prefab_token any

---@param path_or_ui? string | UI
function M:__init(path_or_ui)
    all_instances[self] = true
    ---@private
    self._bind_unit_attr = {}
    ---@package
    ---@type LocalUILogic.OnRefreshInfo[]
    self._on_refreshs = {}
    ---@package
    ---@type LocalUILogic.OnEventInfo[]
    self._on_events = {}
    ---@package
    ---@type LocalUILogic.OnInitInfo[]
    self._on_inits = {}
    ---@package
    ---@type LocalUILogic.PrefabInfo[]
    self._prefab_infos = {}
    ---@package
    ---@type table<string, true>
    self._need_refresh = {}

    if type(path_or_ui) == 'string' then
        clicli.ltimer.wait(0, function ()
            local main = clicli.ui.get_ui(local_player, path_or_ui)
            self:attach(main)
        end)
    end
    if type(path_or_ui) == 'table' then
        self:attach(path_or_ui)
    end
end

---删除本地UI逻辑
function M:remove()
    Delete(self)
end

---@package
---@param prefab_name string
function M:as_prefab(prefab_name)
    ---@private
    self._as_template = true
    ---@private
    self._prefab_name = prefab_name
end

---@private
---@param kv? table
---@return LocalUILogic
function M:make_instance(kv)
    local instance = New 'LocalUILogic' ()
    instance._bind_unit_attr = self._bind_unit_attr
    instance._on_refreshs = self._on_refreshs
    instance._on_events = self._on_events
    instance._on_inits = self._on_inits
    instance._prefab_infos = self._prefab_infos

    instance:apply_kv(kv)

    return instance
end

---@param kv? table
function M:apply_kv(kv)
    if kv then
        for k, v in pairs(kv) do
            self:storage_set(k, v)
        end
    end
end

--Attach to a UI
---@param ui UI
---@param kv? table # The data is obtained using 'instance:storage_get'
---@return LocalUILogic
function M:attach(ui, kv)
    assert(not self._main, '已经附着到UI上了！')
    --如果自己是模板，就复制一个实例出来再附着
    if self._as_template then
        local instance = self:make_instance(kv)
        instance:attach(ui)
        return instance
    end
    self._main = ui
    for _, v in ipairs(self._bind_unit_attr) do
        self:bind_unit_attr(v.child_name, v.ui_attr, v.unit_attr, v.accuracy)
    end

    ---@private
    ---@type table<string, UI|false>
    self._childs = setmetatable({}, { __index = function (t, k)
        local ui = self._main and self._main:get_child(k)
        t[k] = ui or false
        return t[k]
    end })

    ---@private
    ---@type table<string, LocalUILogic.OnRefreshInfo[]>
    self._refresh_targets = setmetatable({}, { __index = function (t, k)
        local uis = self:get_refresh_targets(k)
        t[k] = uis
        return t[k]
    end })

    ---@package
    ---@type table<string, table<string, LocalUILogic[]>>
    self._prefab_instances = clicli.util.multiTable(3)

    ---@package
    ---@type table<string, table<string, LocalUILogic[]>>
    self._prefab_pool = clicli.util.multiTable(3)

    self._childs[''] = self._main
    self:init()
    self:refresh('*')

    self:register_events()

    return self
end

function M:detach()
    self._main = nil
end

--Binds the properties of the child control to the properties of the unit
---@param child_name string
---@param ui_attr clicli.Const.UIAttr
---@param unit_attr clicli.Const.UnitAttr | string
---@param accuracy? integer # Fractional precision
function M:bind_unit_attr(child_name, ui_attr, unit_attr, accuracy)
    if not self._main then
        table.insert(self._bind_unit_attr, {
            child_name = child_name,
            ui_attr = ui_attr,
            unit_attr = unit_attr,
            accuracy = accuracy,
        })
        return
    end
    local child = self._main:get_child(child_name)
    if not child then
        return
    end
    child:bind_unit_attr(ui_attr, unit_attr, accuracy)
end

--Subscribe to the control refresh, the callback function is executed in the * local player * environment.
---@param child_name string # The empty string represents the master device
---@param on_refresh fun(ui: UI, local_player: Player, instance: LocalUILogic)
function M:on_refresh(child_name, on_refresh)
    table.insert(self._on_refreshs, {
        name = child_name,
        on_refresh = on_refresh
    })
end

--Subscribe to the control's local events, and the callback function is executed in the * local player * environment.
---@param child_name string # The empty string represents the master device
---@param event clicli.Const.UIEvent
---@param callback fun(ui: UI, local_player: Player, instance: LocalUILogic)
function M:on_event(child_name, event, callback)
    table.insert(self._on_events, {
        name = child_name,
        event = event,
        on_event = callback
    })
end

--Subscribe to the initialization event of the control, the callback function is executed in the local player environment.
---@param child_name string # The empty string represents the master device
---@param on_init fun(ui: UI, local_player: Player, instance: LocalUILogic)
function M:on_init(child_name, on_init)
    table.insert(self._on_inits, {
        name = child_name,
        on_init = on_init
    })
end

--Binding element
---@param child_name string # The empty string represents the master device
---@param prefab_logic LocalUILogic # Component logic created using 'clicli.local_ui.prefab'
---@param prefab_token? any # If you bind the same components under different controls and need to refresh them separately, you can set different tokens for them
function M:bind_prefab(child_name, prefab_logic, prefab_token)
    table.insert(self._prefab_infos, {
        child_name = child_name,
        prefab_logic = prefab_logic,
        prefab_token = prefab_token or prefab_logic,
    })
end

--Refresh element
---@param prefab_token any # The component to refresh defaults to the component logic at binding time
---@param count? integer # Modify the number of components
---@param on_create? fun(index: integer, kv: table) # When creating a new component callback, 'kv' defaults to set 'index' to which component it is.
---@param on_refresh? fun(ui: UI, local_player: Player, instance: LocalUILogic) # To refresh the callback before the component, you can take the opportunity to set the properties of the component with the 'instance:storage_set'.
function M:refresh_prefab(prefab_token, count, on_create, on_refresh)
    if not self._main then
        error('还未初始化完成，请放到 `on_init` 事件中执行！')
    end
    for _, info in ipairs(self._prefab_infos) do
        if info.prefab_token ~= prefab_token then
            goto continue
        end
        local parent = self._childs[info.child_name]
        if not parent then
            goto continue
        end
        local instances = self._prefab_instances[info.child_name][prefab_token]
        local pool = self._prefab_pool[info.child_name][prefab_token]

        if count and count ~= #instances then
            if count < #instances then
                for i = count + 1, #instances do
                    local ui = instances[i]._main
                    if ui then
                        pool[#pool+1] = instances[i]
                        ui:set_visible(false)
                    else
                        instances[i]:remove()
                    end
                    instances[i] = nil
                end
            else
                for i = #instances + 1, count do
                    local kv = { index = i }
                    if on_create then
                        xpcall(on_create, log.error, i, kv)
                    end

                    ---@type LocalUILogic?
                    local instance = table.remove(pool)
                    if instance then
                        local ui = instance._main
                        if ui then
                            ui:set_visible(true)
                        end
                        instance:apply_kv(kv)
                        instance:init()
                    else
                        local ui = clicli.ui_prefab.create(local_player, info.prefab_logic._prefab_name, parent):get_child()
                        ---@cast ui -?
                        instance = info.prefab_logic:attach(ui, kv)
                        self:bindGC(ui)
                    end

                    instances[i] = instance
                end
            end
        end

        for _, instance in ipairs(instances) do
            if on_refresh then
                xpcall(on_refresh, log.error, instance._main, local_player, instance)
            end
            instance:refresh('*')
        end
        ::continue::
    end

end

---@private
function M:register_events()
    for _, info in ipairs(self._on_events) do
        local ui = self._childs[info.name]
        if ui then
            ui:add_local_event(info.event, function ()
                info.on_event(ui, local_player, self)
            end)
        else
            log.error('控件不存在！', info.name)
        end
    end
end

local function is_child_name(target, name)
    if target == name then
        return true
    end
    if clicli.util.stringStartWith(name, target .. '.') then
        return true
    end
    return false
end

---@private
---@param name string
---@return LocalUILogic.OnRefreshInfo[]
function M:get_refresh_targets(name)
    if name == '*' then
        return self._on_refreshs
    end
    local targets = {}
    for _, info in ipairs(self._on_refreshs) do
        if is_child_name(name, info.name) then
            targets[#targets+1] = info
        end
    end
    return targets
end

---@package
function M:init()
    for _, info in ipairs(self._on_inits) do
        local ui = self._childs[info.name]
        if ui then
            xpcall(info.on_init, log.error, ui, local_player, self)
        else
            log.error('控件不存在！', info.name)
        end
    end
end

---@private
---@type ClientTimer
M._refresh_next_tick_timer = nil

--The refresh control, the specified control, and its child controls receive a refresh message.
--Refresh all controls when the parameter is' * '.
---@param name string
---@param player? Player # Refresh only for this player
function M:refresh(name, player)
    if not self._main then
        return
    end

    if player and player ~= local_player then
        return
    end

    self._need_refresh[name] = true

    if not self._refresh_next_tick_timer then
        self._refresh_next_tick_timer = clicli.ctimer.wait(0, function ()
            self._refresh_next_tick_timer = nil
            self:refreshAll()
        end)
    end
end

---@private
function M:refreshAll()
    local need_refresh = self._need_refresh
    self._need_refresh = {}
    local mark = {}
    for name in pairs(need_refresh) do
        local infos = self._refresh_targets[name]
        for _, info in ipairs(infos) do
            local ui = self._childs[info.name]
            if ui then
                if not mark[ui] then
                    mark[ui] = true
                    xpcall(info.on_refresh, log.error, ui, local_player, self)
                end
            else
                log.error('控件不存在！', info.name)
            end
        end
    end
end

clicli.reload.onBeforeReload(function (reload, willReload)
    for instance in pairs(all_instances) do
        for _, info in pairs(instance._on_refreshs) do
            if reload:isValidName(clicli.reload.getIncludeName(info.on_refresh)) then
                info.on_refresh = function () end
            end
        end
        for _, info in pairs(instance._on_events) do
            if reload:isValidName(clicli.reload.getIncludeName(info.on_event)) then
                info.on_event = function () end
            end
        end
    end
end)

---@class LocalUILogic.API
local API = {}

---@package
API.instance_map = {}

--Create a local UI logic
---@param path_or_ui string | UI
---@return LocalUILogic
function API.create(path_or_ui)
    if API.instance_map[path_or_ui] then
        API.instance_map[path_or_ui]:remove()
    end
    local local_ui = New 'LocalUILogic' (path_or_ui)
    API.instance_map[path_or_ui] = local_ui
    return local_ui
end

--Create a local UI logic for the component
---@param prefab_name string
---@return LocalUILogic
function API.prefab(prefab_name)
    local logic = New 'LocalUILogic' ()
    logic:as_prefab(prefab_name)
    return logic
end

return API
