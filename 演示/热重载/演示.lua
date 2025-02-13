--Files loaded with include are marked as overloadable
include 'clicli.example.热重载.重载的脚本'

--Send the chat message '.rd 'to reload the above file

--You can further specify through configuration that only partial files are overloaded.
--If this is not configured, all reloadable files (files loaded with 'include') are overridden by default.
clicli.reload.setDefaultOptional {
    -- 通过列表指定文件
    list = {
        'clicli.example.热重载.重载的脚本',
    },
    -- 不在上述列表中的文件会尝试调用此函数，如果返回true表示需要重载，否则不重载
    filter = function (name, reload)
        if clicli.util.stringStartWith(name, 'clicli.example.热重载.') then
            return true
        else
            return false
        end
    end,
}
