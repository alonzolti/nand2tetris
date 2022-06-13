require "JackTokenizer"
require "JackConstant"
CompilationEngine = {tokenizer, outfile, parsedRules}

function CompilationEngine:new(file)
    local t = {}
    setmetatable(t,CompilationEngine)
    self.__index = self
    t.tokenizer = JackTokenizer:new(file)
    t.outfile = nil;
    t.parsedRules = {}
    t:openOut(file)
    t:compileClass()
    t:closeOut()
    return t
end

function CompilationEngine:require(tok, val)
    curTok, curVal = self:advance()
    
    if tok ~= curTok or ((tok == T_KEYWORD or tok == T_SYM) and val ~= curVal) then
        error()
    else
        return curVal
    end
end

function CompilationEngine:advance()
    local tok,val = self.tokenizer:advance()

    self:writeTerminal(tok, val)
    return tok, val
end

function CompilationEngine:isToken(tok, val)
    nextTok, nextVal = self.tokenizer:peek()
    if (val == nil) then
        return nextTok == tok
    else
        return nextTok == tok and nextVal == val
    end
end

function CompilationEngine:openOut(file)
    self.outfile = io.open(string.gsub(file, '.jack', '.xml'), 'w')
    self.tokenizer:openOut(file)
end

function CompilationEngine:closeOut()
    self.tokenizer:closeOut()
    self.outfile:close()
end

function CompilationEngine:writeTerminal(tok, val)
    self.outfile:write("<" .. tokenType[tok] .. '> ' .. escape(val) .. ' </' ..
                           tokenType[tok] .. '>\n')
end

function escape(val)
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

function CompilationEngine:startNonTerminal(rule)
    self.outfile:write('<' .. rule .. ">\n")
    table.insert(self.parsedRules, rule)
end

function CompilationEngine:endNotTerminal()
    rule = table.remove(self.parsedRules)
    self.outfile:write('</' .. rule .. '>\n')
end

function CompilationEngine:compileClass()
    self:startNonTerminal('class')
    self:require(T_KEYWORD, KW_CLASS)
    className = self:require(T_ID)
    self:require(T_SYM, '{')
    while self:isClassVarDec() do self:compileClassVarDec() end
    while self:isSubroutine() do self:compileSubroutine() end

    self:require(T_SYM, '}')
    self:endNotTerminal()
end

function CompilationEngine:isClassVarDec()
    return self:isToken(T_KEYWORD, KW_STATIC) or
               self:isToken(T_KEYWORD, KW_FIELD)
end

function CompilationEngine:compileClassVarDec()
    self:startNonTerminal('classVarDec')
    tok, kwd = self:advance()
    self:compileDec()
    self:endNotTerminal()
end

function CompilationEngine:compileDec()
    self:compileType()
    self:compileVarName()
    while self:isToken(T_SYM, ',') do
        self:require(T_SYM, ',')
        self:compileVarName()
    end
    self:require(T_SYM, ';')
end

function CompilationEngine:isType()
    tok, val = self.tokenizer:peek()
    return tok == T_KEYWORD and
               (val == KW_INT or val == KW_CHAR or val == KW_BOOLEAN) or tok ==
               T_ID
end

function CompilationEngine:compileType()
    if self:isType() then
        return self:advance()
    else
        error()
    end
end

function CompilationEngine:compileVoidOrType()
    if self:isToken(T_KEYWORD, KW_VOID) then
        return self:advance()
    else
        self:compileType()
    end
end

function CompilationEngine:isVarName() return self:isToken(T_ID) end

function CompilationEngine:compileVarName() self:require(T_ID) end

function CompilationEngine:isSubroutine()
    tok, kwd = self.tokenizer:peek()
    return tok == T_KEYWORD and
               (kwd == KW_CONSTRUCTOR or kwd == KW_FUNCTION or kwd == KW_METHOD)
end

function CompilationEngine:compileSubroutine()
    self:startNonTerminal('subroutineDec')
    kwd = self:advance()
    self:compileVoidOrType()
    self:compileVarName()
    self:require(T_SYM, '(')
    self:compileParameterList()
    self:require(T_SYM, ')')
    self:compileSubroutineBody()
    self:endNotTerminal()
end

function CompilationEngine:compileParameterList()
    self:startNonTerminal('parameterList')
    self:compileParameter()
    while self:isToken(T_SYM, ',') do
        self:advance()
        self:compileParameter()
    end
    self:endNotTerminal()
end

function CompilationEngine:compileParameter()
    if self:isType()then
        self:compileType()
        self:compileVarName()
    end
end

function CompilationEngine:compileSubroutineBody()
    self:startNonTerminal('subroutineBody')
    self:require(T_SYM, '{')
    while self:isVarDec() do self:compileVarDec() end
    self:compileStatements()
    self:require(T_SYM, '}')
    self:endNotTerminal()
end

function CompilationEngine:isVarDec() return self:isToken(T_KEYWORD, KW_VAR) end

function CompilationEngine:compileVarDec()
    self:startNonTerminal('varDec')
    self:require(T_KEYWORD, KW_VAR)
    self:compileDec()
    self:endNotTerminal()
end

function CompilationEngine:compileStatements()
    self:startNonTerminal("statements")
    while self:isStatement() do self:compileStatment() end
    self:endNotTerminal()
