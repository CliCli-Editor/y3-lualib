local battle_wave = require 'clicli.演示.demo.防守图.刷兵'
local game_result = require 'clicli.演示.demo.防守图.游戏结果'

clicli.ltimer.wait(0.5, function ()
    -- 为玩家1创建主控英雄并选中
    local hero = clicli.player(1):create_unit(134274912, clicli.point.create(0, 0, 0), 180.0)
    clicli.player(1):select_unit(hero)

    -- 让英雄强一点
    hero:set_level(10)
    hero:add_attr('物理攻击', 70)
    hero:add_attr('法术攻击', 150)
    hero:add_attr('攻击速度', 200)
    hero:add_attr('物理吸血', 20)
    hero:add_attr('暴击率', 20)
    hero:add_attr('技能吸血', 200)
    hero:add_attr('魔法恢复', 10)
    hero:add_attr('冷却缩减', 50)

    -- 玩家英雄死亡，游戏失败
    hero:event('单位-死亡', function()
        game_result.lose()
        battle_wave.stop()
    end)
end)

--Wait 2 seconds to start brushing
clicli.ltimer.wait(2, function ()
    battle_wave.next_wave()
    -- 第一次出兵后，每15秒再出一次兵
    clicli.ltimer.loop(15, function ()
        battle_wave.next_wave()
    end)
end)

clicli.ltimer.loop(1, function(timer)
    -- 如果场上的怪超过30个，判定游戏失败
    if battle_wave.get_alive_count() >= 30 then
        game_result.lose()
        battle_wave.stop()
        timer:remove()
    end
    -- 如果场上没有怪了，也没有下一波怪了，判定游戏胜利
    if battle_wave.get_alive_count() == 0 and not battle_wave.has_next() then
        game_result.win()
        battle_wave.stop()
        timer:remove()
    end
end)
