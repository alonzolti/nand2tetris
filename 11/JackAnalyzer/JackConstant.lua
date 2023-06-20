-- Jack compiler constants
-- Token types
T_KEYWORD = 1
T_SYM = 2
T_NUM = 3
T_STR = 4
T_ID = 5
T_ERROR = 6

-- Keywords for token type T_KEYWORD
KW_CLASS = 'class'
KW_METHOD = 'method'
KW_FUNCTION = 'function'
KW_CONSTRUCTOR = 'constructor'
KW_INT = 'int'
KW_BOOLEAN = 'boolean'
KW_CHAR = 'char'
KW_VOID = 'void'
KW_VAR = 'var'
KW_STATIC = 'static'
KW_FIELD = 'field'
KW_LET = 'let'
KW_DO = 'do'
KW_IF = 'if'
KW_ELSE = 'else'
KW_WHILE = 'while'
KW_RETURN = 'return'
KW_TRUE = 'true'
KW_FALSE = 'false'
KW_NULL = 'null'
KW_THIS = 'this'
KW_NONE = ''
-- list of all the keywords
Keywords = {
    KW_CLASS, KW_METHOD, KW_FUNCTION, KW_CONSTRUCTOR, KW_INT, KW_BOOLEAN,
    KW_CHAR, KW_VOID, KW_VAR, KW_STATIC, KW_FIELD, KW_LET, KW_DO, KW_IF,
    KW_ELSE, KW_WHILE, KW_RETURN, KW_TRUE, KW_FALSE, KW_NULL, KW_THIS
}

-- list of all the symbols
Symbols = {
    "{", "}", "(", ")", "[", "]", ".", ",", ";", "+", "-", "*", "/", "&", "|",
    "<", ">", "=", "~"
}

-- Symbol kinds
SK_STATIC = 1
SK_FIELD = 2
SK_ARG = 3
SK_VAR = 4
SK_NONE = 5

-- Convert keywords to symbol kinds
KwdToKind = {}
KwdToKind[KW_STATIC] = SK_STATIC
KwdToKind[KW_FIELD] = SK_FIELD

-- VM Writer Support

--vm commands
CMD_ADD = 1
CMD_SUB = 2
CMD_NEG = 3
CMD_EQ = 4
CMD_GT = 5
CMD_LT = 6
CMD_AND = 7
CMD_OR = 8
CMD_NOT = 9
VmCmds = { 'add', 'sub', 'neg', 'eq', 'gt', 'lt', 'and', 'or', 'not' }

--segments
SE_CONST = 1
SE_ARG = 2
SE_LOCAL = 3
SE_STATIC = 4
SE_THIS = 5
SE_THAT = 6
SE_POINTER = 7
SE_TEMP = 8
SE_NONE = 9
-- list of  the segments
Segments = { 'constant', 'argument', 'local', 'static', 'this', 'that', 'pointer', 'temp' }

-- Temporary registers
TEMP_RETURN = 0 -- Use temp 0 for popping an unused return value
TEMP_ARRAY = 1  -- Use temp 1 for temporarily saving value to assign to array
