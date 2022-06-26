CodeWriter = {outFile = nil, vmFile = '', labelNum = 0, arthJumpFlag = 0}

function CodeWriter:new(file)
    local t = {}
    setmetatable(t, CodeWriter)
    self.__index = self
    t.outFile = io.open(file, "w")
    return t
end

function CodeWriter:closeFile() self.outFile:close() end

function CodeWriter:writeArithmetic(command)
    if command == 'add' then
        self:arithmeticTemplate1()
        self.outFile:write("M=M+D\n")
    elseif command == 'sub' then
        self:arithmeticTemplate1()
        self.outFile:write("M=M-D\n")
    elseif command == 'neg' then
        self.outFile:write("D=0\n@SP\nA=M-1\nM=D-M\n")
    elseif command == 'eq' then
        self:arithmeticTemplate2("JNE")
        self.arthJumpFlag = self.arthJumpFlag + 1
    elseif command == 'gt' then
        self:arithmeticTemplate2("JLE")
        self.arthJumpFlag = self.arthJumpFlag + 1
    elseif command == 'lt' then
        self:arithmeticTemplate2("JGE")
        self.arthJumpFlag = self.arthJumpFlag + 1
    elseif command == 'and' then
        self:arithmeticTemplate1()
        self.outFile:write("M=M&D\n")
    elseif command == 'or' then
        self:arithmeticTemplate1()
        self.outFile:write("M=M|D\n")
    elseif command == 'not' then
        self.outFile:write("@SP\nA=M-1\nM=!M\n")
    end
end

function CodeWriter:writePushPop(cmd, seg, ind)
    if cmd == C_PUSH then
        if seg == "constant" then
            self.outFile:write("@" .. ind .. '\n' ..
                                   "D=A\n@SP\nA=M\nM=D\n@SP\nM=M+1\n")
        elseif seg == "local" then
            self:pushTemplate1("LCL", ind, false)
        elseif seg == "argument" then
            self:pushTemplate1("ARG", ind, false)
        elseif seg == "this" then
            self:pushTemplate1("THIS", ind, false)
        elseif seg == "that" then
            self:pushTemplate1("THAT", ind, false)
        elseif seg == "temp" then
            self:pushTemplate1("R5", tonumber(ind) + 5, false)
        elseif seg == "pointer" and ind == '0' then
            self:pushTemplate1("THIS", ind, true)
        elseif seg == "pointer" and ind == '1' then
            self:pushTemplate1("THAT", ind, true)
        elseif seg == "static" then
            self:pushTemplate1(16 + tonumber(ind), ind, true)
        end
    elseif cmd == C_POP then
        if seg == "local" then
            self:popTemplate1("LCL", ind, false)
        elseif seg == "argument" then
            self:popTemplate1("ARG", ind, false)
        elseif seg == "this" then
            self:popTemplate1("THIS", ind, false)
        elseif seg == "that" then
            self:popTemplate1("THAT", ind, false)
        elseif seg == "temp" then
            self:popTemplate1("R5", tonumber(ind) + 5, false)
        elseif seg == 'pointer' and ind == '0' then
            self:popTemplate1("THIS", ind, true)
        elseif seg == 'pointer' and ind == '1' then
            self:popTemplate1("THAT", ind, true)
        elseif seg == "static" then
            self:popTemplate1(16 + tonumber(ind), ind, true)
        end
    end
end


function CodeWriter:arithmeticTemplate1()
    self.outFile:write("@SP\nAM=M-1\nD=M\nA=A-1\n")
end

function CodeWriter:arithmeticTemplate2(type)
    self.outFile:write("@SP\nAM=M-1\nD=M\nA=A-1\nD=M-D\n@FALSE".. self.arthJumpFlag.. "\nD;".. type.. "\n@SP\nA=M-1\nM=-1\n@CONTINUE" .. self.arthJumpFlag.. "\n0;JMP\n(FALSE" .. self.arthJumpFlag .. ")\n@SP\nA=M-1\nM=0\n(CONTINUE" ..self.arthJumpFlag .. ")\n")
end

function CodeWriter:pushTemplate1(seg,ind,isDirect)
    local noPointerCode = ''
    if isDirect == false then
        noPointerCode = "@"..ind..'\nA=D+A\nD=M\n'
    end
    self.outFile:write("@"..seg..'\nD=M\n'..noPointerCode..'@SP\nA=M\nM=D\n@SP\nM=M+1\n')
end

function CodeWriter:popTemplate1(seg,ind,isDirect)
    local noPointerCode = 'D=A\n'
    if isDirect == false then
        noPointerCode = "D=M\n@"..ind.."\nD=D+A\n"
    end
    self.outFile:write("@"..seg..'\n'..noPointerCode.."@R13\nM=D\n@SP\nAM=M-1\nD=M\n@R13\nA=M\nM=D\n")
end