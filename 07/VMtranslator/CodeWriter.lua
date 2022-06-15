CodeWriter = {outFile, vmFile, labelNum}

function CodeWriter:new(file)
    t = {}
    setmetatable(t, CodeWriter)
    t.outFile = io:open(file, 'w')
    t.vmFile = ''
    t.labelNum = 0
end

function CodeWriter:closeOut() self.outFile:close() end

function CodeWriter:writeInit()
    self:aCommand('256')
    self:cCommand('D', 'A')
    self:compToReg(R_SP, 'D')
    self:writeCall("Sys,init", 0)
end

function CodeWriter:writeArithmetic(command)
    if command == 'add' then
        self:binary('D+A')
    elseif command == 'sub' then
        self:binary('A-D')
    elseif command == 'neg' then
        self:unary('-D')
    elseif command == 'eg' then
        self:compare('JEQ')
    elseif command == 'gt' then
        self:compare('JGT')
    elseif command == 'lt' then
        self:compare("JLT")
    elseif command == 'and' then
        self:binary('D&A')
    elseif command == 'or' then
        self:binary('D|A')
    elseif command == 'not' then
        self:unary('!D')
    end
end

function CodeWriter:writePushPop(command, seg, index)
    if command == C_PUSH then
        self:push(seg, index)
    elseif command == C_POP then
        self:pop(seg, index)
    end
end

function CodeWriter:writeLabel(label) self:lCommand(label) end

function CodeWriter:writeGoto(label)
    self:aCommand(label)
    self:cCommand('', '0', 'JMP')
end

function CodeWriter:writeIf(label)
    self:popToDest('D')
    self:aCommand(label)
    self:cCommand('', 'D', 'JNE')
end

function CodeWriter:writeCall(functionName, numArgs)
    local returnAddress = self:newLabel()
    self:push(S_CONST, returnAddress)
    self:push(S_REG, R_LCL)
    self:push(S_REG, R_ARG)
    self:push(S_REG, R_THIS)
    self:push(S_REG, R_THAT)
    self:loadSpOffest(-numArgs - 5)
    self:compToReg(R_ARG, 'D')
    self:regToReg(R_LCL, R_SP)
    self:aCommand(functionName)
    self:cCommand('', '0', 'JMP')
    self:lCommand(returnAddress)
end

function CodeWriter:writeReturn()
    self:regToReg(R_FRAME, R_LCL)
    self:aCommand('5')
    self:cCommand('A', 'D-A')
    self:cCommand('D', 'M')
    self:compToReg(R_RET, 'D')
    self:pop(S_ARG, 0)
    self:regToDest('D', R_ARG)
    self:compToReg(R_SP, 'D+1')
    self:prevFrameToReg(R_THAT)
    self:prevFrameToReg(R_THIS)
    self:prevFrameToReg(R_ARG)
    self:prevFrameToReg(R_LCL)
    self:regToDest('A', R_RET)
    self:cCommand('', '0', 'JMP')
end

function CodeWriter:prevFrameToReg(reg)
    self:regToDest('D', R_FRAME)
    self:cCommand('D', 'D-1')
    self:compToReg(R_FRAME, 'D')
    self:cCommand('A', 'D')
    self:cCommand('D', 'M')
    self:compToReg(reg, 'D')
end

function CodeWriter:writeFunction(functionName, numLocals)
    self:lCommand(functionName)
    for i = 1, numLocals, 1 do self:push(S_CONST, 0) end
end

function CodeWriter:push(seg, index)
    if self:isConstSeg(seg) then
        self:valToStack(index)
    elseif self:isMemSeg(seg) then
        self:memToStack(self:asmMemSeg(seg), index)
    elseif self:isRegSeg(seg) then
        self:regToStack(seg, index)
    elseif self:isStaticSeg(seg) then
        self:staticToStack(seg, index)
    end
end

function CodeWriter:pop(seg, index)
    self:decSp()
    if self:isMemSeg(seg) then
        self:stackToMem(self:asmMemSeg(seg), index)
    elseif self:isRegSeg(seg) then
        self:stackToReg(seg, index)
    elseif self:isStaticSeg(seg) then
        self:stackToStatic(seg, index)
    end
end

function CodeWriter:popToDest(dest)
    self:decSp()
    self:stackToDest(dest)
end

function CodeWriter:isMemSeg(seg)
    return seg == S_LCL or seg == S_ARG or seg == S_THIS or seg == S_THAT
end

function CodeWriter:isRegSeg(seg)
    return seg == S_REG or seg == S_PTR or seg == S_TEMP
end

function CodeWriter:isStaticSeg(seg) return seg == S_STATIC end

function CodeWriter:isconstSeg(seg) return seg == S_CONST end

function CodeWriter:unary(comp)
    self:decSp()
    self:stackToDest('D')
    self:cCommand('D', comp)
    self:compToStack('D')
    self:incSp()
end

