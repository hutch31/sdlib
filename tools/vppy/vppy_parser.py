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
import logging
#from collections import OrderedDict
from vppy_lexer import Token, Lexer

setVppGlobalVars()
logger = logging.getLogger("vppy.Parser")
#logger.setLevel(logging.DEBUG)

###############################################################################
#                                                                             #
#  PARSER                                                                     #
#                                                                             #
###############################################################################

class AST(object):
    pass

class NoOp(AST):
    pass

class Program (AST):
    def __init__(self, block):
        self.block = block

class ifStmt(AST):
    def __init__(self, condition, path1, path2=NoOp()):
        self.condition = condition
        self.path1 = path1
        self.path2 = path2

class forStmt(AST):
    def __init__(self, init_cond, condition, loopOp, path1, path2=NoOp()):
        self.init_cond = init_cond
        self.condition = condition
        self.loopOp    = loopOp
        self.path1 = path1
        self.path2 = path2

class foreachStmt(AST):
    def __init__(self, var, range, path1, path2=NoOp()):
        self.var = var
        self.range  = range
        self.path1 = path1
        self.path2 = path2

class vBtick(AST):
    def __init__(self, left, right):
        self.left = left
        self.right = right

class vText(AST):
    def __init__(self, tokens):
        self.tokens = tokens
        self.num_token = len(tokens)
        #self.value = token.value

class BinOp(AST):
    def __init__(self, left, op, right):
        self.left = left
        self.token = self.op = op
        self.right = right

class Num(AST):
    def __init__(self, token):
        self.token = token
        self.value = token.value

class Str(AST):
    def __init__(self, token):
        self.token = token
        self.value = token.value[1:-1]

class UnaryOp(AST):
    def __init__(self, op, expr):
        self.token = self.op = op
        self.expr = expr


class Assign(AST):
    def __init__(self, left, op, right=None):
        self.left = left
        self.token = self.op = op
        self.right = right


class comprList(AST):
    """The compList node is a list of comparisons, used to represent an array value"""
    def __init__(self, nodes):
        self.elements = nodes

class Var(AST):
    """The Var node is constructed out of ID token."""
    def __init__(self, tokens):
        self.num_token = len(tokens)
        self.tokens = tokens
        self.id = tokens[0].value
        #logger.debug("Var AST value: %s"%(repr(self)))
    def __str__(self):
        """String representation of the class instance.
        """
        string = ""
        for token in self.tokens:
            string += repr(token)
        return string

    def __repr__(self):
        return self.__str__()

class VarInst(AST):
    def __init__(self, name, block):
        self.name = name
        self.block = block

