VMWriter = {outfile}

function VMWriter:new()
    t = {}
    setmetatable(t, VMWriter)
    self.__index = self
    return t
end
-- open file for writing
function VMWriter:openOut(file)
    self.outfile = io.open(string.gsub(file, '.jack', '.vm'), 'w')
end
-- close outfile
function VMWriter:closeOut() self.outfile:close() end

function VMWriter:writePush(segment, index)
    self:writeCommand("push", segments[segment], index)
end

function VMWriter:writePop(segment, index)
    self:writeCommand("pop", segments[segment], index)
end

function VMWriter:writeArithmetic(command)
    self:writeCommand(vmCmds[command], '', '')
end

function VMWriter:writeLabel(label) self:writeCommand("label", label, "") end

function VMWriter:writeGoto(label) self:writeCommand("goto", label, '') end

function VMWriter:writeIf(label) self:writeCommand("if-goto", label, "") end

function VMWriter:writeCall(name, args) self:writeCommand("call", name, args) end

function VMWriter:writeFunction(name, locals)
    self:writeCommand("function", name, locals)
end

function VMWriter:writeReturn() self:writeCommand("return", '', '') end

function VMWriter:writeCommand(cmd, arg1, arg2)
    --if cmd == 'or' then error() end
    self.outfile:write(cmd .. ' ' .. arg1 .. ' ' .. arg2 .. '\n')
end
