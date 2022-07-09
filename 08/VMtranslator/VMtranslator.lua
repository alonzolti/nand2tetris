require "08\\VMtranslator\\CodeWriter"
require "08\\VMtranslator\\Parser"
require "08\\VMtranslator\\VMconstant"
VMTranslator = {}

function VMTranslator:new()
    local t = {}
    setmetatable(t, VMTranslator)
    self.__index = self
    return t
end

--translate all vm files
function VMTranslator:translateAll(infiles, outFile)
    if infiles ~= nil then
        local codeWriter = CodeWriter:new(outFile) 
        codeWriter:writeInit()
        for _, file in pairs(infiles) do
            if file:match(".vm") then
                self:translate(file, codeWriter)
            end
        end
        codeWriter:closeFile()
    end
end

--going through all the commands in the file
function VMTranslator:translate(file, codeWriter)
    local parser = Parser:new(file)
    codeWriter:setFileName(file)
    while parser:hasMoreCommands() do
        parser:advance()
        self:genCode(parser, codeWriter)
    end
end

--generating asm code from vm
function VMTranslator:genCode(parser, codeWriter)
    local cmd = parser:commandType()
    if cmd == C_ARITHMETIC then
        codeWriter:writeArithmetic(parser:argF())
    elseif cmd == C_PUSH or cmd == C_POP then
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
        local t = {}
        local fileOutPath
        if string.match(arg[1], '.vm') then -- if it is a file
            t = {arg[1]}
            fileOutPath = arg[1]:gsub('.vm','.asm')
        else -- if it is a directory
            t = Scandir(arg[1])
            fileOutPath = arg[1] .. '/' .. arg[1]:sub(string.find(arg[1],'\\[^\\]*$')+1)..'.asm'
        end
        local translator = VMTranslator:new()
        translator:translateAll(t,fileOutPath)
    end
end

--find all the vm files in the directory
function Scandir(directory)
    local i, t, popen = 0, {}, io.popen
    --for linux - 'ls -a "' .. directory .. '"'    
    local pfile = popen('dir "'..directory..'" /b /a')
    if pfile == nil then
        error("directory isn't exist")
    end
    for filename in pfile:lines() do 
        if string.match(filename, '.vm') then
            i = i + 1
            t[i] = directory.. '\\' .. filename
        end
    end    
    pfile:close()
    return t
end
main()