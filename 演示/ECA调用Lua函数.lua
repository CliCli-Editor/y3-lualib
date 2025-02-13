--Declares a new ECA function to get the unit owner
clicli.eca.def '获取单位所有者'
    -- 声明第一个参数的ECA类型
    : with_param('单位', 'Unit')
    -- 声明返回值的ECA类型
    : with_return('玩家', 'Player')
    ---@param unit Unit
    ---@return Player?
    : call(function (unit)
        -- unit 已经是Lua框架的Unit类型
        local p = unit:get_owner()
        -- 直接返回Lua框架的Player类型即可
        return p
    end)

--The ECA 'execute Lua code' is used in the editor to call the above functions
--Set variable player = Execute Lua code 'Bind[' Get unit owner '](args[1])', parameter list: unit
