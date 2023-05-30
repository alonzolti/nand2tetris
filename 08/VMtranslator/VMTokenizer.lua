require "VMconstant"

VMTokenizer = {
    tokens = {},            --list of all commands and 
    curCommand = {},        --list of tokens for current command
    curToken = { ERROR, 0 } --current token of current command
}

function VMTokenizer:new(file)
    local tokenizer = {}
    setmetatable(tokenizer, VMTokenizer)
    self.__index = self
    local rFile = io.open(file, 'r')
    if rFile == nil then
        error('file ' .. file .. ' not found\n')
    end
    --read all the lines and split it into separate strings
    tokenizer:tokenize(rFile:lines())
    return tokenizer
end

--are there more commands in the list
function VMTokenizer:hasMoreCommands() return self.tokens[1] ~= nil end

--move to the next command
function VMTokenizer:nextCommand()
    self.curCommand = self.tokens[1]
    table.remove(self.tokens, 1)
    self:nextToken()
end

--are there more tokens in the current token
function VMTokenizer:hasNextToken() return self.curCommand[1] ~= nil end

--move to the next token
function VMTokenizer:nextToken()
    if self:hasNextToken() then
        self.curToken = self.curCommand[1]
        table.remove(self.curCommand, 1)
    else
        self.curToken = { ERROR, 0 }
    end
    return self.curToken
end

--peek the next token
function VMTokenizer:peekToken()
    if self:hasNextToken() then
        return self.curCommand[1]
    else
        return { ERROR, 0 }
    end
end

--change all every line into tokens
function VMTokenizer:tokenize(lines)
    for line in lines do self:tokenizeLine(line) end
end

--tokenize a specific line
function VMTokenizer:tokenizeLine(line)
    local lineTok = {}
    for word in string.gmatch(self:removeComments(line), "%S+") do
        table.insert(lineTok, self:token(word))
    end
    if lineTok[1] ~= nil then
        table.insert(self.tokens, lineTok)
    end
end

--remove comments from a line, a comment start with //
function VMTokenizer:removeComments(line) return string.gsub(line, '//.*', '') end

--recognize a word. whether it number, identifier or something else(error)
function VMTokenizer:token(word)
    if self:isNum(word) then
        return { NUM, word }
    elseif self:isId(word) then
        return { ID, word }
    else
        return { ERROR, word }
    end
end

--check if the word is a number
function VMTokenizer:isNum(word) return string.match(word, "%d+") end

--check if the word is an indentifier
function VMTokenizer:isId(word)
    return string.match(word, "[A-Za-z_][A-Za-z0-9_]*")
end
