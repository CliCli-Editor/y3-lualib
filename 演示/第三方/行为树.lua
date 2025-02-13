--[[
    参考: https://github.com/meniku/NPBehave/tree/2.0-dev, 本示例为链接的标题`Example: An event-driven behavior tree`的示例
 ]]


require("clicli.third_party.NPBehave")
--This is a built-in context, and you can implement your own independent context according to the format
local GameContext = require("clicli.third_party.NPBehave.GameContext")
local ClassName = NPBehave.ClassName
--Declare the behavior tree in advance
---@type NPBehave.Root
local behaviorTree

--Construct tree
local tree = New(ClassName.Service)(0.5,
    function()
        local v = not behaviorTree.Blackboard:Get("foo")
        behaviorTree.Blackboard:Set("foo", v)
    end,
    New(ClassName.Selector)(
        New(ClassName.BlackboardCondition)("foo", NPBehave.Enum.Operator.IsEqual, true,
            NPBehave.Enum.Stops.ImmediateRestart,
            New(ClassName.Sequence)(
                New(ClassName.Action)({
                    action = function() print("foo") end
                }),
                New(ClassName.WaitUntilStopped)()
            )
        ),
        New(ClassName.Sequence)(
            New(ClassName.Action)({
                action = function()
                    print("bar")
                end
            }),
            New(ClassName.WaitUntilStopped)()
        )
    )
)
--Place the tree in Root
behaviorTree = New(ClassName.Root)(tree)
behaviorTree:Start()
---@type Timer
local timer
clicli.game:event("键盘-按下", clicli.const.KeyboardKey["NUM_4"], function(trg, data)
    local player = data.player
    timer        = clicli.timer.loop(0.5, function()
        -- 更新上下文时间, 树在在更新上下文时间时执行
        GameContext.Update(0.5)
    end)
end)


clicli.game:event("键盘-按下", clicli.const.KeyboardKey["NUM_5"], function(trg, data)
    local player = data.player
    -- timer:remove()
    -- 停止行为树, 上下文仍然更新时间, 但是行为树不再执行
    if behaviorTree ~= nil and behaviorTree.CurrentState == NPBehave.Enum.NodeState.Active then
        behaviorTree:CancelWithoutReturnResult()
    end
end)
