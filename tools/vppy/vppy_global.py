""" vpp and extended, in Python 
----------------------------------------------------------------------
 Author: Frank Wang

----------------------------------------------------------------------
 This is free and unencumbered software released into the public domain.

 Anyone is free to copy, modify, publish, use, compile, sell, or
 distribute this software, either in source code form or as a compiled
 binary, for any purpose, commercial or non-commercial, and by any
 means.

 In jurisdictions that recognize copyright laws, the author or authors
 of this software dedicate any and all copyright interest in the
 software to the public domain. We make this dedication for the benefit
 of the public at large and to the detriment of our heirs and
 successors. We intend this dedication to be an overt act of
 relinquishment in perpetuity of all present and future rights to this
 software under copyright law.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 For more information, please refer to <http://unlicense.org/> 
----------------------------------------------------------------------
"""
INT_CONST = 'INT_CONST'
REAL_CONST = 'REAL_CONST'
STR_CONST = 'STR_CONST'
PLUS = 'PLUS'
MINUS = 'MINUS'
MUL = 'MUL'
DIV = 'DIV'
EQ = 'EQ'
NEQ = 'NEQ'
GT = 'GT'
LT = 'LT'
LE = 'LE'
GE = 'GE'
LPAREN = 'LPAREN'
RPAREN = 'RPAREN'
LBRACKET = 'LBRACKET'
RBRACKET = 'RBRACKET'
ID = 'ID'
FOR = 'FOR'
IF = 'IF'
ELSE = 'ELSE'
ENDFOR = 'ENDFOR'
ENDIF = 'ENDIF'
SWITCH = 'SWITCH'
CASE = 'CASE'
ENDSWITCH = 'EDNSWITCH'
DCOLON = 'DCOLON'
EOF = 'EOF'
LET = 'LET'
SPACE = 'SPACE'
BTICKDCOLUN = 'BTICKDCOLON'
BTICK = 'BTICK'
V_TEXT = 'V_TEXT'
INCR = 'INCR'
DECR = 'DECR'
NEWLINE = 'NEWLINE'
COMMA = 'COMMA'
ASSIGN = 'ASSIGN'
IN    = 'IN'
SEMICOL = 'SEMICOL'
COMMENT = 'COMMENT'
#INCLUDE = 'INCLUDE'

RESERVED_KEYWORDS = [LET,FOR,IF,ELSE,ENDFOR,ENDIF,SWITCH,CASE,ENDSWITCH, IN]

def setVppGlobalVars():
    global INT_CONST     
    global REAL_CONST    
    global STR_CONST     
    global PLUS          
    global MINUS         
    global MUL           
    global DIV           
    global EQ            
    global NEQ           
    global GT            
    global LT            
    global LE            
    global GE            
    global LPAREN        
    global RPAREN        
    global LBRACKET      
    global RBRACKET      
    global ID            
    global FOR           
    global IF            
    global ELSE          
    global ENDFOR        
    global ENDIF         
    global SWITCH        
    global CASE          
    global ENDSWITCH     
    global DCOLON        
    global EOF           
    global LET           
    global SPACE         
    global BTICKDCOLUN   
    global BTICK         
    global V_TEXT        
    global INCR          
    global DECR          
    global NEWLINE       
    global COMMA         
    global ASSIGN
    global IN
    global SEMICOL
    global COMMENT
    global RESERVED_KEYWORDS
    #global INCLUDE