class Parser(object):
    def __init__(self, lexer):
        self.lexer = lexer
        self.lex_state = V_TEXT # v or vpp mode lex-ing
        # set current token to the first token taken from the input
        #self.current_token = self.lexer.get_next_v_token()
        self.la_tokens = [self.lexer.get_next_v_token(),self.lexer.get_next_v_token(),self.lexer.get_next_v_token()]
        self.current_token = self.la_tokens[0]

    def error(self, msg=''):
        raise Exception('Invalid syntax: ' + msg)

    def eat(self, token_type = None, greedy_type = None ):
        # compare the current token type with the passed token
        # type and if they match then "eat" the current token
        # and assign the next token to the self.current_token,
        # otherwise raise an exception.

        if token_type == None or self.current_token.type == token_type:
            #print("Going to get next v_token")
            self.la_tokens.pop(0)
            self.la_tokens.append(self.lexer.get_next_vpp_token())
            self.current_token = self.la_tokens[0]
            if greedy_type != None:
                while self.current_token.type == greedy_type or self.current_token.type == COMMENT:
                    self.la_tokens.pop(0)
                    self.la_tokens.append(self.lexer.get_next_vpp_token())
                    self.current_token = self.la_tokens[0]

            logging.debug("Lexer got token %s" % (repr(self.current_token)))
        else:
            self.error("expecting token type %s, seeing %s"%(token_type,repr(self.current_token)))

    def program(self):
        """program : statements """
        block = self.statements()
        return Program(block)

    def format_vpp_stmt(self):
        #if (self.la_tokens[0].type == COMMENT):
        print("format_vpp_stmt discovering token %s"%(self.la_tokens[0].value))

        if (self.la_tokens[0].type == SPACE and self.la_tokens[1].type == BTICK
                    and self.la_tokens[2].type in RESERVED_KEYWORDS):
            self.eat(SPACE)
            print("format_vpp_stmt detecting vpp statement `%s"%(self.la_tokens[2].__str__))
        elif (self.la_tokens[0].type == SPACE and self.la_tokens[1].type == COMMENT):
            self.eat(SPACE, COMMENT)
            self.eat(NEWLINE)
            print("format_vpp_stmt recursively called point 1")
            self.format_vpp_stmt()
        elif (self.la_tokens[0].type == COMMENT):
            self.eat(COMMENT)  # do not greedy-ly eat NEWLINE, otherwise a empty line after COMMENT will be eaten
            self.eat(NEWLINE)
            print("format_vpp_stmt recursively called point 2")
            self.format_vpp_stmt()
        else:
            print("format_vpp_stmt not detecting vpp statement %s%s" % (self.la_tokens[1].value, self.la_tokens[2].value))

    def statements(self):
        """
        statement_list : statement +
        """
        print("Statements discovering first statement with token %s" % (self.current_token))
        node = self.statement()

        results = [node]

        while self.current_token.type != EOF:
            #if self.current_token.type is BTICK:
            #    self.eat(BTICK)
            #    continue
            self.format_vpp_stmt()

            if self.la_tokens[0].type == BTICK and self.la_tokens[1].type in (ELSE, ENDIF, ENDFOR):
                break
            else:
                logging.debug("Statements going to next statement with token %s"%(self.current_token))
                results.append(self.statement())

        print("Statements return results before token %s" % (self.current_token))
        return results

    def statement(self):
        """
        statement : varassign_stmt
          | if_stmt
          | for_stmt
          | v_text
          | varinst
          | empty
        """

        if self.current_token.type == NEWLINE:
            tokens = []
            tokens.append(self.current_token)
            self.eat(NEWLINE)
            #return NoOp()
            return vText(tokens)
        elif self.current_token.type == EOF:
            return NoOp()
        self.format_vpp_stmt()

        print("statement starting with token %s" % (self.current_token.__str__))
        if self.current_token.type == BTICK:
            self.eat(BTICK)

            print("Statement parsing %s" % (repr(self.current_token)))
            if self.current_token.type == LET:
                node = self.varaassign_stmt()
            elif self.current_token.type == FOR:
                node = self.for_stmt()
                #print("statement: for_stmt returned")
            elif self.current_token.type == IF:
                node = self.if_stmt()
            elif self.current_token.type == DCOLON:
                node = self.btickinst()
            else:
                node = self.varinst()
            self.lex_state = V_TEXT
            #logging.debug("Switch to lex state %s mode ater %s" % (self.lex_state, self.current_token))
            logging.debug("Statement returning node of type %s"%(type(node).__name__))
        else:
            node = self.v_text_stmt()

        return node

    def v_text_stmt(self):
        nodes = []
        while self.current_token.type not in (BTICK, NEWLINE, EOF):
            print("v_text_stmt processing token %s"%(self.current_token.__str__))
            nodes.append(self.current_token)
            self.eat()
        if self.current_token.type == NEWLINE:
            nodes.append(self.current_token)
            self.eat(NEWLINE)
        print("v_text_stmt returning before token %s" % (self.current_token.__str__))
        return vText(nodes)

    def if_stmt(self):
        """
        if_stmt: '`if' comparison statements ('`else' statements)? 'endif'
        """
        nodes = []
        nodes.append(self.current_token)
        self.eat(IF, SPACE)
        self.eat(LPAREN, SPACE)
        condition=self.comparison()
        self.eat(RPAREN, SPACE)
        #if self.current_token.type == NEWLINE:
        self.eat(NEWLINE)
        self.lex_state = V_TEXT
        print("if_stmt discovering path1 statements")
        path1 = self.statements()
        print("if_stmt leaving path1 statements before token %s"%(self.current_token.__str__))
        path2 = NoOp()
        if(self.current_token.type == BTICK and self.la_tokens[1].type == ELSE) :
            #nodes.append(self.current_token)
            self.eat(BTICK)
            self.eat(ELSE, SPACE)
            self.eat(NEWLINE)
            path2 = self.statements()
        if self.current_token.type == EOF :
            self.error("reaching end of file, IF without ENDIF")
        elif self.current_token.type == BTICK and self.la_tokens[1].type == ENDIF:
            self.eat(BTICK)
            self.eat(ENDIF, SPACE)
            self.eat(NEWLINE)
            return ifStmt(condition, path1, path2)


    def for_stmt(self):
        """
        for_stmt: '`for' '(' assignment ',' ' comparison ',' assignment ')' statements ('`else' statements)* '`endfor'
        """
        #nodes = []
        #nodes.append(self.current_token)
        self.eat(FOR, SPACE)
        #print("For statement, branching with token %s"%(self.current_token))
        if self.current_token.type == LPAREN:
            #print("For statement branced into forStmt")
            self.eat(LPAREN, SPACE)
            init = self.assignment()
            self.eat(SEMICOL,SPACE)
            condition = self.comparison()
            self.eat(SEMICOL,SPACE)
            loopOp = self.assignment()
            self.eat(RPAREN,SPACE)
            self.lex_state = V_TEXT
            type = 'forStmt'
        else:
            #print("For statement branced into foreachStmt")
            var = self.variable()
            self.eat(IN, SPACE)
            range = self.compr_list()
            #print("foreachStmt range %s, length %d"%(range, len(range.elements)))
            type = 'foreachStmt'

        if self.current_token.type == NEWLINE:
            self.lex_state = V_TEXT
            self.eat(NEWLINE)
        path1 = self.statements()
        path2 = [NoOp()]
        print("forStmt discovering token %s"%(self.current_token.__str__))
        if self.current_token.type == BTICK and self.la_tokens[1].type == ELSE:
            self.eat(BTICK)
            self.eat(ELSE, SPACE)
            self.eat(NEWLINE)
            path2 = self.statements()
        if self.current_token.type is EOF:
            self.error("reaching end of file, FOR without ENDFOR")
        elif self.current_token.type == BTICK and self.la_tokens[1].type == ENDFOR:
            print("For statement discovering %s" % (self.current_token))
            self.eat(BTICK)
            self.eat(ENDFOR, SPACE)
            self.eat(NEWLINE)
            if type == 'forStmt':
                return forStmt(init,condition,loopOp, path1, path2)
            else:
                return foreachStmt(var, range, path1, path2)

    def compr_list(self):
        """comprlist: '[' comparison (',' comparison)* ']' """

        nodes = []
        if self.current_token.type == LBRACKET:
            self.eat(LBRACKET, SPACE)
            has_bracket = 1
        else:
            has_bracket = 0

        logging.debug("Compr_list getting first comparison")
        nodes.append(self.comparison())
        logging.debug("Compr_list got first comparison")
        while self.current_token.type == COMMA:
            self.eat(COMMA, SPACE)
            logging.debug("Compr_list going to get one more comparison")
            nodes.append(self.comparison())

        if has_bracket:
            self.eat(RBRACKET, SPACE)

        logging.debug("Compr_list returning node")
        return comprList(nodes)

    def btickinst(self):
        token1 = self.current_token  # TODO: it is already DCOLON
        #self.eat(BTICK)
        token2 = self.current_token
        #self.lex_state = V_TEXT
        self.eat(DCOLON)
        return vBtick(token1, token2)

    def varinst(self):
        """
        varinst: '`' variable (::)?
        """
        #self.eat(BTICK)
        node = self.variable()
        self.lex_state = V_TEXT
        #print "Switching lexer to V_TEXT mode after %s"%(self.current_token.__str__)
        if self.current_token.type == DCOLON :
            self.eat(DCOLON)
        #elif self.current_token.type == SPACE:
        #    self.eat(SPACE)
        elif self.current_token.type == NEWLINE:
            self.eat(NEWLINE)
        #print "Received next token in V_TEXT mode"
        return node

    def varaassign_stmt(self):
        """
        varassign_stmt: 'let' assignment NEWLINE
        """
        self.eat(LET, SPACE)
        node = self.assignment()
        logging.debug("varaassign_stmt got assignment node")
        self.lex_state = V_TEXT
        print "varaassign_stmt: current token is %s"%(self.current_token)
        self.eat(NEWLINE)
        logging.debug("varaassign_stmt returning node")
        return node

    def assignment(self):
        """
        assignment : variable ('=' (comparison | compr_list) | '++' | '--')
        """
        left = self.variable()
        token = self.current_token
        right = NoOp()
        if(token.type == ASSIGN):
            self.eat(ASSIGN, SPACE)
            if self.current_token.type == LBRACKET:
                right = self.compr_list()
            else:
                right = self.comparison()
        elif token.type == INCR:
            self.eat(INCR, SPACE)
            right = NoOp()
        elif token.type == DECR:
            self.eat(DECR, SPACE)
            right = NoOp()
        #right = self.comparison()

        node = Assign(left, token, right)
        logging.debug("Assignment returning node before token %s"%(self.current_token))
        return node

    def variable(self):
        """
        variable : variable: ID ('[' expr ']')?
        """
        nodes = []
        nodes.append(self.current_token)
        self.eat(ID,SPACE)
        if self.current_token.type == LBRACKET:
            #nodes.extend(self.current_token)
            self.eat(LBRACKET, SPACE)
            nodes.append(self.expr())
            #nodes.extend(self.current_token())
            self.eat(RBRACKET, SPACE)
        return Var(nodes)

    def empty(self):
        """An empty production"""
        return NoOp()

    def comparison(self):
        """
        comparison : expr ((COMP_OP) expr)*
        """
        has_lparen = False
        if self.current_token == LPAREN:
            self.eat(LPAREN, SPACE)
            has_lparen = True
        node = self.expr()
        if  has_lparen:
            self.eat(RPAREN, SPACE)
            #self.eat(NEWLINE)

        while self.current_token.type in (LE, LT, GT, GE, EQ, NEQ):
            token = self.current_token
            self.eat(token.type, SPACE)

            node = BinOp(left=node, op=token, right=self.expr())
        print("Comparison returning node before token %s"%(self.current_token))
        return node

    def expr(self):
        """
        expr : term ((PLUS | MINUS) term)*
        """
        node = self.term()

        while self.current_token.type in (PLUS, MINUS):
            token = self.current_token
            if token.type == PLUS:
                self.eat(PLUS, SPACE)
            elif token.type == MINUS:
                self.eat(MINUS, SPACE)

            right_node = self.term()
            node = BinOp(left=node, op=token, right=right_node)
        print("Expr returning node before token %s"%(self.current_token))
        return node

    def term(self):
        """term : factor ((MUL | INTEGER_DIV | FLOAT_DIV) term)*"""
        logging.debug("Term generating left factor with token %s" % (repr(self.current_token)))
        left = self.factor()
        node = left
        while self.current_token.type in (MUL, DIV, DIV):
            op = self.current_token
            logging.debug("Term generating seeing OP with token %s" % (repr(self.current_token)))
            self.eat(op.type, SPACE)
            right = self.term()
            logging.debug("Term generating seeing right factor with token %s" % (repr(self.current_token)))
            node = BinOp(left, op, right)
        print("Term returning node of type %s before token %s"%(type(node).__name__, self.current_token))
        return node

    def factor(self):
        """factor : PLUS factor
                   | MINUS factor
                   | INT_CONST
                   | REAL_CONST
                   | STR_CONST
                   | variable
                   | LPAREN expr RPAREN
        """
        token = self.current_token
        logging.debug("Factor seeing token %s"%(repr(token)))
        if token.type == PLUS:
            self.eat(PLUS, SPACE)
            node = UnaryOp(token, self.factor())
            return node
        elif token.type == MINUS:
            self.eat(MINUS, SPACE)
            node = UnaryOp(token, self.factor())
            return node
        elif token.type == INT_CONST:
            self.eat(INT_CONST, SPACE)
            return Num(token)
        elif token.type == REAL_CONST:
            print("factor getting REAL_CONST")
            self.eat(REAL_CONST, SPACE)
            return Num(token)
        elif token.type == STR_CONST:
            logging.debug("STR_CONST token %s"%(token))
            self.eat(STR_CONST, SPACE)
            return Str(token)
        elif token.type == LPAREN:
            self.eat(LPAREN, SPACE)
            node = self.expr()
            self.eat(RPAREN, SPACE)
            return node
        else:
            node = self.variable()
            return node

    def parse(self):
        node = self.program()
        if self.current_token.type != EOF:
            self.error(repr(self.current_token))

        return node
