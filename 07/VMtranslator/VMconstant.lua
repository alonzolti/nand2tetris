-- VM translator constants

NUM = 1
ID = 2
ERROR = 3


-- Command types
C_ARITHMETIC = 1
C_PUSH = 2
C_POP = 3
C_LABEL = 4
C_GOTO = 5
C_IF = 6
C_FUNCTION = 7
C_RETURN = 8
C_CALL = 9
C_ERROR = 10

-- Segment names
S_LCL = 'local'
S_ARG = 'argument'
S_THIS = 'this'
S_THAT = 'that'
S_PTR = 'pointer'
S_TEMP = 'temp'
S_CONST = 'constant'
S_STATIC = 'static'
S_REG = 'reg'

-- Registers
R_SP = 0
R_LCL = 1
R_ARG = 2
R_THIS = 3
R_PTR = 3
R_THAT = 4
R_TEMP = 5
R_FRAME = 13
R_RET = 14
R_COPY = 15
R_R0 = R_SP
R_R1 = R_LCL
R_R2 = R_ARG
R_R3 = R_THIS
R_R4 = R_THAT
R_R5 = R_TEMP
R_R6 = 6
R_R7 = 7
R_R8 = 8
R_R9 = 9
R_R10 = 10
R_R11 = 11
R_R12 = 12
R_R13 = R_FRAME
R_R14 = R_RET
R_R15 = R_COPY
