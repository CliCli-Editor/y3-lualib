--Audio
---@class Sound
---@overload fun(py_sound: py.SoundEntity):self
local M = Class 'Sound'

---@param py_sound py.SoundEntity
function M:__init(py_sound)
    self.handle = py_sound
end

---@param py_sound py.SoundEntity
---@return Sound
function M.get_by_handle(py_sound)
    local sound = New 'Sound' (py_sound)
    return sound
end

---@class Sound.PlayOptions
---@field loop? boolean # Cyclic or not
---@field fade_in? number # Involution time
---@field fade_out? number # Fade out time

---播放声音
---@param player Player 玩家
---@param sound py.AudioKey 声音
---@param options Sound.PlayOptions? # Play option
---@return Sound?
function M.play(player, sound, options)
    local py_sound = GameAPI.play_sound_for_player(
        player.handle,
        sound,
        options and options.loop or false,
        options and options.fade_in or 0.0,
        options and options.fade_out or 0.0
    )
    if not py_sound then
        return nil
    end
    return M.get_by_handle(py_sound)
end

---@class Sound.Play3DOptions: Sound.PlayOptions
---@field height? number # Altitude
---@field ensure? boolean # Ensure to play

---播放3D声音
---@param player Player 玩家
---@param sound py.AudioKey 声音
---@param point Point 目标点
---@param options Sound.Play3DOptions? # Play option
---@return Sound?
function M.play_3d(player, sound, point, options)
    local py_sound = GameAPI.play_3d_sound_for_player(
        player.handle,
        sound,
        -- TODO 见问题2
        ---@diagnostic disable-next-line: param-type-mismatch
        point.handle,
        options and options.height or 0.0,
        options and options.fade_in or 0.0,
        options and options.fade_out or 0.0,
        options and options.ensure or false,
        options and options.loop or false
    )
    if not py_sound then
        return nil
    end
    return M.get_by_handle(py_sound)
end

---@class Sound.PlayUnitOptions: Sound.PlayOptions
---@field ensure? boolean # Ensure to play
---@field offset_x? number # X-axis migration
---@field offset_y? number # Y-axis migration
---@field offset_z? number # Z-axis migration

---跟随单位播放声音
---@param player Player 玩家
---@param sound py.AudioKey 声音
---@param unit Unit 跟随的单位
---@param options Sound.PlayUnitOptions? # Play option
---@return Sound?
function M.play_with_object(player, sound, unit, options)
    local py_sound = GameAPI.follow_object_play_3d_sound_for_player(
        player.handle,
        sound,
        unit.handle,
        options and options.fade_in or 0.0,
        options and options.fade_out or 0.0,
        options and options.ensure or false,
        options and options.loop or false,
        options and options.offset_x or 0.0,
        options and options.offset_y or 0.0,
        options and options.offset_z or 0.0
    )
    if not py_sound then
        return nil
    end
    return M.get_by_handle(py_sound)
end

---停止播放声音
---@param player Player 玩家
---@param is_immediately? boolean 是否立即停止
function M:stop(player, is_immediately)
    GameAPI.stop_sound(player.handle, self.handle, not is_immediately or false)
end

--Set volume
---@param player Player 玩家
---@param volume integer 音量(0-100)
function M:set_volume(player, volume)
    GameAPI.set_sound_volume(player.handle, self.handle, volume)
end

return M
