---@class Synthesis
---@field private recipes table<any, table<any, integer>> # Record the number of occurrences of the synthetic object and its corresponding synthetic material {'target1':{'material1':2, 'material2':4}}
---@field private material_map table<any, table<any, boolean>> # Record the object object that the composition material can synthesize {'material1':{'target1':true, 'target2':true}}
---@overload fun(): self
local M = Class 'Synthesis'

function M:__init()
    ---合成配方表
    ---@private
    self.recipes = {}
    ---合成素材字典
    ---@private
    self.material_map = {}
    return self
end

---注册合成配方
---@param result any # Synthetic target' target'
---@param ingredients any[] # Synthetic materials {'material1', 'material2', 'material3'}
function M:register(result, ingredients)
    self.recipes[result] = {}
    -- 记录合成素材出现的次数
    for i, v in ipairs(ingredients) do
        if self.recipes[result][v] then
            self.recipes[result][v] = self.recipes[result][v] + 1
        else
            self.recipes[result][v] = 1
        end

        -- 记录该合成素材可合成的目标
        if not self.material_map[v] then
            self.material_map[v] = {}
        end
        if not self.material_map[v][result] then
            self.material_map[v][result] = true
        end
    end
end

---根据物品获取其配方
---@param item any # item
---@return { parents: any[], children: any[] } # The synthetic material of this item {parents:{'parent1'}, children:{'child1', 'child2'}}
function M:get_recipes_by_item(item)
    local result = {
        parents = {},
        children = {}
    }

    -- 获取该物品的合成素材
    if self.recipes[item] then
        for material, cnt in pairs(self.recipes[item]) do
            for i = 1, cnt do
                table.insert(result.children, material)
            end
        end
    end

    -- 获取该物品可以合成的物品
    if self.material_map[item] then
        for target, _ in pairs(self.material_map[item]) do
            table.insert(result.parents, target)
        end
    end

    return result
end

---获得result表
---@param items_map table<any, integer> # Item count dictionary {'item1':3, 'item2':1}
---@param target any # Synthetic target
---@param cur_recipes table<any, table<any, integer>> # recipe
---@return { lost: any[], get: any } # lost material, resultant resultant {lost:{'material1', 'material2'}, get:'target1'}
local function get_result(items_map, target, cur_recipes)
    local result = {
        get = target,
        lost = {}
    }
    -- 在items字典中减去对应数量的合成素材
    for material, cnt in pairs(cur_recipes[target]) do
        items_map[material] = items_map[material] - cnt
        -- 同时在lost表中加入失去的合成素材
        for i = 1, cnt do
            table.insert(result.lost, material)
        end
    end
    return result
end

---判断物品栏物品是否能合成某个物品
---@param items_map table<any, integer> # Item count dictionary {'item1':3, 'item2':1}
---@param target any # Synthetic target
---@param cur_recipes table<any, table<any, integer>> # recipe
---@return boolean # Whether it can be synthesized
local function check_target_synthesis(items_map, target, cur_recipes)
    for material, cnt in pairs(cur_recipes[target]) do
        -- 如果物品列表中不存在该合成素材，或者小于该合成素材所需的个数则直接判断该目标不能合成
        if not items_map[material] or items_map[material] < cnt then
            return false
        end
    end
    return true
end

---传入当前物品栏物品，检查合成
---@param items any[]? # Inventory items {'material1', 'material2', 'material3'}
---@return { lost: any[], get: any } | nil # The result of the composition {lost:{'material1', 'material2'}, get:'target1'}
function M:check(items)
    if not items then
        return nil
    end

    -- 统计items中不同物品的出现次数并存储到该字典中
    local items_map = {}
    if items then
        for _, v in ipairs(items) do
            if items_map[v] then
                items_map[v] = items_map[v] + 1
            else
                items_map[v] = 1
            end
        end
    end

    -- 记录配方是否还需访问
    local is_recipe_visited = {}
    for item, cnt in pairs(items_map) do
        -- 选出当前素材可以合成的物品
        local targets = self.material_map[item]
        if targets then
            for target, _ in pairs(targets) do
                if not is_recipe_visited[target] then
                    -- 标记当前可合成物品已访问
                    is_recipe_visited[target] = true
                    -- 判断是否可以合成当前可合成物品
                    local can_synthesis = check_target_synthesis(items_map, target, self.recipes)
                    -- 如果可以合成则计算并返回result表
                    if can_synthesis then
                        return get_result(items_map, target, self.recipes)
                    end
                end
            end
        end
    end

    return nil
end

---递归函数，用来更新result表
---@param target any # target item 'target'
---@param items_map any[] # Item collection {'material1', 'material2'}
---@param cur_recipes table<any, table<any, integer>> # recipe
---@param result { needs: any[], lost: any[] } # {needs:{}, lost:{}}}
local function target_check_backtrack(target, items_map, cur_recipes, result)
    -- 遍历当前物品的合成素材
    for material, cnt in pairs(cur_recipes[target]) do
        local need_num = 0
        local cost_num = 0
        -- 计数需要素材数量和消耗的素材数量
        if not items_map[material] then
            need_num = cnt
            cost_num = 0
        elseif items_map[material] < cnt then
            need_num = cnt - items_map[material]
            cost_num = items_map[material]
        else
            need_num = 0
            cost_num = cnt
        end

        -- 更新lost表和items字典
        for i = 1, cost_num do
            table.insert(result.lost, material)
            items_map[material] = items_map[material] - 1
        end
        -- 判断该素材是否在配方表中
        if not cur_recipes[material] then
            -- 若不在配方表中说明其没子素材则直接加入needs表
            for i = 1, need_num do
                table.insert(result.needs, material)
            end
        else
            for i = 1, need_num do
                -- 若在配方表中说明还有子素材，进行递归更新result表
                target_check_backtrack(material, items_map, cur_recipes, result)
            end
        end
    end
end

---传入目标物品和已有物品，返回结果
---@param target any # target item 'target'
---@param items any[]? # Item collection {'material1', 'material2'}
---@return { needs: any[], lost: any[] } | nil # Materials needed to synthesize and existing materials that will be lost. {needs:{'material3'}, lost:{'material1', 'material2'}}
function M:target_check(target, items)
    local result = {
        needs = {},
        lost = {}
    }

    -- 如果目标物品不在配方表则直接返回
    if not self.recipes[target] then
        return nil
    end

    -- 统计items中不同物品的出现次数并存储到该字典中
    local items_map = {}
    if items then
        for _, v in ipairs(items) do
            if items_map[v] then
                items_map[v] = items_map[v] + 1
            else
                items_map[v] = 1
            end
        end
    end

    -- 更新resul表
    target_check_backtrack(target, items_map, self.recipes, result)
    return result
end

---返回配方表
---@return table<any, table<any, integer>> # recipe
function M:get_recipes()
    return self.recipes
end

---返回合成素材字典
---@return table<any, table<any, boolean>> # Composite material dictionary
function M:get_material_map()
    return self.material_map
end
