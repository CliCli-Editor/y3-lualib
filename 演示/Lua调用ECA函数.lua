--需要安装“Y3开发助手”插件（版本>=1.1.0）

---@diagnostic disable: param-type-mismatch, redundant-parameter

--假设地图中注册了自定义事件：“加法”，参数为2个整数，
--则可以通过以下代码直接调用该自定义事件

y3.eca.call('加法', 100, 200)
