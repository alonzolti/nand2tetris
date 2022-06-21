require "JackTokenizer"
require "JackConstant"
require "SymbolTable"
require "VMWriter"
CompilationEngine = {
    tokenizer = nil,
    vm = nil,
    symbols = nil,
    curClass = nil,
    curSubroutine = nil,
    labelNum = nil
}

-- constructor
function CompilationEngine:new(file)
    local t = {}
    setmetatable(t, CompilationEngine)
    self.__index = self
    t.tokenizer = JackTokenizer:new(file)
    t.labelNum = 0
    t.symbols = SymbolTable:new()
    t.vm = VMWriter:new()
    t:openOut(file)
    t:compileClass()
    t:closeOut()
    return t
end

-- return current function name, className.subroutineName
function CompilationEngine:vmFunctionName()
    return self.curClass .. '.' .. self.curSubroutine
end

-- the next token must be tok,val and check if it is
-- work
function CompilationEngine:require(tok, val)
    local curTok, curVal = self:advance()
    if tok ~= curTok or ((tok == T_KEYWORD or tok == T_SYM) and val ~= curVal) then
        error()
    else
        return curVal
    end
end
-- advance the token, return the token and it's value
-- work
function CompilationEngine:advance() return self.tokenizer:advance() end

-- check the next token equal to what we need and return true/false
-- work
function CompilationEngine:isToken(tok, val)
    local nextTok, nextVal = self.tokenizer:peek()
    return (val == nil and nextTok == tok) or
               (tok == nextTok and val == nextVal)
end
-- open the file for writing
-- work
function CompilationEngine:openOut(file) self.vm:openOut(file) end
-- close the file
-- work
function CompilationEngine:closeOut() self.vm:closeOut() end

-- if the next token is in keywords that are given in th eparameter
-- work
function CompilationEngine:isKeyWord(keywords)
    local curTok, curVal = self.tokenizer:peek()
    for _, value in pairs(keywords) do
        if value == curVal and curTok == T_KEYWORD then return true end
    end
    return false
end

-- is the next token is a symbol
-- work
function CompilationEngine:isSym(symbo)
    local curTok, curVal = self.tokenizer:peek()
    for c in symbo:gmatch(".") do
        if c == curVal and curTok == T_SYM then return true end
    end
    return false
end

-- compile a complete class
-- work
function CompilationEngine:compileClass()
    self:require(T_KEYWORD, KW_CLASS)
    -- class doesn't need to be in symbol table
    self:compileClassName()

    self:require(T_SYM, '{')

    while self:isClassVarDec() do self:compileClassVarDec() end
    while self:isSubroutine() do self:compileSubroutine() end
    self:require(T_SYM, '}')
end

-- compile class name
-- work
function CompilationEngine:compileClassName()
    self.curClass = self:compileVarName()
end
-- work
function CompilationEngine:isClassVarDec()
    return self:isKeyWord({KW_STATIC, KW_FIELD})
end
-- work
function CompilationEngine:compileClassVarDec()
    local tok, kwd = self:advance()
    self:compileDec(kwd_to_kind[kwd])
end

-- work
function CompilationEngine:compileDec(kind)
    local _, type = self:compileType()
    local name = self:compileVarName()
    self.symbols:define(name, type, kind)
    while self:isSym(',') do

        self:advance()
        name = self:compileVarName()
        self.symbols:define(name, type, kind)
    end
    self:require(T_SYM, ';')
end
-- work
function CompilationEngine:isType()
    return self:isToken(T_ID) or self:isKeyWord({KW_INT, KW_CHAR, KW_BOOLEAN})
end

function CompilationEngine:compileVoidOrType()
    if self:isKeyWord({KW_VOID}) then
        return self:advance()
    else
        return self:compileType()
    end
end

function CompilationEngine:compileType()
    if self:isType() then
        return self:advance()
    else
        error()
    end
end

