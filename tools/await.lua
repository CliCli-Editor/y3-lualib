---@class Await
local M = {}

---@type fun(traceback: string)?
local errorHandler

---@type fun(time: number, callback: fun())?
local waker

local function presume(co, ...)
    local suc, err = coroutine.resume(co, ...)
    if not suc and errorHandler then
        errorHandler(debug.traceback(co, err))
    end
end

---@class Await.API
local API = {}

--The current coroutine sleeps for a while
---@async
---@param time number
function API.sleep(time)
    if not waker then
        error('需要先试用 setSleepWaker 设置唤醒器')
    end
    if not coroutine.isyieldable() then
        if errorHandler then
            errorHandler(debug.traceback('当前协程无法让出！'))
        end
        return
    end
    local co = coroutine.running()
    waker(time, function ()
        if coroutine.status(co) ~= 'suspended' then
            return
        end
        presume(co)
    end)
    coroutine.yield()
end

--Current coroutine relinquishes
---@async
---@param callback fun(resume: fun(...)) # The current coroutine is relinquished until resume is called. The argument passed by calling resume will be the return value of the current coroutine.
---@return ...
function API.yield(callback)
    local co = coroutine.running()
    local resolved, yielded, fastResults
    local function resume(...)
        if resolved then
            return
        end
        resolved = true
        if yielded then
            if coroutine.status(co) ~= 'suspended' then
                return
            end
            presume(co, ...)
        else
            fastResults = table.pack(...)
        end
    end
    callback(resume)
    if resolved then
        return table.unpack(fastResults, 1, fastResults.n)
    else
        yielded = true
        return coroutine.yield()
    end
end

---@param callback async fun()
---@return thread
function API.call(callback)
    local co = coroutine.create(callback)
    presume(co)
    return co
end

--Set error handler
---@param handler fun(traceback: string) # When an error occurs, this function is called with the error stack as an argument
function API.setErrorHandler(handler)
    errorHandler = handler
end

--Set the wakeup
---@param f fun(time: number, callback: fun()) # You need to pass in a timer implementation function. When the time is up, the implementation function needs to call the callback.
function API.setSleepWaker(f)
    waker = f
end

return API
