--The VSCode extension CliCli Development Assistant, version >= 1.8.0, needs to be installed

--The interface name of the created node is long, so rename it here:
local Node = clicli.develop.helper.createTreeNode

--Create your view on the tree view of the CliCli development Assistant
clicli.develop.helper.createTreeView('作弊功能', Node('作弊功能', {
    --可用图标请参阅 https://code.visualstudio.com/api/references/icons-in-labels#icon-listing
    icon = 'call-incoming',
    --定义子节点
    childs = {
        Node('回满状态', {
            onClick = function (node)
                --点击事件是本地的，如果你需要联机测试，
                --请使用 `clicli.sync` 库进行同步
                clicli.player.with_local(function (local_player)
                    local unit = local_player:get_local_selecting_unit()
                    if unit then
                        unit:set_attr('生命', unit:get_attr("最大生命"))
                        unit:set_attr('魔法', unit:get_attr("最大魔法"))
                    end
                end)
            end
        }),
        Node('杀死单位', {
            onClick = function (node)
                clicli.player.with_local(function (local_player)
                    local unit = local_player:get_local_selecting_unit()
                    if unit then
                        unit:kill_by(unit)
                    end
                end)
            end
        }),
        --一些比较复杂的功能可以封装成函数，
        --但作为演示我就直接写在这里了
        (function ()
            local node = Node('当前选中的单位', {
                description = '无',
            })

            node:bindGC(clicli.ltimer.loop(0.2, function ()
                clicli.player.with_local(function (local_player)
                    local unit = local_player:get_local_selecting_unit()
                    if unit then
                        node.description = tostring(unit)
                    else
                        node.description = '无'
                    end
                end)
            end))

            return node
        end)(),
    }
}))

--You must have noticed that custom views already have a default Dashboard view.
--The source code can be found in 'clicli\develop\helper\explorer.lua'.
