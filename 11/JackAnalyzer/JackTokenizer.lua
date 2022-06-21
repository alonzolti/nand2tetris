require "JackConstant"
-- tokens - table of all tokens
-- tokenType - type of the current token
-- val - value of the current token
-- outfile - xml file to translate the jack code into
JackTokenizer = {tokens = nil, tokenType = T_ERROR, val = 0, outfile = nil}

function JackTokenizer:new(file)
    local t = {}
    setmetatable(t, JackTokenizer)
    self.__index = self
    t.cfile = io.open(file, 'r')
    t.tokens = t:tokenize(t.cfile:read("*a"))
    return t
end

function JackTokenizer:hasMoreToken() return self.tokens[1] ~= nil end

function JackTokenizer:advance()
    if self:hasMoreToken() then
        self.tokenType = self.tokens[1][1]
        self.val = self.tokens[1][2]
        table.remove(self.tokens, 1)
    else
        self.tokenType = T_ERROR
        self.val = 0
    end
    return self.tokenType, self.val
end

function JackTokenizer:peek()
    if self:hasMoreToken() then
        return self.tokens[1][1], self.tokens[1][2]
    else
        return T_ERROR, 0
    end
end

function JackTokenizer:tokenType() return self.tokenType end

function JackTokenizer:keyWord() return self.val end

function JackTokenizer:symbol() return self.val end

function JackTokenizer:identifier() return self.val end

function JackTokenizer:intVal() return self.val end

function JackTokenizer:stringVal() return self.val end

function JackTokenizer:tokenize(lines)
    local t = {}
    for k, w in pairs(self:split(self:removeComments(lines))) do
        table.insert(t, self:token(w))
    end
    return t
end

function JackTokenizer:removeComments(line)
    local lines = string.gsub(line, "//.-\n", "")
    lines = string.gsub(lines, "/%*.-%*/", "")
    return lines
end

function JackTokenizer:split(line)
    local ans = {}
    while line ~= nil do
        local help = true
        for v, w in pairs(keywords) do
            if self:starts(line, w) and help then
                table.insert(ans, string.sub(line, 1, w:len()))
                line = string.sub(line, w:len() + 1)
                help = false
            end
        end

        local firstChar = string.sub(line, 1, 1)
        for v, s in pairs(symbols) do
            if s == firstChar and help then
                table.insert(ans, s)
                line = string.sub(line, 2)
                help = false
            end
        end
        if string.match(firstChar, "%s") and help then
            line = string.sub(line, 2)
            help = false
        elseif string.match(firstChar, "%d+") and help then
            local num = string.match(line, "%d+")
            table.insert(ans, num)
            line = string.sub(line, num:len() + 1)
            help = false
        elseif firstChar == '"' and help == true then
            local nextQuote = string.find(line, '"', 2)
            local currentToken = string.sub(line, 1, nextQuote)
            table.insert(ans, currentToken)
            line = string.sub(line, nextQuote + 1)
            help = false
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
               string.match(
                   string.sub(String, prefix:len() + 1, prefix:len() + 1), '%s') ~=
               nil
end

function JackTokenizer:token(word)
    if self:isKeyWord(word) then
        return {T_KEYWORD, word}
    elseif self:isSym(word) then
        return {T_SYM, word}
    elseif self:isNum(word) then
        return {T_NUM, word}
    elseif self:isStr(word) then
        return {T_STR, word:sub(2, word:len() - 1)}
    elseif self:isId(word) then
        return {T_ID, word}
    else
        return {T_ERROR, word}
    end
end

function JackTokenizer:isKeyWord(word)
    for v, w in pairs(keywords) do if word == w then return true end end
    return false
end

function JackTokenizer:isSym(word)
    for v, s in pairs(symbols) do if s == word then return true end end
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
