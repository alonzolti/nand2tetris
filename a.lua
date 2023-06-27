a = {}
b = {}
function a:new()
    local B = {}
    setmetatable(B, a)
    self.__index = self
    return B
end
function a:foo()
    print("hello A")
end

function b:new()
    local A = {}
    setmetatable(A,b)
    self.__index = self
    return A
end

function b:foo()
    print("hello B")
end
function c(d)
    d:foo()
end

local a1 = a:new()
local b1 = b:new()


c(b1)