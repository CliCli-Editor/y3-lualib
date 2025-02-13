--chooser
--
--Used to select units within a region
---@class Selector
---@overload fun(): self
local M = Class 'Selector'

---@return self
function M:__init()
    return self
end

--Shape - Adds shape objects
---@param pos Point
---@param shape Shape
---@return self
function M:in_shape(pos, shape)
    ---@private
    self._pos   = pos
    ---@private
    self._shape = shape
    return self
end

--Shape - In a circular area
---@param cent Point | Unit | Item
---@param radius number
---@return self
function M:in_range(cent, radius)
    if cent.type == 'unit' then
        ---@cast cent Unit
        self._pos = cent:get_point()
    elseif cent.type == 'item' then
        ---@cast cent Item
        self._pos = cent:get_point()
    else
        ---@cast cent Point
        ---@private
        self._pos = cent
    end
    ---@private
    self._shape = clicli.shape.create_circular_shape(radius)
    return self
end

--Condition - Is an enemy of a player
---@param p Player
---@return self
function M:is_enemy(p)
    ---@private
    self._owner_player = clicli.player_group.get_enemy_player_group_by_player(p)
    return self
end

--Condition - Is an ally of a player
---@param p Player
---@return self
function M:is_ally(p)
    ---@private
    self._owner_player = clicli.player_group.get_ally_player_group_by_player(p)
    return self
end

--Condition - Belongs to a player or a group of players
---@param p Player | PlayerGroup
---@return self
function M:of_player(p)
    ---@private
    self._owner_player = p
    return self
end

--Condition - Visible to a player
---@param p Player
---@return self
function M:is_visible(p)
    ---@private
    self._visible_player = p
    return self
end

--Condition - Not visible to a player
---@param p Player
---@return self
function M:not_visible(p)
    ---@private
    self._invisible_player = p
    return self
end

--Condition - Not in a unit group
---@param ug UnitGroup
---@return self
function M:not_in_group(ug)
    ---@private
    self._not_in_unit_group = ug
    return self
end

--Condition - Have a specific label
---@param tag string
---@return self
function M:with_tag(tag)
    ---@private
    self._with_tag = tag
    return self
end

--Condition - Do not own a specific label
---@param tag string?
---@return self
function M:without_tag(tag)
    ---@private
    self._without_tag = tag
    return self
end

--Condition - Not a specific unit
---@param u Unit
---@return self
function M:not_is(u)
    ---@private
    self._not_is = u
    return self
end

--Condition - Having a certain state
---@param state integer | clicli.Const.UnitEnumState
---@return self
function M:in_state(state)
    ---@private
    self._in_state = state | (clicli.const.UnitEnumState[state] or state)
    return self
end

--Condition - Does not possess a particular state
---@param state integer | clicli.Const.UnitEnumState
---@return self
function M:not_in_state(state)
    ---@private
    self._not_in_state = state | (clicli.const.UnitEnumState[state] or state)
    return self
end

--Condition - Is a specific unit type
---@param unit_key py.UnitKey
---@return self
function M:is_unit_key(unit_key)
    ---@private
    self._unit_key = unit_key
    return self
end

--Condition - Is a specific unit type
---@param unit_type py.UnitType
---@return self
function M:is_unit_type(unit_type)
    ---@private
    self._unit_type = unit_type
    return self
end

--Option - Contains dead units
---@return self
function M:include_dead()
    ---@private
    self._include_dead = true
    return self
end

--Options - The number of selections
---@param count integer
---@return self
function M:count(count)
    ---@private
    self._count = count
    return self
end

---@enum(key) Selector.SortType
local sort_type = {
    ['由近到远'] = 0,
    ['由远到近'] = 1,
    ['随机'] = 2,
}

--Sort - Sort in a certain way
---@param st Selector.SortType
---@return Selector
function M:sort_type(st)
    ---@private
    self._sort_type = sort_type[st] or st
    return self
end

--Make selection
---@return UnitGroup
function M:get()
    local pos = self._pos
    local shape = self._shape
    assert(pos, '必须设置中心点！')
    assert(shape, '必须设置形状！')
    local py_unit_group = GameAPI.filter_unit_id_list_in_area_v2(
        -- TODO 见问题2
        ---@diagnostic disable-next-line: param-type-mismatch
        pos.handle,
        shape.handle,
        ---@diagnostic disable-next-line: param-type-mismatch
        self._owner_player and self._owner_player.handle or nil,
        self._visible_player and self._visible_player.handle or nil,
        self._invisible_player and self._invisible_player.handle or nil,
        self._not_in_unit_group and self._not_in_unit_group.handle or nil,
        self._with_tag,
        self._without_tag,
        self._unit_key or 0,
        self._not_is and self._not_is.handle or nil,
        self._unit_type,
        self._in_state or 0,
        self._not_in_state or 0,
        self._include_dead,
        self._count or -1,
        self._sort_type
    )
    return New 'UnitGroup' (py_unit_group)
end

--Make selection
---@return Unit[]
function M:pick()
    local ug = self:get()
    return ug:pick()
end

--traversal
function M:ipairs()
    return ipairs(self:pick())
end

--Create picker
---@return Selector
function M.create()
    return New 'Selector' ()
end

return M
