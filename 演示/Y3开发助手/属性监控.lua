--Need to install CliCli Developer Assistant version >= 1.11.1, attach debugger and enable breakpoint 'Caught Errors By Lua' in debugger interface

local unit = clicli.unit.get_by_res_id(1)

--A special exception breakpoint is raised when the unit's maximum life reaches exactly 1000
clicli.develop.helper.createAttrWatcher(unit, '最大生命', 1000)

--Raises a special exception breakpoint when a unit's health drops below half of its maximum life
clicli.develop.helper.createAttrWatcher(unit, '生命', '<= `最大生命` / 2')

--You can also add these monitors dynamically in the CliCli Development Assistant
--1. Select the unit to monitor in the game
--2. Under Selected Units in the Dashboard, click the properties you want to monitor
--3. Enter a breakpoint expression and press Enter to confirm