-- work
function CompilationEngine:isVarName() return self:isToken(T_ID) end

-- work
function CompilationEngine:compileVarName() return self:require(T_ID) end

function CompilationEngine:isSubroutine()
    return self:isKeyWord({KW_CONSTRUCTOR, KW_FUNCTION, KW_METHOD})
end

function CompilationEngine:compileSubroutine()
    local tok, kwd = self:advance()
    local _, type = self:compileVoidOrType()
    self:compileSubroutineName()
    self.symbols:startSubroutine()
    if kwd == KW_METHOD then
        self.symbols:define('this', self.curClass, SK_ARG)
    end
    self:require(T_SYM, '(')
    self:compileParameterList()
    self:require(T_SYM, ')')
    self:compileSubroutineBody(kwd)
end

function CompilationEngine:compileSubroutineName()
    self.curSubroutine = self:compileVarName()
end

function CompilationEngine:compileParameterList()
    if self:isType() then
        self:compileParameter()
        while self:isSym(',') do
            self:advance()
            self:compileParameter()
        end
    end
end

function CompilationEngine:compileParameter()
    if self:isType() then
        local _, type = self:compileType()
        local name = self:compileVarName()
        self.symbols:define(name, type, SK_ARG)
    end
end

function CompilationEngine:compileSubroutineBody(kwd)
    self:require(T_SYM, '{')
    while self:isVarDec() do self:compileVarDec() end
    self:writeFuncDecl(kwd)
    self:compileStatements()
    self:require(T_SYM, '}')
end

-- work
function CompilationEngine:writeFuncDecl(kwd)
    self.vm:writeFunction(self:vmFunctionName(), self.symbols:varCount(SK_VAR))
end

-- work
function CompilationEngine:loadThisPtr(kwd)
    if kwd == KW_METHOD then
        self.vm:writePush(SE_ARG, 0)
        self.vm:writePop(SE_POINTER, 0)
    elseif kwd == KW_CONSTRUCTOR then
        self.vm:writePush(SE_CONST, self.symbols:varCount(SK_FIELD))
        self.vm:writeCall("Memory.alloc", 1)
        self.vm:writePop(SE_POINTER, 0)
    end
end

function CompilationEngine:isVarDec() return self:isKeyWord({KW_VAR}) end

function CompilationEngine:compileVarDec()
    self:require(T_KEYWORD, KW_VAR)
    return self:compileDec(SK_VAR)
end

function CompilationEngine:compileStatements()
    while self:isStatement() do self:compileStatment() end
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

function CompilationEngine:isDo() return self:isKeyWord({KW_DO}) end

function CompilationEngine:compileDo()
    self:require(T_KEYWORD, KW_DO)
    local name = self:require(T_ID)
    self:compileSubroutineCall(name)
    self.vm:writePop(SE_TEMP, 0)
    self:require(T_SYM, ';')
end

function CompilationEngine:isLet() return self:isKeyWord({KW_LET}) end

function CompilationEngine:compileLet()
    self:require(T_KEYWORD, KW_LET)
    local name = self:compileVarName()
    local subscript = self:isSym('[')
    if subscript then self:compileBasePlusIndex(name) end
    self:require(T_SYM, '=')
    self:compileExpression()
    self:require(T_SYM, ';')
    if subscript then
        self:popArrayElement()
    else
        self.vm:writePop(self:getSeg(self.symbols:kindOf(name)),
                         self.symbols:indexOf(name))
    end
end

function CompilationEngine:getSeg(kind)
    if kind == SK_FIELD then
        return SE_THIS
    elseif kind == SK_STATIC then
        return SE_STATIC
    elseif kind == SK_VAR then
        return SE_LOCAL
    elseif kind == SK_ARG then
        return SE_ARG
    else
        return SE_NONE
    end
end

