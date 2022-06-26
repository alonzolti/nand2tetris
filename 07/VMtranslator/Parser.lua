require "VMTokenizer"
require "VMconstant"

Parser = {tokenizer = nil, cmdType = C_ERROR, arg1 = '', arg2 = 0}

function Parser:new(file)
    local t = {}
    setmetatable(t, Parser)
    self.__index = self
    t.tokenizer = VMTokenizer:new(file)
    return t
end

function Parser:initCmdInfo()
    self.cmdType = C_ERROR
    self.arg1 = ''
    self.arg2 = 0
end

function Parser:hasMoreCommands() return self.tokenizer:hasMoreCommands() end

function Parser:advance()
    self:initCmdInfo()
    self.tokenizer:nextCommand()
    local tok = self.tokenizer.curToken[1]
    local val = self.tokenizer.curToken[2]
    if tok ~= ID then
        error()
    elseif commandType[val] == C_ARITHMETIC then
        self.cmdType = C_ARITHMETIC
        self.arg1 = val
        
    elseif commandType[val] == C_RETURN then
        self.cmdType = C_RETURN
        self.arg1 = val
    else
        self.arg1 = self.tokenizer:nextToken()[2]

        if val == "push" then
            self.cmdType = C_PUSH
        elseif val == "pop" then
            self.cmdType = C_POP
        elseif val == "label" then
            self.cmdType = C_LABEL
        elseif val == "if" then
            self.cmdType = C_IF
        elseif val == "goto" then
            self.cmdType = C_GOTO
        elseif val == "function" then
            self.cmdType = C_FUNCTION
        elseif val == "call" then
            self.cmdType = C_CALL
        end
    end
    if self.cmdType == C_PUSH or self.cmdType == C_POP or self.cmdType == C_FUNCTION or self.cmdType == C_CALL then
        self.arg2 = self.tokenizer:nextToken()[2]
    end
end

function Parser:commandType() return self.cmdType end

function Parser:argF() return self.arg1 end

function Parser:argS() return self.arg2 end

function Parser:setCmdType(id) self.cmdType = commandType[id] end