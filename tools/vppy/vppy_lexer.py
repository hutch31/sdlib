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
from vppy_global import *
import re
import logging
#from collections import OrderedDict

###############################################################################
#                                                                             #
#  LEXER                                                                      #
#                                                                             #
###############################################################################


logger = logging.getLogger("vppy.Lexer")
#logger = logging.getLogger()
#logger.setLevel(logging.DEBUG)
#logger.setLevel(logging.INFO)

class Token(object):
    def __init__(self, type, value, line_num=0, line_pos=0):
        self.type = type
        self.value = value
        self.line_num = line_num
        self.line_pos = line_pos
        #print value

    def __str__(self):
        """String representation of the class instance.

        Examples:
            Token(INTEGER, 3)
            Token(PLUS, '+')
            Token(MUL, '*')
        """
        return 'Token({type}, {value}) at line {line} position {position}'.format(
            type=self.type,
            value=repr(self.value),
            line=self.line_num,
            position=self.line_pos

        )

    def __repr__(self):
        return self.__str__()

setVppGlobalVars()
# RESERVED_KEYWORDS = {
#     LET: Token(LET, LET),
#     'FOR': Token('FOR', 'FOR'),
#     'IF': Token('IF', 'IF'),
#     'ELSE': Token('ELSE', 'ELSE'),
#     'ENDFOR': Token('ENDFOR', 'ENDFOR'),
#     'ENDIF': Token('ENDIF', 'ENDIF'),
#     'SWITCH': Token('SWITCH', 'SWITCH'),
#     'CASE': Token('CASE', 'CASE'),
#     'ENDSWITCH': Token('ENDSWITCH', 'ENDSWITCH'),
# }

