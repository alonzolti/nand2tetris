require "VMTokenizer"
require "VMconstant"


Parser = { tokenizer = nil, lines = {}, cmdType = C_ERROR, arg1 = '', arg2 = 0 }

function Parser:new(file)
    local parser = {}
    setmetatable(parser, Parser)
    self.__index = self
    parser.lines = io.open(file,'r'):lines()
    
    parser.tokenizer = VMTokenizer:new(file)

    return parser
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

    self.cmdType = commandType[val]
    if tok ~= ID then
        error()
    elseif self.cmdType == C_ARITHMETIC or self.cmdType == C_RETURN then
        self.arg1 = val
    else
        self.arg1 = self.tokenizer:nextToken()[2]
    end
    if self.cmdType == C_PUSH or self.cmdType == C_POP or self.cmdType == C_FUNCTION or self.cmdType == C_CALL then
        self.arg2 = self.tokenizer:nextToken()[2]
    end
end

function Parser:commandType() return self.cmdType end

function Parser:argF() return self.arg1 end

function Parser:argS() return self.arg2 end
