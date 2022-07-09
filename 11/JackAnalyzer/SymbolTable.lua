require "11/JackAnalyzer/JackConstant"

SymbolTable = {classSymbols = {}, subroutineSymbols = {}, index = {0,0,0,0}}

function SymbolTable:new()
    local t = {}
    setmetatable(t, SymbolTable)
    self.__index = self
    return t
end

function SymbolTable:startSubroutine()
    self.subroutineSymbols = {}
    self.index[SK_VAR] = 0
    self.index[SK_ARG] = 0
end

function SymbolTable:define(name, type, kind)
    if kind == SK_ARG or kind == SK_VAR then
        local a = self.index[kind]
        self.index[kind] = self.index[kind] + 1
        self.subroutineSymbols[name] = {type, kind, a}
    elseif kind == SK_STATIC or kind == SK_FIELD then
        local a = self.index[kind]
        self.index[kind] = self.index[kind] + 1
        self.classSymbols[name] = {type, kind, a}
    end
end

function SymbolTable:varCount(kind) return self.index[kind] end

function SymbolTable:typeOf(name) return self:lookup(name)[1] end

function SymbolTable:kindOf(name) return self:lookup(name)[2] end

function SymbolTable:indexOf(name) return self:lookup(name)[3] end

function SymbolTable:lookup(name)
    if self.classSymbols[name] ~= nil then
        return self.classSymbols[name]
    elseif self.subroutineSymbols[name] ~= nil then
        return self.subroutineSymbols[name]
    else
        return {nil, nil, nil}
    end
end
