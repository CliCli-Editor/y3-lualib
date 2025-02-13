---@diagnostic disable-next-line: undefined-global
local y3_crypto = y3_crypto

--aes encryption and decryption
---@class AES
local M = {}

--Cryptographic string
---@param key string # The length must be 16/24/32
---@param iv string # The length must be 16
---@param source_text string # Text to encrypt
---@return string
function M.encrypt(key, iv, source_text)
    if #key ~= 16 and #key ~= 24 and #key ~= 32 then
        error('key长度必须是16/24/32')
    end
    if #iv ~= 16 then
        error('iv长度必须是16')
    end
    local ret, err = y3_crypto.aes_encrypt(key, iv, source_text, #source_text)
    if not ret then
        error(err)
    end
    return ret
end

--Decryption string
---@param key string # The length must be 16/24/32
---@param iv string # The length must be 16
---@param crypted_text string # Text to decrypt
---@return string
function M.decrypt(key, iv, crypted_text)
    if #key ~= 16 and #key ~= 24 and #key ~= 32 then
        error('key长度必须是16/24/32')
    end
    if #iv ~= 16 then
        error('iv长度必须是16')
    end
    local ret, err = y3_crypto.aes_decrypt(key, iv, crypted_text, #crypted_text)
    if not ret then
        error(err)
    end
    return ret
end

return M
