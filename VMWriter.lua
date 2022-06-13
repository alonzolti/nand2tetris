VMWriter = {outfile}

function VMWriter:new(file)
    t = {}
    setmetatable(t, VMWriter)
    self.__index = self
    return t
end

function VMWriter:openOut(file)
    self.outfile = io.open(string.gsub(file, '.jack', '.vm'), 'w')
end

function VMWriter:closeOut() self.outfile:close() end

function VMWriter:writePush(segment, index)
    self:writeVmCmd('push', segment, index)
end

function VMWriter:writePop(segment, index) self:writeVmCmd('pop', segment, index) end

function VMWriter:writeArithmetic(op) self:writeVmCmd(op) end

function VMWriter:writeLabel(label) self:writeVmCmd('label', label) end

function VMWriter:writeGoto(label) self:writeVmCmd("goto", label) end

function VMWriter:writeIf(label) self:writeVmCmd('if-goto', label) end

function VMWriter:writeCall(name, numArgs) self:writeVmCmd('call', name, numArgs) end

function VMWriter:writeFunction(name, numLocals)
    self:writeVmCmd('function', name, numLocals)
end

function VMWriter:writeReturn() self:writeVmCmd('return') end

function VMWriter:writeVmCmd(cmd, arg1, arg2)
    if arg1 == nil then arg1 = '' end
    if arg2 == nil then arg2 = '' end
    self.outfile:write(cmd .. ' ' .. arg1 .. ' ' .. arg2 .. '\n')
end

function VMWriter:pushConst(val) self:writePush('constant', val) end

function VMWriter:pushArg(argNum) self:writePush('pointer', 0) end

function VMWriter:pushThisPtr() self:writePush('pointer', 0) end

function VMWriter:popThisPtr() self:writePop('pointer', 0) end

function VMWriter:popThatPtr() self:writePop('pointer', 1) end

function VMWriter:pushThat() self:writePush('that', 0) end

function VMWriter:popThat() self:writePop('that', 0) end
function VMWriter:pushTemp(tempNum) self:writePush('temp', tempNum) end

function VMWriter:popTemp(tempNum) self:writePop('temp', tempNum) end
