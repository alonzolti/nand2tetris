require "VMconstant"

VMTokenizer = {lines,tokens,curCommand,curToken}

function VMTokenizer:new(file)
    local t = {}
    setmetatable(t,VMTokenizer)
    local rFile = io.open(file,'r')
    t.lines = rFile:read('*a')
    t:tokenize(self.lines:split('\n'))
    t.curCommand = {}
    t.curToken = {ERROR,0}
    return t
end


function VMTokenizer:hasMoreCommands()
    return self.tokens[1]~=nil
end

function VMTokenizer:nextCommand()
    self.curCommand = self.tokens:remove(1)
    self:nextToken()
    return self.curCommand
end

function VMTokenizer:hasNextToken()
    return self.curCommand[1] ~=nil
end

function VMTokenizer:nextToken()
    if self:hasMoreCommands() then
        self.curToken = self.curCommand.remove(1)
    else
        self.curToken = {ERROR,0}
    end
    return self.curToken
end

function VMTokenizer:peekToken()
    if self:hasNextToken() then
        return self.curCommand[1]
    else
        return {ERROR,0}
    end
end

function VMTokenizer:tokenize(lines)
    for line in lines do
        self:tokenizeLine(line)
    end
end

function VMTokenizer:tokenizeLine(line)
    for word in string.gmatch(self:removeComment(line),"%S+")do
        table.insert(self.tokens,self:token(word))
    end
end

function VMTokenizer:removeComments(line)
    return line:gsub('//.*','')
end

function VMTokenizer:token(word)
    if self:isNum(word) then
        return {NUM,word}
    elseif self:isId(word) then
        return {ID,word}
    else
        return {ERROR,word}
    end
end

function VMTokenizer:isNum(word)
    return string.match(word, "%d+")
end

function VMTokenizer:isId(word)
    return string.match(word, "[A-Za-z_][A-Za-z0-9_]*")
end

