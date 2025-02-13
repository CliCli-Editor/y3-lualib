Class   = require 'clicli.tools.class'.declare
New     = require 'clicli.tools.class'.new
Extends = require 'clicli.tools.class'.extends
IsValid = require 'clicli.tools.class'.isValid
Type    = require 'clicli.tools.class'.type
Delete  = require 'clicli.tools.class'.delete

---@class Log
log = {
    error = print,
}

---@class CliCli
clicli = {}
clicli.util    = require 'clicli.tools.utility'
clicli.reload  = require 'clicli.tools.reload'
clicli.linked_table = require 'clicli.tools.linked-table'

require 'clicli.util.event'
require 'clicli.util.event_manager'
require 'clicli.util.custom_event'
clicli.trigger = require 'clicli.util.trigger'

require 'clicli.unittest.eventtest'
require 'clicli.unittest.eventperform'
require 'clicli.unittest.ltimer'

print('测试完成！')