-- work
function CompilationEngine:compileBasePlusIndex(name)
    self.vm:writePush(self:getSeg(self.symbols:kindOf(name)),
                      self.symbols:indexOf(name))
    self:advance()
    self:compileExpression()
    self:require(T_SYM, ']')
    self.vm:writeArithmetic(CMD_ADD)
end

function CompilationEngine:popArrayElement()
    self.vm:writePop(SE_TEMP, 0)
    self.vm:writePop(SE_POINTER, 1)
    self.vm:writePush(SE_TEMP, 0)
    self.vm:writePop(SE_THAT, 0)
end

function CompilationEngine:isWhile() return self:isKeyWord({KW_WHILE}) end

function CompilationEngine:compileWhile()
    self:require(T_KEYWORD, KW_WHILE)
    local continueLabel = self:newLabel()
    local topLabel = self:newLabel()
    self.vm:writeLabel(topLabel)
    self:require(T_SYM, '(')
    self:compileExpression()
    self:require(T_SYM, ')')
    self.vm:writeArithmetic(CMD_NOT)
    self.vm:writeIf(continueLabel)
    self:require(T_SYM, '{')
    self:compileStatements()
    self:require(T_SYM, '}')
    self.vm:writeGoto(topLabel)
    self.vm:writeLabel(continueLabel)
end

function CompilationEngine:isReturn() return self:isKeyWord({KW_RETURN}) end

function CompilationEngine:compileReturn()
    self:require(T_KEYWORD, KW_RETURN)
    if not self:isSym(';') then
        self:compileExpression()
    else
        self.vm:writePush(SE_CONST, 0)
    end
    self:require(T_SYM, ';')
    self.vm:writeReturn()
end

function CompilationEngine:isIf() return self:isKeyWord({KW_IF}) end

function CompilationEngine:compileIf()
    self:require(T_KEYWORD, KW_IF)
    local elseLabel = self:newLabel()
    local endLabel = self:newLabel()
    self:require(T_SYM, '(')
    self:compileExpression()
    self:require(T_SYM, ')')
    self.vm:writeArithmetic(CMD_NOT)
    self.vm:writeIf(elseLabel)
    self:require(T_SYM, '{')
    self:compileStatements()
    self:require(T_SYM, '}')
    self.vm:writeGoto(endLabel)
    self.vm:writeLabel(elseLabel)

    if self:isKeyWord({KW_ELSE}) then
        self:advance()
        self:require(T_SYM, '{')
        self:compileStatements()
        self:require(T_SYM, '}')
    end
    self.vm:writeLabel(endLabel)
end

function CompilationEngine:newLabel()
    self.labelNum = self.labelNum + 1
    return 'LABEL_' .. self.labelNum
end

function CompilationEngine:compileExpression()
    self:compileTerm()
    while self:isOp() do
        local tok, op = self:advance()
        self:compileTerm()
        if op == '+' then
            op = 'add'
        elseif op == '-' then
            op = 'sub'
        elseif op == '*' then
            op = "call Math.multiply 2"
        elseif op == '/' then
            op = "call Math.divide 2"
        elseif op == '<' then
            op = "lt"
        elseif op == '>' then
            op = "gt"
        elseif op == '=' then
            op = 'eq'
        elseif op == '&' then
            op = 'and'
        elseif op == '|' then
            op = 'or'
        else
            error()
        end
        self.vm:writeCommand(op, '', '')
    end
end

function CompilationEngine:isTerm()
    return self:isConst() or self:isVarName() or self:isSym('(') or
               self:isUnaryOp()
end

