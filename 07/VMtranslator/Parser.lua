require "07.VMtranslator.VMconstant"

Parser = {lines,tokens,curCommand,curToken}

function Parser:new(file)
    local t = {}
    setmetatable(t,Parser)
    local rFile = io.open(file,'r')
    t.lines = rFile:read('*a')
    t:tokenize(self.lines:split('\n'))
    t.curCommand = {}
    t.curToken = {ERROR,0}
    return t
end


function Parser:hasMoreCommands()
    return self.tokens[1]~=nil
end

function Parser:nextCommand()
    self.curCommand = self.tokens:remove(1)
    self:nextToken()
    return self.curCommand
end

function Parser:hasNextToken()
    return self.curCommand[1] ~=nil
end

function Parser:nextToken()
    if self:hasMoreCommands() then
        self.curToken = self.curCommand.remove(1)
    else
        self.curToken = {ERROR,0}
    end
    return self.curToken
end

function Parser:peekToken()
    if self:hasNextToken() then
        return self.curCommand[1]
    else
        return {ERROR,0}
    end
end

function Parser:tokenize(lines)
    for line in lines do
        self:tokenizeLine(line)
    end
end

function Parser:tokenizeLine(line)
    for word in string.gmatch(self:removeComment(line),"%S+")do
        table.insert(self.tokens,self:token(word))
    end
end

function Parser:removeComments(line)
    return line:gsub('//.*','')
end

function Parser:token(word)
    if self:isNum(word) then
        return {NUM,word}
    elseif self:isId(word) then
        return {ID,word}
    else
        return {ERROR,word}
    end
end

function Parser:isNum(word)
    return string.match(word, "%d+")
end

function Parser:isId(word)
    return string.match(word, "[A-Za-z_][A-Za-z0-9_]*")
end

