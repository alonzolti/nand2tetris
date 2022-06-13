require "JackTokenizer"
require "JackConstant"
require "SymbolTable"
require "VMWriter"
CompilationEngine = {tokenizer, vm, symbols, curClass, curSubroutine, labelNum}

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

function CompilationEngine:vmFunctionName()
    return self.curClass ..'.'.. self.curSubroutine
end

function CompilationEngine:vmPushVariable(name)
    t = self.symbols:lookup(name)
    self.vm:writePush(segments[t[2]], t[3])
end

function CompilationEngine:vmPopVariable(name)
    t = self.symbols:lookup(name)
    self.vm:writePop(segments[t[2]], t[3])
end

function CompilationEngine:require(tok, val)
    local curTok, curVal = self:advance()
    if tok ~= curTok or ((tok == T_KEYWORD or tok == T_SYM) and val ~= curVal) then
        error()
    else
        return curVal
    end
end

function CompilationEngine:advance() return self.tokenizer:advance() end

function CompilationEngine:isToken(tok, val)
    nextTok, nextVal = self.tokenizer:peek()
    return (val == nil and nextTok == tok) or (tok == nextTok and val == nextVal)
end

function CompilationEngine:openOut(file) self.vm:openOut(file) end

function CompilationEngine:closeOut() self.vm:closeOut() end

function CompilationEngine:isKeyWord(keywords)
    curTok, curVal = self.tokenizer:peek()
    for _, value in pairs(keywords) do
        if value == curVal and curTok == T_KEYWORD then return true end
    end
    return false
end

function CompilationEngine:isSym(symbo)
    curTok, curVal = self.tokenizer:peek()
    for c in symbo:gmatch(".") do
        if c == curVal and curTok == T_SYM then return true end
    end
    return false
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

function CompilationEngine:compileClass()
    self:require(T_KEYWORD, KW_CLASS)
    self:compileClassName()
    self:require(T_SYM, '{')
    while self:isClassVarDec() do self:compileClassVarDec() end
    while self:isSubroutine() do self:compileSubroutine() end
    self:require(T_SYM, '}')
end

function CompilationEngine:compileClassName()
    self.curClass = self:compileVarName()
end

function CompilationEngine:isClassVarDec()
    return self:isKeyWord({KW_STATIC, KW_FIELD})
end

function CompilationEngine:compileClassVarDec()
    local tok, kwd = self:advance()
    self:compileDec(kwd_to_kind[kwd])
end

function CompilationEngine:compileDec(kind)
    local type = self:compileType()
    local name = self:compileVarName()
    self.symbols:define(name, type, kind)
    while self:isSym(',') do
        self:advance()
        name = self:compileVarName()
        self.symbols:define(name, type, kind)
    end
    self:require(T_SYM, ';')
end

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

function CompilationEngine:isVarName() return self:isToken(T_ID) end

function CompilationEngine:compileVarName() return self:require(T_ID) end

function CompilationEngine:isSubroutine()
    return self:isKeyWord({KW_CONSTRUCTOR, KW_FUNCTION, KW_METHOD})
end

function CompilationEngine:compileSubroutine()
    local tok, kwd = self:advance()
    local type,a = self:compileVoidOrType()
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
        local type,a = self:compileType()
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

function CompilationEngine:writeFuncDecl(kwd)
    self.vm:writeFunction(self:vmFunctionName(), self.symbols:varCount(SK_VAR))
    self:loadThisPtr(kwd)
end

function CompilationEngine:loadThisPtr(kwd)
    if kwd == KW_METHOD then
        self.vm:pushArg(0)
        self.vm:popThisPtr()
    elseif kwd == KW_CONSTRUCTOR then
        self.vm:pushConst(self.symbols:varCount(SK_FIELD))
        self.vm:writeCall('Memory.alloc', 1)
        self.vm:popThisPtr()
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
    name = self:require(T_ID)
    self:compileSubroutineCall(name)
    self.vm:popTemp(TEMP_RETURN)
    self:require(T_SYM, ';')
end

function CompilationEngine:isLet() return self:isKeyWord({KW_LET}) end

function CompilationEngine:compileLet()
    self:require(T_KEYWORD, KW_LET)
    name = self:compileVarName()
    subscript = self:isSym('[')
    if subscript then self:compileBasePlusIndex(name) end
    self:require(T_SYM, '=')
    self:compileExpression()
    self:require(T_SYM, ';')
    if subscript then
        self:popArrayElement()
    else
        self:vmPopVariable(name)
    end
end

function CompilationEngine:compileBasePlusIndex(name)
    self:vmPushVariable(name)
    self:advance()
    self:compileExpression()
    self:require(T_SYM, ']')
    self.vm:writeVmCmd('add')