function CompilationEngine:compileTerm()
    if self:isConst() then
        self:compileConst()
    elseif self:isSym('(') then
        self:advance()
        self:compileExpression()
        self:require(T_SYM, ')')
    elseif self:isUnaryOp() then
        local tok, op = self:advance()
        self:compileTerm()
        if op == '-' then
            self.vm:writeArithmetic(CMD_NEG)
        else
            self.vm:writeArithmetic(CMD_NOT)
        end
    elseif self:isVarName() then
        local tok, name = self:advance()
        if self:isSym('[') then
            self:compileArraySubscript(name)
        elseif self:isSym('(.') then
            self:compileSubroutineCall(name)
        else
            self.vm:writePush(self:getSeg(self.symbols:kindOf(name)),
                              self.symbols:indexOf(name))
        end
    end
end
-- work
function CompilationEngine:compileConst()
    local tok, val = self:advance()
    if tok == T_NUM then
        self.vm:writePush(SE_CONST, val)
    elseif tok == T_STR then
        self:writeStringConstInit(val)
    elseif tok == T_KEYWORD then
        self:compileKwdConst(val)
    end
end
-- work
function CompilationEngine:writeStringConstInit(val)
    self.vm:writePush(SE_CONST, val:len())
    self.vm:writeCall('String.new', 1)
    for c in val:gmatch(".") do
        self.vm:writePush(SE_CONST, string.byte(c))
        self.vm:writeCall('String.appendChar', 2)
    end
end
-- work
function CompilationEngine:compileKwdConst(kwd)
    if kwd == KW_THIS then
        self.vm:writePush(SE_POINTER, 0)
    elseif kwd == KW_TRUE then
        self.vm:writePush(SE_CONST, 0)
        self.vm:writeArithmetic(CMD_NOT)
    else
        self.vm:writePush(SE_CONST, 0)
    end
end

function CompilationEngine:compileArraySubscript(name)
    self.vm:writePush(self:getSeg(self.symbols:kindOf(name)),
                      self.symbols:indexOf(name))
    self:require(T_SYM, '[')
    self:compileExpression()
    self:require(T_SYM, ']')
    self.vm:writeArithmetic(CMD_ADD)
    self.vm:writePop(SE_POINTER, 1)
    self.vm:writePush(SE_THAT, 0)
end

function CompilationEngine:compileSubroutineCall(name)
    local numArgs = 0
    if self:isSym('.') then
        self:require(T_SYM, '.')
        local objName = name
        _, name = self:advance()
        type = self.symbols:typeOf(objName)
        if self:isBuiltinType(type) then
            error()
        elseif type == nil then
            name = objName .. '.' .. name
        else
            numArgs = 1
            self.vm:writePush(self:getSeg(self.symbols:kindOf(objName)),
                              self.symbols:indexOf(objName))
            name = self.symbols:typeOf(objName) .. '.' .. name
        end
        self:require(T_SYM, '(')
        numArgs = numArgs + self:compileExpressionList()
        self:require(T_SYM, ')')
        self.vm:writeCall(name, numArgs)
    else -- ='('
        self:require(T_SYM, '(')
        self.vm:writePush(SE_POINTER, 0)
        numArgs = self:compileExpressionList() + 1
        self:require(T_SYM, ')')
        self.vm:writeCall(self.curClass .. '.' .. name, numArgs)
    end

end

function CompilationEngine:isBuiltinType(type)
    return type == KW_INT or type == KW_CHAR or type == KW_BOOLEAN or type ==
               KW_VOID
end

function CompilationEngine:isConst()
    return self:isToken(T_NUM) or self:isToken(T_STR) or
               self:isKeywordConstant()
end

function CompilationEngine:isKeywordConstant()
    return self:isKeyWord({KW_TRUE, KW_FALSE, KW_NULL, KW_THIS})
end

function CompilationEngine:isUnaryOp() return self:isSym('-~') end

function CompilationEngine:isOp() return self:isSym('+-*/&|<>=') end

function CompilationEngine:compileExpressionList()
    local numArgs = 0
    if self:isTerm() then
        self:compileExpression()
        numArgs = 1
        while self:isSym(',') do
            self:advance()
            self:compileExpression()
            numArgs = numArgs + 1
        end
    end
    return numArgs
end
