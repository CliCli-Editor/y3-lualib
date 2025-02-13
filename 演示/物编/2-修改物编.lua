local M = clicli.object.unit[134274912] -- 关羽

M.data.name = '这是修改过的名字'

clicli.game:event('键盘-按下', clicli.const.KeyboardKey['SPACE'], function ()
    clicli.player(1):create_unit(134274912)
end)