end

function CompilationEngine:isStatement()
    return self:isDo() or self:isLet() or self:isIf() or self:isWhile() or
               self:isReturn()
end

function CompilationEngine:compileStatment()
    if self:isDo() then
        self:compileDo()
    elseif self:isLet() then
        self:compileLet()
    elseif self:isIf() then
        self:compileIf()
    elseif self:isWhile() then
        self:compileWhile()
    elseif self:isReturn() then
        self:compileReturn()
    end
end

function CompilationEngine:isDo() return self:isToken(T_KEYWORD, KW_DO) end

function CompilationEngine:compileDo()
    self:startNonTerminal('doStatement')
    self:require(T_KEYWORD, KW_DO)
    self:require(T_ID)
    self:compileSubroutineCall()
    self:require(T_SYM, ';')
    self:endNotTerminal()
end

function CompilationEngine:isLet() return self:isToken(T_KEYWORD, KW_LET) end

function CompilationEngine:compileLet()
    self:startNonTerminal('letStatement')
    self:require(T_KEYWORD, KW_LET)
    self:compileVarName()
    if self:isToken(T_SYM, '[') then
        self:advance()
        self:compileExpression()
        self:require(T_SYM, ']')
    end
    self:require(T_SYM, '=')
    self:compileExpression()
    self:require(T_SYM, ';')
    self:endNotTerminal()
end

function CompilationEngine:isWhile() return self:isToken(T_KEYWORD, KW_WHILE) end

function CompilationEngine:compileWhile()
    self:startNonTerminal('whileStatement')
    self:require(T_KEYWORD, KW_WHILE)
    self:compileCondExpressionStatements()
    self:endNotTerminal()
end

function CompilationEngine:isReturn() return self:isToken(T_KEYWORD, KW_RETURN) end

function CompilationEngine:compileReturn()
    self:startNonTerminal('returnStatement')
    self:require(T_KEYWORD, KW_RETURN)
    if self:isToken(T_SYM, ';')==false then self:compileExpression() end
    self:require(T_SYM, ';')
    self:endNotTerminal()
end

function CompilationEngine:isIf() return self:isToken(T_KEYWORD, KW_IF) end

function CompilationEngine:compileIf()
    self:startNonTerminal('ifStatement')
    self:require(T_KEYWORD, KW_IF)
    self:compileCondExpressionStatements()
    if self:isToken(T_KEYWORD, KW_ELSE) then
        self:adnvace()
        self:compileStatements()
    end
    self:endNotTerminal()
end

function CompilationEngine:compileCondExpressionStatements()
    self:require(T_SYM,'(')
    self:compileExpression()
    self:require(T_SYM,')')
    self:require(T_SYM,'{')
    self:compileStatements()
    self:require(T_SYM,'}')
end

function CompilationEngine:compileExpression()
    if self:isTerm() == false then return end
    self:startNonTerminal('expression')
    self:compileTerm()
    while self:isOp() do
        self:advance()
        self:compileTerm()
    end
    self:endNotTerminal()
end

function CompilationEngine:isTerm()
    return self:isToken(T_NUM) or self:isToken(T_STR) or
               self:isKeywordConstant() or self:isVarName() or
               self:isToken(T_SYM, '(') or self:isUnaryOp()
end

function CompilationEngine:compileTerm()
    self:startNonTerminal('term')
    if self:isToken(T_NUM) or self:isToken(T_STR) or self:isKeywordConstant() then
        self:advance()
    elseif self:isToken(T_SYM, '(') then
        self:advance()
        self:compileExpression()
        self:require(T_SYM, ')')
    elseif self:isUnaryOp() then
        self:advance()
        self:compileTerm()
    elseif self:isVarName() then
        self:advance()
        if self:isToken(T_SYM, '[') then
            self:compileArraySubscript()
        elseif self:isToken(T_SYM, '(') or self:isToken(T_SYM, '.') then
            self:compileSubroutineCall()
        end
    end
    self:endNotTerminal()
end

function CompilationEngine:compileArraySubscript()
    self:require(T_SYM, '[')
    self:compileExpression()
    self:require(T_SYM, ']')
end

function CompilationEngine:compileSubroutineCall()
    if self:isToken(T_SYM, '.') then
        self:advance()
        self:require(T_ID)
    end
    self:require(T_SYM, '(')
    self:compileExpressionList()
    self:require(T_SYM, ')')
end

function CompilationEngine:isKeywordConstant()
    tok, kwd = self.tokenizer:peek()
    return tok == T_KEYWORD and
               (kwd == KW_TRUE or kwd == KW_FALSE or kwd == KW_NULL or kwd ==
                   KW_THIS)
end

function CompilationEngine:isUnaryOp()
    return self:isToken(T_SYM, '-') or self:isToken(T_SYM, '~')
end

function CompilationEngine:isOp()
    tok, sym = self.tokenizer:peek()
    return tok == T_SYM and string.find('+-*/&|<>=', sym) ~= nil
end

function CompilationEngine:compileExpressionList()
    self:startNonTerminal('expressionList')
    self:compileExpression()
    while self:isToken(T_SYM, ',') do
        self:advance()
        self:compileExpression()
    end
    self:endNotTerminal()
end
