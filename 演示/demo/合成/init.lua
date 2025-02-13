local shop = require 'clicli.演示.demo.合成.商店合成'
local pick = require 'clicli.演示.demo.合成.拾取合成'

--To implement the store purchase interface, click the store button UI (or press the Z key) to open or close the store interface
include 'clicli.演示.demo.合成.商店界面'

--Set the player's gold attribute
clicli.player(1):set('gold', 2000)

--Store arrangement
local shop_item_config = {
    刑天斧      = 134257216,
    血翼魔刃    = 134268943,
    裂甲戟      = 134233952,
    圆月弯刀    = 134244701,
    碎牙        = 134280428,
    羽裂斧      = 201390088,
    刹那靴      = 134276637,
    疾风靴      = 134250168,
    蚀魔靴      = 134257230
}

--Initialize the store configuration
shop.init_item_config(shop_item_config)

--Register store item synthesis recipes
shop.register('刑天斧', {'血翼魔刃', '裂甲戟', '裂甲戟', '裂甲戟'})
shop.register('刹那靴', {'疾风靴', '蚀魔靴'})
shop.register('羽裂斧', {'刑天斧', '刑天斧', '刑天斧'})

--Store item initialization
shop.init_shop_item({'刑天斧', '血翼魔刃', '裂甲戟', '羽裂斧', '刹那靴', '疾风靴', '蚀魔靴'})

--Pick up item configuration
local pick_item_config = {
    天眼符      = 134245520,
    燧石        = 201390023,
    神力丹      = 201390001,
    神术丹      = 201390002,
    狼锋破      = 134253209
}

--Initialize the pick configuration
pick.init_item_config(pick_item_config)

--Register the pickup item synthesis recipe
pick.register('天眼符', {'神力丹', '神术丹'})
pick.register('神力丹', {'狼锋破', '狼锋破'})
pick.register('燧石', {'天眼符', '神力丹'})

--Monitor whether the item is synthesized when acquired
pick.pick_synthesis_check()