class Lexer(object):
    def __init__(self, text):
        # client string input, e.g. "4 + 2 * 3 - 6 / 2"
        self.text = text
        #print "Lexer(text) of length %s"%(len(text))
        # self.pos is an index into self.text
        self.pos = 0
        self.line_num = 0
        self.line_pos = 0
        self.line_end = False
        self.current_char = self.text[0]['text'][self.line_pos]
        self.current_meta = self.text[0]['meta']

    def genToken(self,type, value,):
        token = Token(type, value, self.current_meta, self.line_pos)
        logging.debug("Generating token %s"%(repr(token)))
        #print "Generating token %s"%(repr(token))
        return token


    def error(self):
        raise Exception("Invalid character %s at line %s position %s"%(
                self.current_char, self.line_num, self.line_pos))

    def advance(self):
        """Advance the `pos` pointer and set the `current_char` variable."""
        self.pos += 1
        #if self.pos > len(self.text) - 1:
        #    self.current_char = None  # Indicates end of input
        #else:
        #    self.current_char = self.text[self.pos]
        #self.update_line_number()
        ##logging.debug("Seing character %s" % (self.current_char))
        #print("%s::%s"%(self.current_meta, self.current_char))
        self.line_pos += 1
        if self.line_pos >= len(self.text[self.line_num]['text']):
            self.line_num +=1
            self.line_pos = 0
            if self.line_num >= len(self.text):
                self.current_char = None
                self.current_meta = None
            else:
                print(self.text[self.line_num])
                if len(self.text[self.line_num]['text'])>0:
                    self.current_char = self.text[self.line_num]['text'][self.line_pos]
                    self.current_meta = self.text[self.line_num]['meta']
                else:
                    self.current_char = None
                    self.current_meta = None
        else:
            self.current_char = self.text[self.line_num]['text'][self.line_pos]
            #self.current_meta = self.text[self.line_num]['meta']

    def peek(self, start=1,length=1):
        peek_pos = self.line_pos + start + length
        if peek_pos > len(self.text[self.line_num]['text']) - 1:
            return None
        else:
            return self.text[self.line_num]['text'][self.line_pos + start : peek_pos]

    def whitespace(self):
        result = ''
        while self.current_char is not None and re.match(r"[ \t]", self.current_char):
            result += self.current_char
            self.advance()
        #result += self.current_char
        #self.advance()
        #print "Whitespace returning token"
        return self.genToken(SPACE, result)


    def skip_comment(self):
        result = ''
        while self.current_char != "\n" and self.current_char != "\r" and self.current_char is not None:
            result += self.current_char
            self.advance()
        return self.genToken(COMMENT,result)
        #if self.current_char is not None:
        #    self.advance()  # the NEWLINE

    def vblk_comment(self):
        value = self.current_char
        while self.peek(1,2) != '*/':
            self.advance()
            value += self.current_char
        self.advance()
        value += self.current_char
        self.advance()
        value += self.current_char
        self.advance()
        return self.genToken(V_TEXT, value)

    def vline_comment(self):
        value = self.current_char
        self.advance()
        #print("vline_comment seeing char %s."%(value))
        while self.current_char not in ["\n", "\r"]:
            value += self.current_char
            self.advance()
            #print("vline_comment seeing char %s."%(value))
        #self.advance()
        #value += self.current_char
        return self.genToken(V_TEXT, value)

    def v_text(self):
        """Return a string value, all Verilog text excluding comments
        verilog statement stops at '//' or '/*', or backtick '`', but '`::' continues Verilog"""

        result = self.current_char
        self.advance()
        while self.current_char:
            # if self.peek(0,2) == '//':
            #     return self.genToken(V_TEXT, result)
            # elif re.match(r"[\r\n]",self.current_char):
            #     return self.genToken(V_TEXT, result)
            # elif self.peek(0,2) == '/*':
            #     return self.genToken(V_TEXT, result)
            # elif self.current_char == '`':
            #     return self.genToken(V_TEXT, result)
            # elif self.current_char != None:
            #     result += self.current_char
            #     self.advance()

            #print self.current_char
            if (self.current_char == None or re.match(r"[\r|\n|`]",self.current_char)
                                  or self.peek(0,2) == '//' or self.peek(0,2) == '/*'):
                break
            else:
                result += self.current_char
                self.advance()

            #print "v_text getting %s"%(self.current_char)

        return self.genToken(V_TEXT, result)


    def number(self):
        """Return a (multidigit) integer or float consumed from the input."""
        result = ''
        while self.current_char is not None and self.current_char.isdigit():
            result += self.current_char
            self.advance()

        if self.current_char == '.':
            result += self.current_char
            self.advance()

            while (self.current_char is not None and self.current_char.isdigit()):
                result += self.current_char
                self.advance()
            token = self.genToken('REAL_CONST', float(result))

        if self.current_char == 'e':
            result += self.current_char
            self.advance()
            if self.current_char == '-':
                result += self.current_char
                self.advance()
            while (self.current_char is not None and self.current_char.isdigit()):
                result += self.current_char
                self.advance()

            token = self.genToken('REAL_CONST', float(result))

        try:
            token.type is REAL_CONST
        #else:
        except NameError:
            token = self.genToken('INT_CONST', int(result))

        return token

    def string(self):
        """Return a string value."""

        delimiter = self.current_char
        #logger.debug("Delimiter is %s"%(delimiter))
        result    = self.current_char
        self.advance()
        while self.current_char != delimiter:
            result += self.current_char
            self.advance()
        result += self.current_char
        self.advance()

        token = self.genToken(STR_CONST, result)

        return token

    def _id(self):
        """Handle identifiers and reserved keywords"""
        result = ''
        while self.current_char is not None and re.match(r"[0-9a-zA-Z_]",self.current_char):
            result += self.current_char
            self.advance()

        #token = RESERVED_KEYWORDS.get(result.upper(), self.genToken(ID, result))
        if result.upper() in RESERVED_KEYWORDS:
            token = self.genToken(result.upper(), result)
        else:
            token = self.genToken(ID, result)
        #print "Invoked _id method for token %s"%(repr(token))
        return token

    def update_line_number(self):
        if self.line_end:
            self.line_num +=1
            self.line_pos = 1
        else:
            self.line_pos +=1
        if self.current_char in ("\r", "\n"):
            self.line_end = True
        else:
            self.line_end = False

    def get_next_v_token(self):
        """Lexical analyzer (also known as scanner or tokenizer)

        This method is dealing with native Verilog statements, one block of statements as a sing token
        """
        # while self.current_char is not None:
        #     if self.peek(0,4) == '////': # vpp comment
        #         #self.advance()
        #         self.skip_comment()
        #         continue
        #
        #     # if self.current_char == '`' and self.peek(2) == '::':
        #     #     self.advance()
        #     #     self.advance()
        #     #     self.advance()
        #     #     return token(BTICKDCOLON,'`::')
        #
        #     if self.current_char == '`':  # ` deliminate boundary into vpp domain
        #         self.advance()
        #         return self.genToken(BTICK,'`')
        #
        #     if re.match(r"[\r\n]", self.current_char):
        #         #print("getting newline")
        #         token = self.genToken(NEWLINE, self.current_char)
        #         self.advance()
        #         return token
        #
        #     if re.match(r"[ \t]", self.current_char):
        #         # this pattern will only catch whitespace at start of line in V_TEXT mode.
        #         return self.whitespace()
        #
        #     if self.peek(0,2) == '/*': # Verilog block comment
        #         return self.vblk_comment()
        #
        #     if self.peek(0,2) == '//': # Verilog line comment
        #         return self.vline_comment()
        #
        #     # verilog statement stops at '//' or '/*', or backtick '`', but '`::' continues Verilog
        #     return self.v_text()
        #
        # return self.genToken(EOF, None)
        return self.get_next_vpp_token()

    def get_next_vpp_token(self):
        """Lexical analyzer (also known as scanner or tokenizer)

        This method is responsible for breaking a VPP sentence apart into tokens. One token at a time.
        """
        while self.current_char is not None:
            #self.update_line_number()
            if self.peek(0,4) == '////': # vpp comment
                #self.advance()
                return self.skip_comment()
                # continue
            if self.peek(0,2) == '/*': # Verilog block comment
                return self.vblk_comment()
            if self.peek(0,2) == '//': # Verilog line comment
                print("peeking(0,2) line %s:%s:%s"%(self.line_num, self.current_char, self.peek(0,2)))
                return self.vline_comment()

            if re.match(r"[\r\n]", self.current_char):
                #print("getting newline")
                token = self.genToken(NEWLINE, self.current_char)
                self.advance()
                return token

            if re.match(r"[ \t]", self.current_char):
                #self.advance()
                return self.whitespace()

            if self.current_char == '"' or self.current_char == "\'":
                #self.advance()
                return self.string()

            if self.current_char == '`':
                #print("Seeing BTICK %s"%(self.current_char))
                self.advance()
                return self.genToken(BTICK, '`')

            if self.peek(0,2) == '::':
                self.advance()
                self.advance()
                return self.genToken(DCOLON, '::')

            if self.peek(0,2) == '==':
                self.advance()
                self.advance()
                return self.genToken(EQ, '==')
            if self.current_char == '=' :
                self.advance()
                return Token(ASSIGN, '=')

            if self.peek(0,2) == '>=':
                self.advance()
                self.advance()
                return self.genToken(GE, '>=')
            if self.current_char == '<=' :
                self.advance()
                return Token(LE, '<=')
            if self.current_char == '>':
                self.advance()
                return self.genToken(GT, '>')
            if self.current_char == '<':
                self.advance()
                return self.genToken(LT, '<')


            if self.current_char == ',':
                self.advance()
                return self.genToken(COMMA, ',')

            if self.current_char == ';':
                token = self.genToken(SEMICOL, self.current_char)
                self.advance()
                return token

            if self.peek(0,2) == '++':
                self.advance()
                self.advance()
                return self.genToken(INCR, '++')
            if self.current_char == '+':
                self.advance()
                return self.genToken(PLUS, '+')

            if self.peek(0,2) == '--':
                self.advance()
                self.advance()
                return self.genToken(DECR, '--')
            if self.current_char == '-':
                self.advance()
                return self.genToken(MINUS, '-')

            if self.current_char == '*':
                self.advance()
                return self.genToken(MUL, '*')

            if self.current_char == '/':
                self.advance()
                return self.genToken(DIV, '/')

            if self.current_char == '(':
                self.advance()
                return self.genToken(LPAREN, '(')

            if self.current_char == ')':
                self.advance()
                return self.genToken(RPAREN, ')')

            if self.current_char == '[':
                self.advance()
                return self.genToken(LBRACKET, '[')

            if self.current_char == ']':
                self.advance()
                return self.genToken(RBRACKET, ']')

            if self.current_char.isalpha():
                #print("Seeing ID %s"%(self.current_char))
                return self._id()

            if self.current_char.isdigit():
                return self.number()


            # if self.current_char == '.':
            #     self.advance()
            #     return Token(DOT, '.')

            return self.v_text()

        return self.genToken(EOF, None)
