require "JackConstant"
--- the class responsible of saving the class and function variable data
SymbolTable = { classSymbols = {}, subroutineSymbols = {}, index = { 0, 0, 0, 0 } }
--- constructor
function SymbolTable:new()
    local table = {}
    setmetatable(table, SymbolTable)
    self.__index = self
    return table
end

--- the function initialize the subroutine symbol table at the start of every function
function SymbolTable:startSubroutine()
    self.subroutineSymbols = {}
    self.index[SK_VAR] = 0
    self.index[SK_ARG] = 0
end

--- the function adds a variable to the tables based on his kind
--- if its a local variable or argument, then the function adds it to the subroutine table
--- and if its a static or field varialbe then the function adds it to the class table
function SymbolTable:define(name, type, kind)
    if kind == SK_ARG or kind == SK_VAR then
        local a = self.index[kind]
        self.index[kind] = self.index[kind] + 1
        self.subroutineSymbols[name] = { type, kind, a }
    elseif kind == SK_STATIC or kind == SK_FIELD then
        local a = self.index[kind]
        self.index[kind] = self.index[kind] + 1
        self.classSymbols[name] = { type, kind, a }
    end
end

--- the function return the number of variables of the same kind
function SymbolTable:varCount(kind) return self.index[kind] end

--- the function return the type of the variable name
function SymbolTable:typeOf(name) return self:lookup(name)[1] end

--- the function return the kind of the variable name
function SymbolTable:kindOf(name) return self:lookup(name)[2] end

--- the function return the number of the variable name
function SymbolTable:indexOf(name) return self:lookup(name)[3] end

--- the function search the variable name in the table and return the details about it
--- need to check in what table search first
function SymbolTable:lookup(name)
    if self.classSymbols[name] ~= nil then
        return self.classSymbols[name]
    elseif self.subroutineSymbols[name] ~= nil then
        return self.subroutineSymbols[name]
    else
        return { nil, nil, nil }
    end
end
