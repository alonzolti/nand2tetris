require "JackConstant"

SymbolTable = {classSymbols, subroutineSymbols,symbols,index}

function SymbolTable:new()
    local t = {}
    setmetatable(t,SymbolTable)
    self.__index = self
    t.classSymbols = {}
    t.subroutineSymbols = {}
    t.symbols = {}
    t:init()
    t.index = {0,0,0,0}
    return t
end

function SymbolTable:init()
    self.symbols = {self.classSymbols,self.classSymbols,self.subroutineSymbols,self.subroutineSymbols}
end

function SymbolTable:startSubroutine()
    self:init()
    self.subroutineSymbols = {}
    self.index[SK_VAR] = 0
    self.index[SK_ARG] = self.index[SK_VAR]
end

function SymbolTable:define(name,type,kind)
    self:init()
    self.symbols[kind][name] = {type,kind,self.index[kind]}
    self.index[kind] =self.index[kind]+ 1
end

function SymbolTable:varCount(kind)
    self:init()
    s = 0
    for k,v in pairs(self.symbols[kind]) do
        if k == kind then
            s = s + 1
        end
    end
    return s
end

function SymbolTable:typeOf(name)
    self:init()
    local t = self:lookup(name)
    return t[1]
end

function SymbolTable:kindOf(name)
    self:init()
    t = self:lookup(name)
    return t[2]
end


function SymbolTable:indexOf(name)
    self:init()
    t = self:lookup(name)
    return t[3]
end


function SymbolTable:lookup(name)
    --print(name)
    self:init()
    for k,v in pairs(self.subroutineSymbols)do
        --print(k)
        if k == name then
            return self.subroutineSymbols[k]
        end
    end
    for k,v in pairs(self.classSymbols) do
        if k == name then
            return self.classSymbols[k]
        end
    end
    return {nil,nil,nil}
end