end

function CompilationEngine:popArrayElement()
    self.vm:popTemp(TEMP_ARRAY)
    self.vm:popThatPtr()
    self.vm:pushTemp(TEMP_ARRAY)
    self.vm:popThat()
end

function CompilationEngine:isWhile() return self:isKeyWord({KW_WHILE}) end

function CompilationEngine:compileWhile()
    self:require(T_KEYWORD, KW_WHILE)
    label = self:newLabel()
    self.vm:writeLabel(label)
    self:compileCondExpressionStatements(label)
end

function CompilationEngine:isReturn() return self:isKeyWord({KW_RETURN}) end

function CompilationEngine:compileReturn()
    self:require(T_KEYWORD, KW_RETURN)
    if not self:isSym(';') then
        self:compileExpression()
    else
        self.vm:pushConst(0)
    end
    self:require(T_SYM, ';')
    self.vm:writeReturn()
end

function CompilationEngine:isIf() return self:isKeyWord({KW_IF}) end

function CompilationEngine:compileIf()
    self:require(T_KEYWORD, KW_IF)
    label = self:newLabel()
    self:compileCondExpressionStatements(label)
    if self:isKeyWord({KW_ELSE}) then
        self:advance()
        self:require(T_SYM, '{')
        self:compileStatements()
        self:require(T_SYM, '}')
    end
    self.vm:writeLabel(label)
end

function CompilationEngine:compileCondExpressionStatements(label)
    self:require(T_SYM, '(')
    self:compileExpression()
    self:require(T_SYM, ')')
    self.vm:writeVmCmd('not')
    notifyLabel = self:newLabel()
    self.vm:writeIf(notifyLabel)
    self:require(T_SYM, '{')
    self:compileStatements()
    self:require(T_SYM, '}')
    self.vm:writeGoto(label)
    self.vm:writeLabel(notifyLabel)
end

function CompilationEngine:newLabel()
    self.labelNum = self.labelNum + 1
    return 'label' .. self.labelNum
end

function CompilationEngine:compileExpression()
    self:compileTerm()
    while self:isOp() do
        local tok,op = self:advance()
        self:compileTerm()
        self.vm:writeVmCmd(vmCmds[op])
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
        self.vm:writeVmCmd(vmUnaryCmds[op])
    elseif self:isVarName() then
        local tok, name = self:advance()
        if self:isSym('[') then
            self:compileArraySubscript(name)
        elseif self:isSym('(.') then
            self:compileSubroutineCall(name)
        else
            self:vmPushVariable(name)
        end
    end
end

function CompilationEngine:compileConst()
    local tok, val = self:advance()
    if tok == T_NUM then
        self.vm:pushConst(val)
    elseif tok == T_STR then
        self:writeStringConstInit(val)
    elseif tok == T_KEYWORD then
        self:compileKwdConst(val)
    end
end

function CompilationEngine:writeStringConstInit(val)
    self.vm:pushConst(val:len())
    self.vm:writeCall('String.new', 1)
    for c in val:gmatch(".") do
        self.vm:pushConst(string.byte(c))
        self.vm:writeCall('String.appendChar', 2)
    end
end

function CompilationEngine:compileKwdConst(kwd)
    if kwd == KW_THIS then
        self.vm:pushThisPtr()
    elseif kwd == KW_TRUE then
        self.vm:pushConst(1)
        self.vm:writeVmCmd('neg')
    else
        self.vm:pushConst(0)
    end
end

function CompilationEngine:compileArraySubscript(name)
    self:vmPushVariable(name)
    self:require(T_SYM, '[')
    self:compileExpression()
    self:require(T_SYM, ']')
    self.vm:writeVmCmd('add')
    self.vm:popThatPtr()
    self.vm:pushThat()
end

function CompilationEngine:compileSubroutineCall(name)
    t = self.symbols:lookup(name)
    if self:isSym('.') then
        numArgs, name = self:compileDottedSubroutineCall(name, t[1])
    else
        numArgs = 1
        self.vm:pushThisPtr()
        name = self.curClass .. '.' .. name
    end
    self:require(T_SYM, '(')
    numArgs = numArgs + self:compileExpressionList()
    self:require(T_SYM, ')')
    self.vm:writeCall(name, numArgs)
end

function CompilationEngine:compileDottedSubroutineCall(name, type)
    local numArgs = 0
    local objName = name
    self:advance()
    name = self:compileVarName()
    if self:isBuiltinType(type) then
        error()
    elseif type == nil then
        name = objName .. '.' .. name
    else
        numArgs = 1
        self:vmPushVariable(objName)
        name = self.symbols:typeOf(objName) .. '.' .. name
    end
    return numArgs, name
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
    numArgs = 0
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
