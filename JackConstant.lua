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

keywords = {
    KW_CLASS, KW_METHOD, KW_FUNCTION, KW_CONSTRUCTOR, KW_INT, KW_BOOLEAN,
    KW_CHAR, KW_VOID, KW_VAR, KW_STATIC, KW_FIELD, KW_LET, KW_DO, KW_IF,
    KW_ELSE, KW_WHILE, KW_RETURN, KW_TRUE, KW_FALSE, KW_NULL, KW_THIS
}

-- Symbols for token type T_SYM
symbols = {
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
kwd_to_kind = {}
kwd_to_kind[KW_STATIC] = SK_STATIC
kwd_to_kind[KW_FIELD] = SK_FIELD

-- VM Writer Support
vmCmds = {}
vmCmds['+'] = "add"
vmCmds['-'] = "sub"
vmCmds['*'] = "call Math.multiply 2"
vmCmds['/'] = "call Math.divide 2"
vmCmds["<"] = "lt"
vmCmds[">"] = "gt"
vmCmds["="] = "eq"
vmCmds["&"] = "and"
vmCmds["|"] = "or"

vmUnaryCmds = {}
vmUnaryCmds["-"] = "neg"
vmUnaryCmds["~"] = "not"

segments = {}
segments[SK_STATIC] = "static"
segments[SK_FIELD] = "this"
segments[SK_ARG] = "argument"
segments[SK_VAR] = "local"
--segments[None] = "ERROR"

-- Temporary registers
TEMP_RETURN = 0 -- Use temp 0 for popping an unused return value
TEMP_ARRAY = 1 -- Use temp 1 for temporarily saving value to assign to array
