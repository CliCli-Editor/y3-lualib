local helper = require 'clicli.develop.helper.helper'

---输入框的可选项，完全照抄的 VSCode 的接口
---@class Develop.Helper.InputBox.Optional
---@field title? string # title
---@field value? string # Initial value
---@field valueSelection? [integer, integer] # Initially selected text range (cursor position, 0 before first character)
---@field prompt? string # Tips
---@field placeHolder? string # placeholder
---@field password? boolean # Password or not box
---@field ignoreFocusOut? boolean # Whether to close when you lose focus
---@field validateInput? fun(value: string): string | nil # An error message is returned indicating that the input is invalid

---@class Develop.Helper.InputBox: Develop.Helper.InputBox.Optional
---@overload fun(optional?: Develop.Helper.InputBox.Optional): Develop.Helper.InputBox
local M = Class 'Develop.Helper.InputBox'

---@private
M.maxID = 0

---@private
---@type table<integer, Develop.Helper.InputBox>
M.inputBoxMap = {}

---@param optional? Develop.Helper.InputBox.Optional
function M:__init(optional)
    M.maxID = M.maxID + 1
    self.id = M.maxID

    if optional then
        for k, v in pairs(optional) do
            self[k] = v
        end
    end
end

function M:__del()
    M.inputBoxMap[self.id] = nil
end

---删除输入框
function M:remove()
    Delete(self)
end

---显示输入框
---@param callback fun(value?: string) # Input the callback function after completion. If the user cancels the input, 'value' is nil.
function M:show(callback)
    M.inputBoxMap[self.id] = self
    helper.request('showInputBox', {
        id = self.id,
        title = self.title,
        value = self.value,
        valueSelection = self.valueSelection,
        prompt = self.prompt,
        placeHolder = self.placeHolder,
        password = self.password,
        ignoreFocusOut = self.ignoreFocusOut,
        hasValidateInput = type(self.validateInput) == 'function',
    }, function (data)
        self:remove()
        callback(data)
    end)
end

helper.registerMethod('inputBoxValidate', function (params)
    local inputBox = M.inputBoxMap[params.id]
    if not inputBox then
        return nil
    end
    return inputBox.validateInput(params.input)
end)

return M
