require "CompilationEngine"

function main()
    if (arg[1] == nil or arg[2] ~= nil) then
        print("Wrong number of parameters")
    else
        for p, v in pairs(scandir(arg[1])) do 
            if string.match(v,'.jack') then
                CompilationEngine:new(arg[1]..'/'..v) end
            end
    end
end

function getFiles(path)
    if string.match(path, '.jack') then return {path} end
    return scandir(path)
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
