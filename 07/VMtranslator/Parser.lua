require "VMTokenizer"
require "VMconstant"

Parser = {tokenizer, cmdType, arg1, arg2}

function Parser:new(file)
    t = {}
    setmetatable(t, Parser)
    self.tokenizer = VMTokenizer:new(file)
    self:initCmdInfo()
end

function Parser:initCmdInfo()
    self.cmdType = C_ERROR
    self.arg1 = ''
    self.arg2 = 0
end

function Parser:hasMoreCommands() return self.tokenizer:hasMoreCommands() end

function Parser:advacne()
    self:initCmdInfo()
    self.tokenizer:nextCommand()
    local tok = self.tokenizer.curToken[1]
    local val = self.tokenizer.curToken[2]
    if tok ~= ID then
        error()
    elseif contain(val, nullary) then
        self:nullaryCommand(val)
    elseif contain(val, unary) then
        self:unaryCommand(val)
    elseif contain(val, binary) then
        self:binaryCommand(val)
    end
end

function contain(val, t)
    for k, v in t do if v == val then return true end end
    return false
end

function Parser:commandType() return self.cmdType end

function Parser:arg1() return self.arg1 end

function Parser:arg2() return self.arg2 end

function Parser:setCmdType(id) self.cmdType = commandType[id] end

function Parser:nullaryCommand(id)
    self:setCmdType(id)
    if commandType[id] == C_ARITHMETIC then self.arg1 = id end
end

function Parser:unaryCommand(id)
    self:nullaryCommand(id)
    local val = self.tokenizer:nextToken()[2]
    self.arg1 = val
end

function Parser:binaryCommand(id)
    self:unaryCommand(id)
    local val = self.tokenizer:nextToken()[2]
    self.arg2 = val
end

