---@meta _

---@class XDouble
---@operator unm:  XDouble
---@operator add:  XDouble
---@operator sub:  XDouble
---@operator mul:  XDouble
---@operator div:  XDouble
---@operator mod:  XDouble
---@operator pow:  XDouble
---@operator idiv: XDouble
local M = {}

---@param num clicli.Number | string
---@return XDouble
function xdouble(num) end

---@return number
function M:float() end

--round-up
---@return integer
function M:int() end

--Absolute value
---@return XDouble
function M:abs() end

--Inverse cosine
---@return XDouble
function M:acos() end

--arcsine
---@return XDouble
function M:asin() end

--arctangent
---@return XDouble
function M:atan() end

--Round up
---@return XDouble
function M:ceil() end

--cosine
---@return XDouble
function M:cos() end

--Natural logarithm
---@return XDouble
function M:exp() end

--Round down
---@return XDouble
function M:floor() end

--Take the logarithm
---@return XDouble
function M:log() end

--Round it up
---@return XDouble
function M:round() end

--sine
---@return XDouble
function M:sin() end

--Root of a root
---@return XDouble
function M:sqrt() end

--tangent
---@return XDouble
function M:tan() end
