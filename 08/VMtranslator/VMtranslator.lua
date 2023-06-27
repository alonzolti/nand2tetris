package.path = package.path .. ";" .. io.popen("cd"):read() .. arg[0]:sub(2, string.find(arg[0], '\\[^\\]*$')) .. "?.lua"
require "CodeWriter"
require "Parser"
require "VMconstant"

--- translate all vm files
function TranslateAll(infiles, outFile)
    if infiles ~= nil then
        local codeWriter = CodeWriter:new(outFile)
        --codeWriter:writeInit()
        for _, file in pairs(infiles) do
            if file:match(".vm") then
                Translate(file, codeWriter)
            end
        end
        codeWriter:closeFile()
    end
end

--going through all the commands in the file
function Translate(file, codeWriter)
    local parser = Parser:new(file)
    codeWriter:setFileName(file)
    while parser:hasMoreCommands() do
        parser:advance()
        GenCode(parser, codeWriter)
    end
end

--generating asm code from vm
function GenCode(parser, codeWriter)
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
        os.exit()
    end

    local files = {}
    local fileOutPath
    -- if it is a file
    if string.match(arg[1], '.vm') then
        files = { arg[1] }
        fileOutPath = arg[1]:gsub('.vm', '.asm')
        -- if it is a directory
    else
        files = Scandir(arg[1])
        fileOutPath = arg[1] .. '/' .. arg[1]:sub(string.find(arg[1], '\\[^\\]*$') + 1) .. '.asm'
    end
    TranslateAll(files, fileOutPath)
end

--find all the vm files in the directory
function Scandir(directory)
    local VMfiles = {}
    --for linux - 'ls -a "' .. directory .. '"'
    local pfile = io.popen('dir "' .. directory .. '" /b /a')
    if pfile == nil then
        error("directory isn't exist")
    end
    for filename in pfile:lines() do
        if string.match(filename, '.vm') then
            table.insert(VMfiles, directory .. '\\' .. filename)
        end
    end
    pfile:close()
    return VMfiles
end

main()
