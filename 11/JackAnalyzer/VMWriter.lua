--- the class responsible of writing the vm file.
VMWriter = { outfile = nil }
--- constractor
function VMWriter:new()
    local VmWriter = {}
    setmetatable(VmWriter, VMWriter)
    self.__index = self
    return VmWriter
end

--- open file for writing
function VMWriter:openOut(file)
    self.outfile = io.open(string.gsub(file, '.jack', '.vm'), 'w')
end

--- close outfile
function VMWriter:closeOut() self.outfile:close() end

--- the function writes a push command
function VMWriter:writePush(segment, index)
    self:writeCommand("push", Segments[segment], index)
end

--- the function writes a pop command
function VMWriter:writePop(segment, index)
    self:writeCommand("pop", Segments[segment], index)
end

--- the function writes an arithmetic command
function VMWriter:writeArithmetic(command)
    self:writeCommand(VmCmds[command], '', '')
end

--- the function writes a label command
function VMWriter:writeLabel(label) self:writeCommand("label", label, "") end

--- the function writes a goto command
function VMWriter:writeGoto(label) self:writeCommand("goto", label, '') end

--- the function writes a if-goto command
function VMWriter:writeIf(label) self:writeCommand("if-goto", label, "") end

--- the function writes a call command
function VMWriter:writeCall(name, args) self:writeCommand("call", name, args) end

--- the function writes a function command
function VMWriter:writeFunction(name, locals)
    self:writeCommand("function", name, locals)
end

--- the function writes a return command
function VMWriter:writeReturn() self:writeCommand("return", '', '') end

--- the function writes a command that in the formation of: cmd arg1 arg2 to the vm file
function VMWriter:writeCommand(cmd, arg1, arg2)
    self.outfile:write(cmd .. ' ' .. arg1 .. ' ' .. arg2 .. '\n')
end
