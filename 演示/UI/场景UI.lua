--Suppose you have a UI called 'Blood Bar' in the scene UI

clicli.game:event('单位-创建', function (trg, data)
    --创建任意单位后，给这个单位绑定一个场景UI
    local scene_ui = clicli.scene_ui.create_scene_ui_at_player_unit_socket('血条', clicli.player(1), data.unit, 'head')
    --当单位被移除后，移除这个场景UI
    data.unit:bindGC(scene_ui)
end)