function CodeWriter:binary(comp)
    self:decSp()
    self:stackToDest('D')
    self:decSp()
    self:stackToDest('A')
    self:cCommand('D', comp)
    self:compToStack('D')
    self:incSp()
end

function CodeWriter:compare(jump)
    self:decSp()
    self:stackToDest('D')
    self:decSp()
    self:stackToDest('A')
    self:cCommand('D', 'A-D')
    local labelEq = self:jump('D', jump)
    self:compToStack('0')
    local labelNe = self:jump('0', 'JMP')
    self:lCommand(labelEq)
    self:compToStack('-1')
    self:lCommand(labelNe)
    self:incSp()
end

function CodeWriter:incSp()
    self:aCommand('SP')
    self:cCommand('M', 'M+1')
end

function CodeWriter:decSp()
    self:aCommand('SP')
    self:cCommand('M', 'M-1')
end

function CodeWriter:loadSp()
    self:aCommand('SP')
    self:cCommand('A', 'M')
end

function CodeWriter:valToStack(val)
    self:aCommand(val)
    self:cCommand('D', 'A')
    self:compToStack('D')
end

function CodeWriter:regToStack(seg, index)
    self:regToDest('D', self:regNum(seg, index))
    self:compToStack('D')
end

function CodeWriter:memToStack(seg, index, indir)
    self:loadSeg(seg, index, indir)
    self:cCommand('D', 'M')
    self:compToStack('D')
end

function CodeWriter:staticToStack(seg, index)
    self:aCommand(self:staticName(index))
    self:cCommand('D', 'M')
    self:compToStack('D')
end

function CodeWriter:compToStack(comp)
    self:loadSp()
    self:cCommand('M', comp)
end

function CodeWriter:stackToReg(seg, index)
    self:stackToDest('D')
    self:compToReg(self:regNum(seg, index), 'D')
end

function CodeWriter:stackToMem(seg, index, indir)
    self:loadSeg(seg, index, indir)
    self:compToReg(R_COPY, 'D')
    self:stackToDest('D')
    self:regToDest('A', R_COPY)
    self:cCommand('M', 'D')
end

function CodeWriter:stackToStatic(seg, index)
    self:stackToDest('D')
    self:aCommand(self:staticName(index))
    self:cCommand('M', 'D')
end

function CodeWriter:stackToDest(dest)
    self:loadSp()
    self:cCommand(dest, 'M')
end

function CodeWriter:loadSpOffest(offest) self:loadSeg(self:asmReg(R_SP), offest) end

function CodeWriter:loadSeg(seg, index, indir)
    if index == 0 then
        self:loadSegNoIndex(seg, indir)
    else
        self:loadSegIndex(seg, index, indir)
    end
end

function CodeWriter:loadSegNoIndex(seg, indir)
    self:aCommand(seg)
    if indir then self:indir('AD') end
end

function CodeWriter:loadSegIndex(seg, index, indir)
    local comp = 'D+A'
    if index < 0 then
        index = -index
        comp = 'A-D'
    end

    self:aCommand(index)
    self:cCommand('D', 'A')
    self:aCommand(seg)
    if indir then self:indir() end
    self:cCommand('AD', comp)
end

function CodeWriter:regToDest(dest, reg)
    self:aCommand(self:asmReg(reg))
    self:ccommand(dest, 'M')
end

function CodeWriter:compToReg(reg, comp)
    self:aCommand(self:asmRe(reg))
    self:ccommand('M', comp)
end

function CodeWriter:regToReg(dest, src)
    self:regToDest('D', src)
    self:compToReg(dest, 'D')
end

function CodeWriter:indir(dest) self:cCommand(dest, 'M') end

function CodeWriter:regNum(seg, index) return self:regBase(seg) + index end

function CodeWriter:regBase(seg)
    if seg == 'reg' then
        return R_R0
    elseif seg == 'pointer' then
        return R_PTR
    elseif seg == 'temp' then
        return R_TEMP
    end
end

function CodeWriter:staticName(index) return self.vmFile .. '.' .. index end

function CodeWriter:asmMemSeg(seg)
    if seg == S_LCL then
        return 'LCL'
    elseif seg == S_ARG then
        return 'ARG'
    elseif seg == S_THIS then
        return 'THIS'
    elseif seg == S_THAT then
        return 'THAT'
    end
end

function CodeWriter:asmReg(regnum) return 'R' .. regnum end

function CodeWriter:jump(comp, jump)
    local label = self:newLabel()
    self:aCommand(label)
    self:cCommand(nil, comp, jump)
    return label
end

function CodeWriter:aCommand(address) self.outFile:write('@' .. address .. '\n') end

function CodeWriter:cCommand(dest, comp, jump)
    if dest ~= nil then self.outFile:write(dest .. '=') end
    self.outFile:write(comp)
    if jump ~= nil then self.outFile:write(';' .. jump) end
    self.outFile:write('\n')
end

function CodeWriter:lCommand(label) self.outFile:write('(' .. label .. ')\n') end
