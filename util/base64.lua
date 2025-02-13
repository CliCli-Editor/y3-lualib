---@diagnostic disable-next-line: undefined-global
local y3_crypto = y3_crypto

--base64 encoding and decoding
---@class BASE64
local M = {}

--Encodes the string into base64
---@param str string
---@return string
function M.encode(str)
    return y3_crypto.base64_encode(str, #str)
end

--Decode base64 as a string
---@param base64 string
---@return string
function M.decode(base64)
    local res = y3_crypto.base64_decode(base64)
    return res
end

return M
