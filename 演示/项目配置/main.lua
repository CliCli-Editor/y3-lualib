--This file will run automatically when the game starts

--In development mode, print logs into the game
if clicli.game.is_debug_mode() then
    clicli.config.log.toGame = true
    clicli.config.log.level  = 'debug'
else
    clicli.config.log.toGame = false
    clicli.config.log.level  = 'info'
end

clicli.game:event('游戏-初始化', function (trg, data)
    print('Hello, CliCli!')
end)

clicli.timer.loop(5, function (timer, count)
    print('每5秒显示一次文本，这是第' .. tostring(count) .. '次')
end)

clicli.game:event('键盘-按下', 'SPACE', function ()
    print('你按下了空格键！')
end)

--The code in this file can be hot overloaded
include '可重载的代码'
