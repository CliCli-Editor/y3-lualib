--Try swapping comments on the next 2 lines before reloading!
print('文件第一次被加载')
--print(' File is loaded a second time ')

clicli.game:event('键盘-按下', clicli.const.KeyboardKey['SPACE'], function (trg, data)
    -- 重载前交换下面2行的注释试试！
    print('第一种敲空格')
    --print('第二种敲空格')
end)

clicli.timer.loop(1, function (timer, count)
    -- 重载前交换下面2行的注释试试！
    print('第一种计时器到期')
    --print('第二种计时器到期')
end)
