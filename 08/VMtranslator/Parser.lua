
require "VMconstant"


Parser = { commands = {}, curCommand = {}, cmdType = C_ERROR, arg1 = '', arg2 = 0 }

function Parser:new(file)
    local parser = {}
    setmetatable(parser, Parser)
    self.__index = self
    for line in io.open(file, 'r'):lines() do
        table.insert(parser.commands, line)
    end
    return parser
end

function Parser:initCmdInfo()
    self.cmdType = C_ERROR
    self.arg1 = ''
    self.arg2 = 0
end

function Parser:hasMoreCommands() return self.commands[1] ~= nil end

function Parser:nextCommand()
    --remove comments and split into words
    for word in string.gmatch(string.gsub(self.commands[1], '//.*', ''), "%S+") do
        table.insert(self.curCommand, word)
    end
    table.remove(self.commands, 1)
    --if the line was a comment
    if self.curCommand[1] == nil then
        self:nextCommand()
    end
end

function Parser:advance()
    self:initCmdInfo()
    self:nextCommand()
    local val = self:nextWord()
    self.cmdType = commandType[val]
    if self.cmdType == C_ARITHMETIC or self.cmdType == C_RETURN then
        self.arg1 = val
    else
        self.arg1 = self:nextWord()
    end
    if self.cmdType == C_PUSH or self.cmdType == C_POP or self.cmdType == C_FUNCTION or self.cmdType == C_CALL then
        self.arg2 = self:nextWord()
    end
end

function Parser:hasNextWord() return self.curCommand[1] ~= nil end

function Parser:nextWord()
    if self:hasNextWord() then
        local word = self.curCommand[1]
        table.remove(self.curCommand, 1)
        return word
    else
        error("vm files aren't correct")
    end
end

function Parser:commandType() return self.cmdType end

function Parser:argF() return self.arg1 end

function Parser:argS() return self.arg2 end
