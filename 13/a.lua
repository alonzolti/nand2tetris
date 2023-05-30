function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

os.exit()
print(io.popen("cd"):read())
