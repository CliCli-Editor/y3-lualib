local M = {}

require 'clicli.tools.synthesis'
local maker = New 'Synthesis'()

---@type table<string, py.ItemKey> # Item configuration, which maps the item name to its corresponding key, e.g. {item1 = 10001}
local item_config = {}

---输入物品名返回对应的key
---@param name string # Item Name
---@return py.ItemKey? # Corresponding key
function M.get_item_key_by_name(name)
    -- 判断是否在配置中
    if item_config[name] then
        return item_config[name]
    else
        return nil
    end
end

--Initialize item configuration
function M.init_item_config(config)
    item_config = config
end

---注册合成配方
---@param result any # Synthetic target' target'
---@param ingredients any[] # Synthetic materials {'material1', 'material2', 'material3'}
function M.register(result, ingredients)
    maker:register(result, ingredients)
end

--After picking up the item, determine whether it can be synthesized
function M.pick_synthesis_check()
    clicli.game:event('物品-获得', function (trg, data)
        -- 存储当前单位全部的物品名
        local item_names = {}
        for i, v in ipairs(data.unit:get_all_items():pick()) do
            table.insert(item_names, v:get_name())
        end

        -- 获取合成结果
        local res = maker:check(item_names)

        -- 如果可以合成
        if res then
            -- 将合成目标所需的素材从该单位身上移除
            for _, v in ipairs(res.lost) do
                local item_key = M.get_item_key_by_name(v)
                if item_key then
                    data.unit:remove_item(item_key, 1)
                end
            end

            -- 给该单位增添合成后的目标物品
            local item_key = M.get_item_key_by_name(res.get)
            if item_key then
                data.unit:add_item(item_key)
            end
        end
    end)
end

---返回maker对象
---@return Synthesis # Composite processing object
function M.get_maker()
    return maker
end


return M
