---@alias Timer.OnTimer fun(timer: Timer,...)

---@alias Timer.Mode 'second' | 'frame'

--Synchronous timer
--
--All players must use the same timer, otherwise it will be out of sync
---@class Timer
---@field handle py.Timer
---@field desc string
---@field private on_timer Timer.OnTimer
---@field private include_name? string | false
---@field private mode Timer.Mode
---@overload fun(py_timer: py.Timer, on_timer: Timer.OnTimer, mode: Timer.Mode, desc: string): self
local M = Class 'Timer'

M.type = 'timer'

---@private
M.id_counter = clicli.util.counter()

---@private
M.all_timers = setmetatable({}, clicli.util.MODE_V)

---@param py_timer py.Timer
---@param on_timer Timer.OnTimer
---@param mode Timer.Mode
---@param desc string
---@return self
function M:__init(py_timer, on_timer, mode, desc)
    self.handle = py_timer
    self.on_timer = on_timer
    self.id = self.id_counter()
    self.mode = mode
    self.desc = desc
    M.all_timers[self.id] = self
    return self
end

function M:__del()
    Blackbox.delete_timer(self.handle)
end

---@param py_timer py.Timer
---@param on_timer Timer.OnTimer
---@return Timer
function M.get_by_handle(py_timer, on_timer)
    local timer = New 'Timer' (py_timer, on_timer)
    return timer
end


clicli.py_converter.register_py_to_lua('py.Timer', M.get_by_handle)
clicli.py_converter.register_lua_to_py('py.Timer', function (lua_value)
    return lua_value.handle
end)

---@param func function
---@return string
local function make_timer_reason(func)
    local info = debug.getinfo(func, 'Sl')
    local sourceStr
    if info.currentline == -1 then
        sourceStr = '?'
    else
        sourceStr = ('%s:%d'):format(info.source, info.currentline)
    end
    return sourceStr
end

--Wait for the execution time
---@param timeout number
---@param on_timer fun(timer: Timer)
---@param desc? string # Description
---@return Timer
function M.wait(timeout, on_timer, desc)
    desc = desc or make_timer_reason(on_timer)
    ---@type Timer
    local timer
    local py_timer = Blackbox.add_timer_by_time(timeout, 0, false, function(current_timer)
        if not timer then
            timer = New 'Timer' (current_timer, on_timer, 'second', desc)
        end
        timer:execute()
        timer:remove()
    end, desc)
    timer = timer or New 'Timer' (py_timer, on_timer, 'second', desc)
    return timer
end

--Wait for a certain number of frames before executing
--> Please use 'clicli.ltimer.wait_frame' instead
---@param frame integer
---@param on_timer fun(timer: Timer)
---@param desc? string # Description
---@return Timer
function M.wait_frame(frame, on_timer, desc)
    desc = desc or make_timer_reason(on_timer)
    ---@type Timer
    local timer
    local py_timer = Blackbox.add_timer_by_frame(frame, 0, function (current_id)
        timer:execute()
        timer:remove()
    end, desc)
    timer = New 'Timer' (py_timer, on_timer, 'frame', desc)
    return timer
end

--Loop execution
---@param timeout number
---@param on_timer fun(timer: Timer, count: integer)
---@param desc? string # Description
---@param immediate? boolean # Whether to execute it immediately
---@return Timer
function M.loop(timeout, on_timer, desc, immediate)
    desc = desc or make_timer_reason(on_timer)
    immediate = immediate or false
    local timer
    local count = 0
    local py_timer = Blackbox.add_timer_by_time(timeout, -1, immediate, function(current_id)
        if not timer then
            timer = New 'Timer' (current_id, on_timer, 'second', desc)
        end
        count = count + 1
        timer:execute(count)
    end, desc)
    timer = timer or New 'Timer' (py_timer, on_timer, 'second', desc)
    return timer
end

