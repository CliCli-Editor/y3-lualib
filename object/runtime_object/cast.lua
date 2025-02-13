--Casting example
--
--Will be passed during spell-related events
---@class Cast
---@field package ability Ability
---@field package cast_id integer
---@overload fun(ability: Ability, cast_id: integer): self
local M = Class 'Cast'

---@class Cast: GCHost
Extends('Cast', 'GCHost')
---@class Cast: Storage
Extends('Cast', 'Storage')

---@param ability Ability
---@param cast_id integer
---@return self
function M:__init(ability, cast_id)
    self.ability = ability
    self.cast_id = cast_id
    return self
end

function M:__tostring()
    return string.format('{cast|%d} @ %s'
        , self.cast_id
        , self.ability
    )
end

--Acquire skills
---@return Ability
function M:get_ability()
    return self.ability
end

--Get casting directions
---@return number
function M:get_angle()
    local angle = self.ability.handle:api_get_release_direction(self.cast_id)
    if not angle then
        return 0.0
    end
    return clicli.helper.tonumber(angle) or 0.0
end

--Get the target item
---@return Item?
function M:get_target_item()
    local py_item = GameAPI.get_target_item_in_ability(self.ability.handle, self.cast_id)
    if not py_item then
        return nil
    end
    return clicli.item.get_by_handle(py_item)
end

--Gets the cast target unit
---@return Unit?
function M:get_target_unit()
    local py_unit = GameAPI.get_target_unit_in_ability(self.ability.handle, self.cast_id)
    if not py_unit then
        return nil
    end
    return clicli.unit.get_by_handle(py_unit)
end

--Gets destructible objects from the casting target
---@return Destructible?
function M:get_target_destructible()
    local py_destructible = GameAPI.get_target_dest_in_ability(self.ability.handle, self.cast_id)
    if not py_destructible then
        return nil
    end
    return clicli.destructible.get_by_handle(py_destructible)
end

--Gets the casting target point
---@return Point?
function M:get_target_point()
    local py_point = self.ability.handle:api_get_release_position(self.cast_id)
    if not py_point then
        return nil
    end
    return clicli.point.get_by_handle(py_point)
end


---@class Ability
---@field package _castMap? table<integer, Cast>

---@param ability Ability
---@param cast_id integer
---@return Cast
function M.get(ability, cast_id)
    if not ability._castMap then
        ability._castMap = {}
        ability:event('施法-结束', function (trg, data)
            local id = data.cast.cast_id
            local cast = ability._castMap[id]
            if cast then
                clicli.ltimer.wait(5, function ()
                    ability._castMap[id] = nil
                end)
            end
        end)
    end
    if not ability._castMap[cast_id] then
        local cast = New 'Cast' (ability, cast_id)
        ability._castMap[cast_id] = cast
    end
    return ability._castMap[cast_id]
end

return M
