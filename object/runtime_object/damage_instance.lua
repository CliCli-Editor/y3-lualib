--Injury instance
--
--Will be transmitted during injury-related events
---@class DamageInstance
---@overload fun(data: EventParam.单位-受到伤害后, mode: string): self
local M = Class 'DamageInstance'

---@param data EventParam.单位-受到伤害后
---@param mode '伤害前' | '伤害时' | '伤害后'
function M:__init(data, mode)
    ---@private
    self.data = data
    ---@private
    self.mode = mode
end

--Acquire relevant skills
---@return Ability?
function M:get_ability()
    return self.data.ability
end

--Get current damage
---@return number
function M:get_damage()
    return self.data.damage
end

--Modify current damage
---@param damage number
function M:set_damage(damage)
    assert(self.mode ~= '伤害后', '不能在伤害后修改伤害')
    if not self.origin_damage then
        self.origin_damage = self.data.damage --记录一下最开始的原始伤害
    end
    self.data.damage = damage --刷掉伤害，之后的事件拿的伤害值还是老的
    GameAPI.set_cur_damage(Fix32(damage))
end

--Gets whether the current damage is evaded
---@return boolean
function M:is_missed()
    local damage_state = self.data['_py_params']['__damage_result_state']
    return GameAPI.get_cur_damage_is_miss(damage_state)
end

--Sets whether to dodge the current damage
---@param missed boolean
function M:set_missed(missed)
    assert(self.mode == '伤害前', '只能在伤害前修改伤害是否闪避')
    GameAPI.set_cur_damage_is_miss(missed)
end

--Gets whether the current damage is critical
---@return boolean
function M:is_critical()
    local damage_state = self.data['_py_params']['__damage_result_state']
    return GameAPI.get_cur_damage_is_critical(damage_state)
end

--Sets whether the current damage is critical
---@param critical boolean
function M:set_critical(critical)
    assert(self.mode ~= '伤害后', '只能在伤害前(时)修改伤害是否暴击')
    GameAPI.set_cur_damage_is_critical(critical)
end

function M:get_attack_type()
    return self.data['_py_params']['__attack_type']
end

function M:get_damage_type()
    return self.data["_py_params"]["__damage_type"]
end