CodeWriter = { outFile = nil, vmFile = '', labelNum = 0 }

function CodeWriter:new(file)
    local codeWriter = {}
    setmetatable(codeWriter, CodeWriter)
    self.__index = self
    codeWriter.vmFile = ''
    codeWriter.outFile = io.open(file, "w")
    return codeWriter
end

function CodeWriter:setFileName(file)
    self.vmFile = file:match("[^\\]*.vm$")
end

function CodeWriter:closeFile() self.outFile:close() end

function CodeWriter:writeInit()
    -- SP = 256
    self:aCommand('256')
    self:cCommand('D', 'A')
    self:compToReg(R_SP, 'D')
    -- call Sys.init
    self:writeCall("Sys.init", 0)
end

--- the function writes an arithmetic command in hack
function CodeWriter:writeArithmetic(command)
    if command == 'add' then
        self:binary('D+A')
    elseif command == 'sub' then
        self:binary('A-D')
    elseif command == 'neg' then
        self:unary('-D')
    elseif command == 'eq' then
        self:compare('JEQ')
    elseif command == 'gt' then
        self:compare('JGT')
    elseif command == 'lt' then
        self:compare('JLT')
    elseif command == 'and' then
        self:binary('D&A')
    elseif command == 'or' then
        self:binary('D|A')
    elseif command == 'not' then
        self:unary('!D')
    end
end

--- the function writes push and pop command in hack
function CodeWriter:writePushPop(cmd, seg, ind)
    if cmd == C_PUSH then
        self:push(seg, ind)
    elseif cmd == C_POP then
        self:pop(seg, ind)
    end
end

--- the function writeds push command in hack
--- there are four differnt push commands:
--- 1: constant
--- 2: memory segment
--- 3: TEMP or PTR
--- 4: STATIC
function CodeWriter:push(seg, index)
    if self:isConstSeg(seg) then
        self:valToStack(tostring(index))
    elseif self:isMemSeg(seg) then
        self:memToStack(self:asmMemSeg(seg), index)
    elseif self:isRegSeg(seg) then
        self:regToStack(seg, index)
    elseif self:isStaticSeg(seg) then
        self:staticToStack(index)
    end
    self:incSp()
end

--- the fucntion wrties pop command in hack
--- there are three differnt push commands:
--- 1: memory segment
--- 2: TEMP or PTR
--- 3: STATIC
function CodeWriter:pop(seg, index)
    self:decSp()
    if self:isMemSeg(seg) then
        self:stackToMem(self:asmMemSeg(seg), index)
    elseif self:isRegSeg(seg) then
        self:stackToReg(seg, index)
    elseif self:isStaticSeg(seg) then
        self:stackToStatic(index)
    end
end

--- the function write a label in hack
function CodeWriter:writeLabel(label)
    label = self.vmFile.. '.' .. label
    self:lCommand(label)
end

--- the function write the command GoTo in hack
function CodeWriter:writeGoto(label)
    label = self.vmFile.. '.' .. label
    -- A = label
    self:aCommand(label)
    -- 0;JMP
    self:cCommand(nil, '0', 'JMP')
end

--- the function write the command if-goto in hack
function CodeWriter:writeIf(label)
    label = self.vmFile.. '.' .. label
    -- D = *SP
    self:popToDest('D')
    -- A = label
    self:aCommand(label)
    -- D;JNE
    self:cCommand(nil, 'D', 'JNE')
end

--- the function write the command call in hack
--- to implement this command in hack, there are four steps:
--- 1. create a new label for the return address
--- 2. push the memory segments into the stack
--- 3. move the ARG pointer to the start of the argument
--- 4. move the LCL pointer to the start of the stack
--- 5. jump to the fucntion that was called
--- 6. write a label of the return address
function CodeWriter:writeCall(funcName, numArgs)
    -- push retAdd
    local retAdd = self:newLabel()
    self:push(S_CONST, retAdd)
    -- push LCL
    self:push(S_REG, R_LCL)
    -- push ARG
    self:push(S_REG, R_ARG)
    -- push THIS
    self:push(S_REG, R_THIS)
    -- push THAT
    self:push(S_REG, R_THAT)
    -- ARG = SP - numArgs - 5
    self:loadSeg(self:asmReg(R_SP), -numArgs - 5)
    self:compToReg(R_ARG, 'D')
    -- LCL = SP
    self:regToReg(R_LCL, R_SP)
    -- A = funcName
    self:aCommand(funcName)
    -- 0;JMP
    self:cCommand(nil, '0', 'JMP')
    -- (retAdd)
    self:lCommand(retAdd)
