package.path = package.path .. ";" .. io.popen("cd"):read() .. arg[0]:sub(2, string.find(arg[0], '\\[^\\]*$')) .. "?.lua"
require "CompilationEngine"

function main()
    if (arg[1] == nil or arg[2] ~= nil) then
        error("Wrong number of parameters")
    else
        for _, file in pairs(GetFiles(arg[1])) do
            CompilationEngine:new(file)
        end
    end
end

function GetFiles(path)
    if string.match(path, '.jack') then return { path } end
    return Scandir(path)
end

--find all the Jack files in the directory
function Scandir(directory)
    local JackFiles = {}
    local pfile = io.popen('dir "' .. directory .. '" /b /a')
    if pfile == nil then
        error("directory" .. directory .. " isn't exist\n")
    end
    for filename in pfile:lines() do
        if string.match(filename, '.jack') then
            table.insert(JackFiles, directory .. '\\' .. filename)
        end
    end
    pfile:close()
    return JackFiles
end

main()
