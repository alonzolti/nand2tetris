require "VMconstant"

VMTokenizer = {lines = nil,
tokens = {},--list of all tokens
curCommand = {},--list of tokens for current command
curToken = {ERROR, 0}}--current token of current command

function VMTokenizer:new(file)
    local t = {}
    setmetatable(t, VMTokenizer)
    self.__index = self
    local rFile = io.open(file, 'r')
    t.lines = rFile:read('*a')
    t:tokenize(t.lines:gmatch("[^\r\n]+"))
    return t
end

function VMTokenizer:hasMoreCommands() return self.tokens[1] ~= nil end

function VMTokenizer:nextCommand()
    self.curCommand = self.tokens[1]
    table.remove(self.tokens,1)
    self:nextToken()
    return self.curCommand
end

function VMTokenizer:hasNextToken() return self.curCommand[1] ~= nil end

function VMTokenizer:nextToken()
    if self:hasNextToken() then
        self.curToken = self.curCommand[1]
        table.remove(self.curCommand,1)
    else
        self.curToken = {ERROR, 0}
    end
    return self.curToken
end

function VMTokenizer:peekToken()
    if self:hasNextToken() then
        return self.curCommand[1]
    else
        return {ERROR, 0}
    end
end

function VMTokenizer:tokenize(lines)
    for line in lines do self:tokenizeLine(line) end
end

function VMTokenizer:tokenizeLine(line)
    local b = {} --t = {{},{},{}}
    for word in string.gmatch(self:removeComments(line), "%S+") do
        table.insert(b, self:token(word))
    end
    if b[1]~= nil then
        table.insert(self.tokens,b)
    end
end

function VMTokenizer:removeComments(line) return string.gsub(line,'//.*', '')end

function VMTokenizer:token(word)
    if self:isNum(word) then
        return {NUM, word}
    elseif self:isId(word) then
        return {ID, word}
    else
        return {ERROR, word}
    end
end

function VMTokenizer:isNum(word) return string.match(word, "%d+") end

function VMTokenizer:isId(word)
    return string.match(word, "[A-Za-z_][A-Za-z0-9_]*")
end

