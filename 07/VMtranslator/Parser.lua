--Meta class
require(VMconstant)

Parser = {commands,cmdType = C_ERROR, arg1 = "",arg2=0}

commandType =     {'add':C_ARITHMETIC, 'sub':C_ARITHMETIC, 'neg':C_ARITHMETIC,
                     'eq' :C_ARITHMETIC, 'gt' :C_ARITHMETIC, 'lt' :C_ARITHMETIC,
                     'and':C_ARITHMETIC, 'or' :C_ARITHMETIC, 'not':C_ARITHMETIC}

nullary = ['add', 'sub', 'neg', 'eq', 'gt', 'lt', 'and', 'or', 'not']
unary = []
binary = ['push','pop']


--Derived class method new
function Parser:new (file)
self.commands = io.open(file,"r")

end


--Derived class method
function Parser:has_more_command()
return self.commands
end

function Parser:advance()
str = self.commands:read("*l")


end


function split(s)
t = {}
a = 0
for v in string.gmatch(s,"%a+")do
t[a] = v
a += 1
return t
end


