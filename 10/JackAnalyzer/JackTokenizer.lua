require "JackConstant"

JackTokenizer = {lines , tokens,tokenType,val,outfile}

function JackTokenizer:new(file)
	local cfile = io.open(file,'r')
	self.lines = cfile:read("*a")
	tokens = self.tokenize(self.lines)
	self.tokenType = T_ERROR
	self.val = 0
end

function JackTokenizer:openOutFile(file)
	self.outfile = io.open(string.gsub(file,".jack","T.xml"),'w')
	self.outfile:write("<tokens>\n")
end

function JackTokenizer:closeOutFile()
	self.outfile:write("</tokens>")
	self.outfile:close()
end

function JackTokenizer:hasMoreToken()
	return self.tokens[1] == nil
end

function JackTokenizer:advance()
	if self:hasMoreToken() then
		self.tokenType,self.val = table.remove(self.tokens,1)
	else 
		self.tokenType = T_ERROR
		self.val = 0
	end
	self.writeXml()
end

function JackTokenizer:peek()
	if self.hasMoreToken() then
		return self.tokens[1]
	else
		return {T_ERROR,0}
	end
end

function JackTokenizer:writeXml()
	local tok = self.tokenType
	local val = self.val
	self.writeStartTag(tokensTypes[tok])
	if tok == T_KEYWORD then
		self.outfile:write(self.keyWord())
	elseif tok == T_SYM then
		self.outfile:write(escape(self.symbol()))
	elseif tok == T_NUM then
		self.outfile:write(self.intVal())
	elseif tok == T_STR then
		self.outfile:write(self.stringVal())
	elseif tok == T_ID then
		self.outfile:write(self.identifier())
	elseif tok == T_ERROR then
		self.outfile:write("<<ERRORR>>")
	end
	self.writeEndTag(tokensTypes[tok])
end

function JackTokenizer:writeStartTag(token)
	self.outfile:write("<" + token + ">")
end

function JackTokenizer:writeEndTag(token)
	self.outfile:write("</"+token+">\n")
end

function JackTokenizer:tokenType()
	return self.tokenType
end

function JackTokenizer:keyWord()
	return self.val
end

function JackTokenizer:symbol()
	return self.val
end

function JackTokenizer:identifier()
	return self.val
end

function JackTokenizer:intVal()
	return self.val
end

function JackTokenizer:stringVal()
	return self.val
end

function JackTokenizer:tokenize(lines)
--	return {self:token(word) for word in self do split(self:removeComments(lines)) end}
end

function JackTokenizer:removeComments(line)
--	return string.gmatch(line,'//[^\n]*\n|/\*(.*?)\*/')
end


keyWordRe = table.concat(keywords,"|")
t = {}
symbols:gsub(".",function(c) table.insert(t,c)end)
symRe = table.concat(t,"|")
--numRe= '\d+'
--strRe = '"[^"\n]*"'
--idRe = '[\w\-]+'
rules =  keyWordRe + '|' + symRe + '|' + numRe + '|' + strRe + '|' + idRe


function JackTokenizer:split(line)
	return string.gmatch(line, rules)
end


function JackTokenizer:token(word)
	if self.isKeyWord(word) then
		return {T_KEYWORD,word}
	elseif self.isSym(word) then
		return {T_SYM,word}
	elseif self.isNum(word) then
		return {T_NUM,word}
	elseif self.isStr(word) then
		return {T_STR, word}
	elseif self.isId(word) then
		return {T_ID, word}
	else 
		return {T_ERROR,word}
	end
end

function JackTokenizer:isKeyWord(word)
	return string:match(word,keyWordRe) ~= nil
end

function JackTokenizer:isSym(word)
	return string:match(word, symRe) ~= nil
end

function JackTokenizer:isNum(word)
	return string:match(word, numRe) ~=nil
end

function JackTokenizer:isStr(word)
	return string:match(word, strRe) ~= nil
end

function JackTokenizer:isId(word)
	return string:match(word, idRe) ~= nil
end



	