end

--- the function write the return command in hack
--- to implement this command, there are a few steps:
--- we do step number 1 before 2, in case that there aren't any arguments, and we don't want to override the return address
--- 1. save the return address in a register
--- 2. save the return value in ARG[0]
--- 3. recompute the memory segments before the calling to this function
--- 4. jump to the return address
function CodeWriter:writeReturn()
    -- R_FRAME = R_LCL
    self:regToReg(R_FRAME, R_LCL)
    -- A = 5
    self:aCommand('5')
    -- A = FRAME - 5
    self:cCommand('A', 'D-A')
    -- D = M
    self:cCommand('D', 'M')
    -- RET = *(FRAME - 5)
    self:compToReg(R_RET, 'D')
    -- *ARG = return value
    self:pop(S_ARG, 0)
    -- D = ARG
    self:regToDest('D', R_ARG)
    -- SP = ARG + 1
    self:compToReg(R_SP, 'D+1')
    -- THAT=*(FRAME-1)
    self:prevFrameToReg(R_THAT)
    -- THIS=*(FRAME-2)
    self:prevFrameToReg(R_THIS)
    -- ARG=*(FRAME-3)
    self:prevFrameToReg(R_ARG)
    -- LCL=*(FRAME-4)
    self:prevFrameToReg(R_LCL)
    -- A = retAdd
    self:regToDest('A', R_RET)
    -- goto retAdd
    self:cCommand(nil, '0', 'JMP')
end

function CodeWriter:prevFrameToReg(reg)
    -- D = FRAME
    self:regToDest('D', R_FRAME)
    -- D = FRAME - 1
    self:cCommand('D', 'D-1')
    -- FRAME = FRAME - 1
    self:compToReg(R_FRAME, 'D')
    -- A = FRAME - 1
    self:cCommand('A', 'D')
    -- D = *(FRAME - 1)
    self:cCommand('D', 'M')
    -- reg = D
    self:compToReg(reg, 'D')
end

--- the function write the function command in hack
--- there are two steps to this command:
--- 1. write the label of the function
--- 2. push numLocals times the number 0 to have enough space to the local segment
function CodeWriter:writeFunction(funcName, numLocals)
    self:lCommand(funcName)
    for i = 1, numLocals do
        self:push(S_CONST, 0)
    end
end

--- the function does the following operation: dest = *(SP-1)
--- which is the value in the top of the stack
function CodeWriter:popToDest(dest)
    self:decSp()
    self:stackToDest(dest)
end

--- check if the segment is memory segment
function CodeWriter:isMemSeg(seg)
    return seg == S_LCL or seg == S_ARG or seg == S_THIS or seg == S_THAT
end

function CodeWriter:isRegSeg(seg)
    return seg == S_REG or seg == S_TEMP or seg == S_PTR
end

--- the function check if the segment is the Static segment
function CodeWriter:isStaticSeg(seg)
    return seg == S_STATIC
end

--- the function check if the segment is the constant segment
function CodeWriter:isConstSeg(seg)
    return seg == S_CONST
end

function CodeWriter:unary(comp)
    self:popToDest('D')
    self:cCommand('D', comp)
    self:compToStack('D')
    self:incSp()
end

function CodeWriter:binary(comp)
    self:popToDest('D')
    self:popToDest('A')
    self:cCommand('D', comp)
    self:compToStack('D')
    self:incSp()
end

function CodeWriter:compare(jump)
    self:popToDest('D')
    self:popToDest('A')
    self:cCommand('D', 'A-D')
    local labelEq = self:jump('D', jump)
    self:compToStack('0')
    local labelNe = self:jump('0', 'JMP')
    self:lCommand(labelEq)
    self:compToStack('-1')
    self:lCommand(labelNe)
    self:incSp()
end

--- increase the stack pointer
function CodeWriter:incSp()
    -- A = SP
    self:aCommand('SP')
    -- *SP = *SP + 1
    self:cCommand('M', 'M+1')
end

--- decrease the stack pointer
function CodeWriter:decSp()
    -- A = SP
    self:aCommand('SP')
    -- *SP = *SP - 1
    self:cCommand('M', 'M-1')
end

--- load the stack pointer value
--- which means A = *SP
function CodeWriter:loadSp()
    -- A = SP
    self:aCommand('SP')
    -- A = M
    self:cCommand('A', 'M')
end

--- the function stores a value into the stack
function CodeWriter:valToStack(val)
    -- A = val
    self:aCommand(val)
    -- D = A
    self:cCommand('D', 'A')
    -- *SP = D
    self:compToStack('D')
end

