require "JackConstant"

SymbolTable = {classSymbols, subroutineSymbols,symbols,index}

function SymbolTable:new()
    local t = {}
    setmetatable(t,SymbolTable)
    self.__index = self
    self.classSymbols = {}
    self.subroutineSymbols = {}
    self.symbols = {self.classSymbols,self.classSymbols,self.subroutineSymbols,self.subroutineSymbols}
    self.index = {0,0,0,0}
    return t
end

function SymbolTable:str()
    return self:symbolString('class',self.classSymbols).. self:symbolString('subroutine',self.subroutineSymbols)
end

function SymbolTable:symbolString(name,table)
    result = 'symbol table' .. name .. ':\n'
    for k,v in pairs(table) do
        result = result .. 'symbol name:'
    end
end

function SymbolTable:startSubroutine()
    self.subroutineSymbols = {}
    self.index[SK_VAR] = 0
    self.index[SK_ARG] = self.index[SK_VAR]
end

function SymbolTable:define(name,type,kind)
    self.symbols[kind][name] = {type,kind,self.index[kind]}
    self.index[kind] =self.index[kind]+ 1
end

function SymbolTable:varCount(kind)
    s = 0
    for k,v in pairs(self.symbols[kind]) do
        if k == kind then
            s = s + 1
        end
    end
    return s
end

function SymbolTable:typeOf(name)
    type,kind,index = self:lookup(name)
    return type
end

function SymbolTable:kindOf(name)
    type,kind,index = self:lookup(name)
    return kind
end


function SymbolTable:indexOf(name)
    type,kind,index = self:lookup(name)
    return index
end


function SymbolTable:lookup(name)
    for k,v in pairs(self.subroutineSymbols)do
        if k == name then
            return v[1],v[2],v[3]
        end
    end
    for k,v in pairs(self.classSymbols) do
        if k == name then
            return v[1],v[2],v[3]
        end
    end
    return nil,nil,nil
end