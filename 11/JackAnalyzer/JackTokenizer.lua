require "JackConstant"
-- tokens - table of all tokens
-- tokenType - type of the current token
-- val - value of the current token
-- outfile - xml file to translate the jack code into
JackTokenizer = {tokens, tokenType, val, outfile}

function JackTokenizer:new(file)
    local t = {}
    setmetatable(t, JackTokenizer)
    self.__index = self
    t.cfile = io.open(file, 'r')
    t.tokens = tokenize(t.cfile:read("*a"))
    t.tokenType = T_ERROR
    t.val = 0
    return t
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
        self.tokenType = self.tokens[1][1]
        self.val = self.tokens[1][2]
        table.remove(self.tokens, 1)
    else
        self.tokenType = T_ERROR
        self.val = 0
    end
    --self:writeXml()
    return self.tokenType, self.val
end

function JackTokenizer:peek()
    if self:hasMoreToken() then
        return self.tokens[1][1],self.tokens[1][2]
    else
        return T_ERROR, 0
    end
end

function JackTokenizer:writeXml()
    local tok = self.tokenType
    local val = self.val

    self:writeStartTag(tokenType[tok])

    if tok == T_KEYWORD then
        self.outfile:write(self:keyWord())
    elseif tok == T_SYM then
        self.outfile:write((self:symbol()))
    elseif tok == T_NUM then
        self.outfile:write(self:intVal())
    elseif tok == T_STR then
        self.outfile:write(self:stringVal())
    elseif tok == T_ID then
        self.outfile:write(self:identifier())
    elseif tok == T_ERROR then
        self.outfile:write("<<ERRORR>>")
    end
    self:writeEndTag(tokenType[tok])
end

function JackTokenizer:writeStartTag(token) self.outfile:write("<" .. token .. ">") end

function JackTokenizer:writeEndTag(token)
    self.outfile:write("</" .. token .. ">\n")
end

function JackTokenizer:tokenType() return self.tokenType end

function JackTokenizer:keyWord() return self.val end

function JackTokenizer:symbol() return self.val end

function JackTokenizer:identifier() return self.val end

function JackTokenizer:intVal() return self.val end

function JackTokenizer:stringVal() return self.val end

function tokenize(lines)
    t = {}
    for k, w in pairs(split(removeComments(lines))) do
        table.insert(t, token(w))
    end
    return t
end

function removeComments(line)
    lines = string.gsub(line, "//.-\n", "")
    lines = string.gsub(lines, "/%*.-%*/", "")
    return lines
end

function split(line)
    local ans = {}
    while line ~= nil do
        help = true
        -- check keyword(working)
        for v, w in pairs(keywords) do
            if starts(line, w) and help then
                table.insert(ans, string.sub(line, 1, w:len()))
                line = string.sub(line, w:len() + 1)
                help = false
            end
        end

        local firstChar = string.sub(line, 1, 1)
        -- check symbol(working)
        for v, s in pairs(symbols) do
            if s == firstChar and help then
                table.insert(ans, s)
                line = string.sub(line, 2)
                help = false
            end
        end
        -- check()
        if string.match(firstChar, "%s") and help then
            line = string.sub(line, 2)
            help = false

            -- check num(working)
        elseif string.match(firstChar, "%d+") and help then
            local num = string.match(line, "%d+")
            table.insert(ans, num)
            line = string.sub(line, num:len() + 1)
            help = false
            -- check string

        elseif firstChar == '"' and help == true then
            local nextQuote = string.find(line, '"', 2)
            currentToken = string.sub(line,1, nextQuote)
            table.insert(ans, currentToken)
            line = string.sub(line, nextQuote + 1)
            help = false

            -- check identifier
        elseif help == true and line ~= '' and line ~= nil then
            local start, finish = string.find(line, "[A-Za-z_][A-Za-z0-9_]*")
            if start ~= 1 then
                -- print(line)
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

--start a prefix, and there is no character after
function starts(String, prefix)
    return string.sub(String, 1, string.len(prefix)) == prefix and string.match(string.sub(String, prefix:len()+1,prefix:len()+1),'%s')~=nil
end

function token(word)
    if isKeyWord(word) then
        return {T_KEYWORD, word}
    elseif isSym(word) then
        return {T_SYM, word}
    elseif isNum(word) then
        return {T_NUM, word}
    elseif isStr(word) then
        return {T_STR, word:sub(2, word:len() - 1)}
    elseif isId(word) then
        return {T_ID, word}
    else
        return {T_ERROR, word}
    end
end

function isKeyWord(word)
    for v, w in pairs(keywords) do if word == w then return true end end
    return false
end

function isSym(word)
    for v, s in pairs(symbols) do if s == word then return true end end
end

function isNum(word) return tonumber(word) ~= nil end

function isStr(word) 
    return word:sub(1,1) == '"' and word:find('"',2) ~= nil 
end

function isId(word)
    local start, finish = string.find(word, "[A-Za-z_][A-Za-z0-9_]*")
    if start == 1 and finish == string.len(word) then return true end
    return false
end
