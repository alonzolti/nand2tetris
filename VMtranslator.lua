require "CodeWriter"
require "Parser"
require "VMconstant"
VMTranslator = {}

function VMTranslator:new()
    local t = {}
    setmetatable(t, VMTranslator)
    self.__index = self
    return t
end

function VMTranslator:translateAll(infiles, outFile,dir)
    if infiles ~= nil then
        local codeWriter = CodeWriter:new(outFile)
        --codeWriter:writeInit()
        for _,file in pairs(infiles) do
            if file:match(".vm") then
                self:translate(dir..file, codeWriter)
            end
        end
        codeWriter:closeFile()
    end
end

function VMTranslator:translate(file, codeWriter)
    local parser = Parser:new(file)
    while parser:hasMoreCommands() do
        parser:advance()
        self:genCode(parser, codeWriter)
    end
end

function VMTranslator:genCode(parser, codeWriter)
    local cmd = parser:commandType()
    if cmd == C_ARITHMETIC then
        codeWriter:writeArithmetic(parser:argF())
    elseif cmd == C_PUSH then
        codeWriter:writePushPop(cmd, parser:argF(), parser:argS())
    elseif cmd == C_LABEL then
        codeWriter:writeLabel(parser:argF())
    elseif cmd == C_GOTO then
        codeWriter:writeGoto(parser:argF())
    elseif cmd == C_IF then
        codeWriter:writeIf(parser:argF())
    elseif cmd == C_FUNCTION then
        codeWriter:writeFunction(parser:argF(), parser:argS())
    elseif cmd == C_RETURN then
        codeWriter:writeReturn()
    elseif cmd == C_CALL then
        codeWriter:writeCall(parser:argF(), parser:argS())
    end
end

function main()
    if (arg[1] == nil or arg[2] ~= nil) then
        print("Wrong number of parameters")
    else
        local translator = VMTranslator:new()
        if string.match(arg[1], '.vm') then
            translator:translateAll({arg[1]}, arg[1]:gsub('.vm', 'asm'),'')
        else
            translator:translateAll(scandir(arg[1]), arg[1] .. '/' .. 'b.asm',arg[1]..'/')
        end
    end
end

function scandir(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "' .. directory .. '"')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end
main()
