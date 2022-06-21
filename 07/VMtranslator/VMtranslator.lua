require "CodeWriter"
require "Parser"
require "VMconstant"
VMTranslator = {outFile}

function VMTranslator:new(infiles, outfile)
    local t = {}
    setmetatable(t, VMTranslator)
    t.outFile = outfile
    return t
end

function VMTranslator:translateAll()
    if infiles ~= nil then
        local codeWriter = CodeWriter:new(outFile)
        codeWriter:writeInit()
        for file in infiles do
            if file:match(".vm") then
                self:translate(file, codeWriter)
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

function VMTranslator:getCode(parser, codeWriter)
    local cmd = parser:commandType()
    if cmd == C_ARITHMETIC then
        codeWriter:writeArithmetic(parser:arg1())
    elseif cmd == C_PUSH then
        codeWriter:writePushPop(cmd, parser:arg1(), parser:arg2())
    elseif cmd == C_LABEL then
        codeWriter:writeLabel(parser:arg1())
    elseif cmd == C_GOTO then
        codeWriter:writeGoto(parser:arg1())
    elseif cmd == C_IF then
        codeWriter:writeIf(parser:arg1())
    elseif cmd == C_FUNCTION then
        codeWriter:writeFunction(parser:arg1(), parser:arg2())
    elseif cmd == C_RETURN then
        codeWriter:writeReturn()
    elseif cmd == C_CALL then
        codeWriter:writeCall(parser:arg1(), parser:arg2())
    end
end

function main()
    if (arg[1] == nil or arg[2] ~= nil) then
        print("Wrong number of parameters")
    else
        local t = VMTranslator:new()
        print(arg[1])
        if string.match(arg[1], '.vm') then
            t:translateAll({arg[1]}, arg[1]:gsub('.vm', 'asm'))
        else
            t:translateAll(scandir(arg[1]), arg[1] .. '/' .. arg[1] .. '.asm')
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
