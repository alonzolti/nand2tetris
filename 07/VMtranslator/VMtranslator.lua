require "Parser"
require "CodeWriter"





function main()

	if(arg[1] == nil or arg[2] ~=nil)then
		print("Wrong number of parameters")
	else
		if(arg[1]:sub(-3)!=".vm")then
			print("argument should be a VM file")
		else
			
		end
	end
end

main()