--Execute after a certain number of frames
--> Please use 'clicli.ltimer.loop_frame' instead
---@param frame integer
---@param on_timer fun(timer: Timer, count: integer)
---@param desc? string # Description
---@return Timer
function M.loop_frame(frame, on_timer, desc)
    desc = desc or make_timer_reason(on_timer)
    ---@type Timer
    local timer
    local count = 0
    local py_timer = Blackbox.add_timer_by_frame(frame, -1,  function (timer_id)
        count = count + 1
        timer:execute(count)
    end, desc)
    timer = New 'Timer' (py_timer, on_timer, 'frame', desc)
    return timer
end

--Loop execution, you can specify a maximum number of times
---@param timeout number
---@param times integer
---@param on_timer fun(timer: Timer, count: integer)
---@param desc? string # Description
---@param immediate? boolean # Whether to execute once immediately (count for maximum count)
---@return Timer
function M.count_loop(timeout, times, on_timer, desc, immediate)
    desc = desc or make_timer_reason(on_timer)
    immediate = immediate or false
    local timer
    local count = 0
    local py_timer = Blackbox.add_timer_by_time(timeout, times, immediate, function(current_id)
        if not timer then
            timer = New 'Timer' (current_id, on_timer, 'second', desc)
        end
        count = count + 1
        timer:execute(count)

        if count >= times then
            timer:remove()
        end
    end, desc)
    timer = timer or New 'Timer' (py_timer, on_timer, 'second', desc)
    return timer
end

--You can specify the maximum number of frames to be executed after a certain number of frames
--> Use 'clicli.ltimer.count_loop_frame' instead
---@param frame integer
---@param times integer
---@param on_timer fun(timer: Timer, count: integer)
---@param desc? string # Description
---@return Timer
function M.count_loop_frame(frame, times, on_timer, desc)
    desc = desc or make_timer_reason(on_timer)
    local timer
    local count = 0
    local py_timer = Blackbox.add_timer_by_frame(frame, times, function()
        count = count + 1
        timer:execute(count)
        if count >= times then
            timer:remove()
        end
    end, desc)
    timer = New 'Timer' (py_timer, on_timer, 'frame', desc)
    return timer
end

--Immediate execution
function M:execute(...)
    if self:is_removed() then
        return
    end
    xpcall(self.on_timer, log.error, self, ...)
end

--Remove timer
function M:remove()
    Delete(self)
end

function M:is_removed()
    return not IsValid(self)
end

--Pause timer
function M:pause()
    if self.mode == 'frame' then
        error('帧计时器不支持暂停，若有此需求请改用 `clicli.ltimer.xxx_frame`')
    end
    GameAPI.pause_timer(self.handle)
end

--Continue timer
function M:resume()
    GameAPI.resume_timer(self.handle)
end

--Whether it is running
function M:is_running()
    return GameAPI.is_timer_valid(self.handle)
end

---获取计时器经过的时间
---@return number time 计时器经过的时间
function M:get_elapsed_time()
    return clicli.helper.tonumber(GameAPI.get_timer_elapsed_time(self.handle)) or 0
end

---获取计时器初始计数
---@return integer count 初始计数
function M:get_init_count()
    return GameAPI.get_timer_init_count(self.handle)
end

---获取计时器剩余时间
---@return number time 计时器剩余时间
function M:get_remaining_time()
    return clicli.helper.tonumber(GameAPI.get_timer_remaining_time(self.handle)) or 0
end

---获取计时器剩余计数
---@return integer count 剩余计数
function M:get_remaining_count()
    return GameAPI.get_timer_remaining_count(self.handle)
end

---获取计时器设置的时间
---@return number time 设置的时间
function M:get_time_out_time()
    return clicli.helper.tonumber(GameAPI.get_timer_time_out_time(self.handle)) or 0
end

---@return string?
function M:get_include_name()
    if not self.include_name then
        self.include_name = clicli.reload.getIncludeName(self.on_timer) or false
    end
    return self.include_name or nil
end

--Iterate over all timers for debugging purposes only (it may be possible to iterate over an invalid one)
---@return fun():Timer?
function M.pairs()
    local timers = {}
    for _, timer in clicli.util.sortPairs(M.all_timers) do
        timers[#timers+1] = timer
    end
    local i = 0
    return function ()
        i = i + 1
        return timers[i]
    end
end

return M
