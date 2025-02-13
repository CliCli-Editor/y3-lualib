--Interface element
---@class UIPrefab
---@field handle string
---@field player Player
---@overload fun(player: Player, py_ui_prefab: string): self
local M = Class 'UIPrefab'

---@class UIPrefab: KV
Extends('UIPrefab', 'KV')

M.type = 'ui_prefab'

---@param player Player
---@param ui_name string
---@return self
function M:__init(player, ui_name)
    self.handle = ui_name
    self.player = player
    return self
end

function M:__del()
    GameAPI.del_ui_prefab(self.handle)
end

---通过py层的界面实例获取lua层的界面实例
---@param  player Player 玩家
---@param  prefab_name string
---@return UIPrefab # Returns the lua layer skill instance after being initialized at the lua layer
function M.get_by_handle(player, prefab_name)
    local ui_prefab = New 'UIPrefab' (player, prefab_name)
    return ui_prefab
end

--Example Create an interface module instance
---@param  player Player 玩家
---@param  prefab_name string 界面模块id
---@param  parent_ui UI 父控件
---@return UIPrefab
function M.create(player, prefab_name, parent_ui)
    local py_ui_prefab = GameAPI.create_ui_prefab_instance(player.handle, clicli.ui.comp_id[prefab_name], parent_ui.handle)
    return M.get_by_handle(player, py_ui_prefab)
end

--Example Delete an interface module instance
function M:remove()
    Delete(self)
end

--Gets the UI instance of UIPrefab
--> Use the 'get_child' method instead
---@deprecated
---@param  player Player 玩家
---@return UI
function M:get_ui(player)
    ---@diagnostic disable-next-line: param-type-mismatch
    return clicli.ui.get_by_handle(player, GameAPI.get_ui_prefab_child_by_path(self.handle, ""))
end

--Gets the UI instance of UIPrefab
--> Attention! The path here is relative to the first layer of * nodes (that is, there is a node in the node list that cannot be deleted by default, that is the first layer).
---@param child_path? string 路径，默认为根节点。
---@return UI?
function M:get_child(child_path)
    ---@diagnostic disable-next-line: param-type-mismatch
    local py_ui = GameAPI.get_ui_prefab_child_by_path(self.handle, '')
    if not py_ui then
        return nil
    end

    local ui = clicli.ui.get_by_handle(self.player, py_ui)
    if child_path and #child_path > 0 then
        return ui:get_child(child_path)
    end

    return ui
end

return M