-- the function stores a reg value into the stack
function CodeWriter:regToStack(seg, index)
    -- D = reg
    self:regToDest('D', self:regNum(seg, index))
    -- *SP = D
    self:compToStack('D')
end

-- the function stores a value from a memory segment into the stack
function CodeWriter:memToStack(seg, index)
    -- A = seg + index
    self:loadSeg(seg, index)
    -- D = *(seg + index)
    self:cCommand('D', 'M')
    -- *SP = *(seg + index)
    self:compToStack('D')
end

-- the function stores a static value into the stack
function CodeWriter:staticToStack(index)
    -- A = staticName
    self:aCommand(self:staticName(index))
    -- D = value
    self:cCommand('D', 'M')
    -- *SP = value
    self:compToStack('D')
end

-- the function stores a comp into the stack
function CodeWriter:compToStack(comp)
    -- A = *SP
    self:loadSp()
    -- *SP = comp
    self:cCommand('M', comp)
end

-- the function retrieve a value from the stack into a register
function CodeWriter:stackToReg(seg, index)
    self:stackToDest('D')
    self:compToReg(self:regNum(seg, index), 'D')
end

function CodeWriter:stackToMem(seg, index)
    self:loadSeg(seg, index)
    self:compToReg(R_COPY, 'D')
    self:stackToDest('D')
    self:regToDest('A', R_COPY)
    self:cCommand('M', 'D')
end

function CodeWriter:stackToStatic(index)
    self:stackToDest('D')
    self:aCommand(self:staticName(index))
    self:cCommand('M', 'D')
end

function CodeWriter:stackToDest(dest)
    self:loadSp()
    self:cCommand(dest, 'M')
end

--- load a segment + index into the A,D registers
function CodeWriter:loadSeg(seg, index)
    if tonumber(index) == 0 then
        self:loadSegNoIndex(seg)
    else
        self:loadSegIndex(seg, index)
    end
end

--- load a segment + index into the A,D registers
function CodeWriter:loadSegNoIndex(seg)
    self:aCommand(seg)
    self:cCommand('AD', 'M')
end

--- load a segment + index into the A,D registers
function CodeWriter:loadSegIndex(seg, index)
    local comp = 'D+A'
    if tonumber(index) < 0 then
        index = -index
        comp = 'A-D'
    end
    self:aCommand(tostring(index))
    self:cCommand('D', 'A')
    self:aCommand(seg)
    self:cCommand('A', 'M')
    self:cCommand('AD', comp)
end

function CodeWriter:regToDest(dest, reg)
    self:aCommand(self:asmReg(reg))
    self:cCommand(dest, 'M')
end

function CodeWriter:compToReg(reg, comp)
    self:aCommand(self:asmReg(reg))
    self:cCommand('M', comp)
end

function CodeWriter:regToReg(dest, src)
    self:regToDest('D', src)
    self:compToReg(dest, 'D')
end

function CodeWriter:regNum(seg, index)
    return self:regBase(seg) + index
end

function CodeWriter:regBase(seg)
    if seg == 'reg' then
        return R_R0
    elseif seg == 'pointer' then
        return R_PTR
    elseif seg == 'temp' then
        return R_TEMP
    end
end

--- return the name of the static variable
function CodeWriter:staticName(index)
    return self.vmFile .. '.' .. index
end

--- return the name of the segment in Hack
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

function CodeWriter:asmReg(regNum)
    return 'R' .. regNum
end

function CodeWriter:jump(comp, jump)
    local label = self:newLabel()
    self:aCommand(label)
    self:cCommand(nil, comp, jump)
    return label
end

--- the function create a new label name
function CodeWriter:newLabel()
    self.labelNum = self.labelNum + 1
    return 'LABEL' .. self.labelNum
end

--- A command - load the value of address into the A register
function CodeWriter:aCommand(address)
    self.outFile:write('@' .. address .. '\n')
    --io.write('@' .. address .. '\n')
end

--- C command - load the comp into dest and jump into the A line if the condition(jump) is true
function CodeWriter:cCommand(dest, comp, jump)
    if dest ~= nil then
        self.outFile:write(dest .. '=')
        --io.write(dest .. '=')
    end
    self.outFile:write(comp)
    --io.write(comp)
    if jump ~= nil then
        --io.write(';'.. jump)
        self.outFile:write(';' .. jump)
    end
    self.outFile:write('\n')
    --io.write('\n')
end

--- l command - write a label in hack. like this: (nameLabel)
function CodeWriter:lCommand(label)
    self.outFile:write('(' .. label .. ')\n')
    --io.write('(' .. label .. ')\n' )
end
