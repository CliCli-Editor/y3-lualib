local M = {}

local generate_monsters_config = {
    -- 怪物类型                  刷怪数
    { monster_type = 134251991, count = 10 }, --蝎子
    { monster_type = 134246732, count = 10 }, --树人
    { monster_type = 134251991, count = 12 }, --蝎子
    { monster_type = 134246732, count = 12 }, --树人
    { monster_type = 134251991, count = 15 }, --蝎子
    { monster_type = 134246732, count = 15 }, --树人
}

for _, config in ipairs(generate_monsters_config) do
    local monster_type = config.monster_type
    if not clicli.object.unit[monster_type].data then
        error [[
该演示图依赖特定的物编数据，请按照以下步骤安装：

在编辑器中点击 `菜单栏` -> `插件` -> `插件商城`，搜索 `LuaLib`，安装 `LuaLib示例-防守图`（英雄、技能、怪物的物编数据）]]
    end
end

--Monster birth coordinates
local spawn_point = clicli.point.create(0, -2000, 0)
--Monster attack target
local attack_point = clicli.point.create(0, -2000, 0)

--It starts with wave 0 monsters
local wave_index = 0

--Total number of waves
local total_batch_count = #generate_monsters_config

--Monsters alive on the field
local alive_count = 0

local stopped = false

--Brush the next wave of monsters
function M.next_wave()
    if not M.has_next() then
        return
    end

    if stopped then
        return
    end

    wave_index = wave_index + 1

    -- 怪物类型
    local monster_type = generate_monsters_config[wave_index].monster_type

    -- 这一波要刷的怪物数量
    local count = generate_monsters_config[wave_index].count

    -- 每间隔一秒刷一个怪物
    clicli.timer.count_loop(1, count, function()
        if stopped then
            return
        end

        -- 生成怪物
        local monster = clicli.unit.create_unit(clicli.player(31), monster_type, spawn_point, 0)

        -- 命令怪物攻击移动到目标位置
        monster:attack_move(attack_point)

        alive_count = alive_count + 1

        monster:event('单位-死亡', function(_, data)
            alive_count = alive_count - 1
        end)
    end)
end

---@return boolean 有无下波怪
function M.has_next()
    return wave_index < total_batch_count
end

function M.get_alive_count()
    return alive_count
end

function M.stop()
    stopped = true
end

return M
