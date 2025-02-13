local monster_wave = require 'clicli.演示.demo.练功房.刷怪'

clicli.ltimer.wait(0.5, function ()
    -- 给玩家1创建主控英雄并选中
    local hero = clicli.player(1):create_unit(134242543, clicli.point.create(0, 0, 0), 180.0)
    clicli.player(1):select_unit(hero)

    -- 设置英雄属性
    hero:set_level(10)
    hero:add_attr('物理攻击', 70)
    hero:add_attr('法术攻击', 150)
    hero:add_attr('攻击速度', 200)
    hero:add_attr('物理吸血', 20)
    hero:add_attr('暴击率', 80)
    hero:add_attr('技能吸血', 500)
    hero:add_attr('魔法恢复', 20)
    hero:add_attr('冷却缩减', 50)

    -- 创建练功房区域
    local circle_area = clicli.area.create_circle_area(clicli.point.create(-1000, -1000, 0), 800)

    -- 当英雄进入练功房时开始刷怪
    circle_area:event('区域-进入', function (trg, data)
        if data.unit:is_hero() then
            monster_wave.start()
        end
    end)

    -- 1.当英雄离开练功房5秒后删除区域内怪物
    -- 2.如果5秒内英雄折返则不删除
    circle_area:event('区域-离开', function (trg, data)
        if data.unit:is_hero() then
            monster_wave.delete(circle_area, 5)
        end
    end)
end)
