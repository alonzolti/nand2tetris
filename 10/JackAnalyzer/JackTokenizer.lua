require "JackConstant"
-- tokens - table of all tokens
-- tokenType - type of the current token
-- val - value of the current token
-- outfile - xml file to translate the jack code into
JackTokenizer = { tokens = nil, tokenType = T_ERROR, val = 0, outfile = nil }

function JackTokenizer:new(file)
    local tokenizer = {}
    setmetatable(tokenizer, JackTokenizer)
    self.__index = self
    local cfile = io.open(file, 'r')
    if cfile == nil then
        return error("file" .. file .. " isn't exist\n")
    end
    tokenizer.tokens = tokenizer:tokenize(cfile:read("*a"))

    return tokenizer
end

function JackTokenizer:openOut(file)
    self.outfile = io.open(string.gsub(file, ".jack", "T.xml"), 'w')
    self.outfile:write("<tokens>\n")
end

function JackTokenizer:closeOut()
    self.outfile:write("</tokens>")
    self.outfile:close()
end

function JackTokenizer:hasMoreToken() return self.tokens[1] ~= nil end

function JackTokenizer:advance()
    if self:hasMoreToken() then
        self.tokenType, self.val = self.tokens[1][1], self.tokens[1][2]
        table.remove(self.tokens, 1)
    else
        self.tokenType = T_ERROR
        self.val = 0
    end
    self:writeXml()
    return self.tokenType, self.val
end

function JackTokenizer:peek()
    if self:hasMoreToken() then
        return self.tokens[1][1], self.tokens[1][2]
    else
        return T_ERROR, 0
    end
end

function JackTokenizer:writeXml()
    self:writeStartTag(TokenType[self.tokenType])
    if self.tokenType == T_ERROR then
        self.outfile:write("<<ERRORR>>")
    end
    if self.tokenType == T_SYM then
        self.outfile:write(self:escape(self.val))
    else
        self.outfile:write(self.val)
    end
    self:writeEndTag(TokenType[self.tokenType])
end

function JackTokenizer:escape(val)
    if val == '<' then
        return "&lt;"
    elseif val == ">" then
        return "&gt;"
    elseif val == "&" then
        return "&amp;"
    else
        return val
    end
end

function JackTokenizer:writeStartTag(token) self.outfile:write("<" .. token .. ">") end

function JackTokenizer:writeEndTag(token)
    self.outfile:write("</" .. token .. ">\n")
end

function JackTokenizer:tokenize(lines)
    local words = {}
    for _, w in pairs(self:split(self:removeComments(lines))) do
        table.insert(words, self:token(w))
    end
    return words
end

function JackTokenizer:removeComments(line)
    local lines = string.gsub(line, "//.-\n", "")
    lines = string.gsub(lines, "/%*.-%*/", "")
    return lines
end

--the function converts a line into tokens
function JackTokenizer:split(line)
    local ans = {}
    while line ~= nil do
        local help = true
        --if the first word is a keyword
        for v, w in pairs(Keywords) do
            if self:starts(line, w) and help then
                table.insert(ans, string.sub(line, 1, w:len()))
                line = string.sub(line, w:len() + 1)
                help = false
            end
        end
        --if the first char is a symbol
        local firstChar = string.sub(line, 1, 1)
        for v, s in pairs(Symbols) do
            if s == firstChar and help then
                table.insert(ans, s)
                line = string.sub(line, 2)
                help = false
            end
        end
        --if the first char is a space
        if string.match(firstChar, "%s") and help then
            line = string.sub(line, 2)
            help = false
        --if the first char is a number
        elseif string.match(firstChar, "%d+") and help then
            local num = string.match(line, "%d+")
            table.insert(ans, num)
            line = string.sub(line, num:len() + 1)
            help = false
        --if the first char is "
        elseif firstChar == '"' and help == true then
            local nextQuote = string.find(line, '"', 2)
            local currentToken = string.sub(line, 1, nextQuote)
            table.insert(ans, currentToken)
            line = string.sub(line, nextQuote + 1)
            help = false
        --if the first word is identifier
        elseif help == true and line ~= '' and line ~= nil then
            local start, finish = string.find(line, "[A-Za-z_][A-Za-z0-9_]*")
            if start ~= 1 then
            else
                local tok = string.sub(line, 1, finish)
                table.insert(ans, tok)
                line = string.sub(line, finish + 1)
            end
        end
        if line == '' then line = nil end
    end
    return ans
end

function JackTokenizer:starts(String, prefix)
    return string.sub(String, 1, string.len(prefix)) == prefix and
        string.match(string.sub(String, prefix:len() + 1, prefix:len() + 1), '%s') ~= nil
end

function JackTokenizer:token(word)
    if self:isKeyWord(word) then
        return { T_KEYWORD, word }
    elseif self:isSym(word) then
        return { T_SYM, word }
    elseif self:isNum(word) then
        return { T_NUM, word }
    elseif self:isStr(word) then
        return { T_STR, word:sub(2, word:len() - 1) }
    elseif self:isId(word) then
        return { T_ID, word }
    else
        return { T_ERROR, word }
    end
end

function JackTokenizer:isKeyWord(word)
    for _, w in pairs(Keywords) do if word == w then return true end end
    return false
end

function JackTokenizer:isSym(word)
    for _, s in pairs(Symbols) do if s == word then return true end end
    return false
end

function JackTokenizer:isNum(word) return tonumber(word) ~= nil end

function JackTokenizer:isStr(word)
    return word:sub(1, 1) == '"' and word:find('"', 2) ~= nil
end

function JackTokenizer:isId(word)
    local start, finish = string.find(word, "[A-Za-z_][A-Za-z0-9_]*")
    if start == 1 and finish == string.len(word) then return true end
    return false
end
