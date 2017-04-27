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
from collections import OrderedDict
from vppy_global import *
import logging

setVppGlobalVars()
logger = logging.getLogger("vppy.Interpreter")
#logger.setLevel(logging.DEBUG)

###############################################################################
#                                                                             #
#  AST visitors (walkers)                                                     #
#                                                                             #
###############################################################################

class NodeVisitor(object):
    def visit(self, node):
        method_name = 'visit_' + type(node).__name__
        visitor = getattr(self, method_name, self.generic_visit)
        logger.debug("NodeVisitor going to use visitor %s" % (visitor))
        return visitor(node)

    def generic_visit(self, node):
        logging.debug("Node is %s"%(repr(node)))

        raise Exception('No visit_{} method'.format(type(node).__name__))


###############################################################################
#                                                                             #
#  INTERPRETER                                                                #
#                                                                             #
###############################################################################

class Interpreter(NodeVisitor):
    def __init__(self, tree):
        self.tree = tree
        self.GLOBAL_MEMORY = OrderedDict()
        self.result = ""

    def error(self, msg=''):
        raise Exception('Run time error: ' + msg)

    def concat_result(self, result, stmt_rslt):
        logging.debug("Incremental result update %s" % (stmt_rslt))
        if stmt_rslt != None and type(self.result) == type(stmt_rslt):
            self.result += stmt_rslt
        elif stmt_rslt != None:
            logging.debug("converting incremental result update of type %s to string" % (
                type(stmt_rslt).__name__))
            self.result += str(stmt_rslt)
        return result

    def visit_Program(self, node):
        result = ""
        logging.debug("visit_Program: going to visit %d statements"%(len(node.block)))
        for statement in node.block:
            logging.debug("Program going to visit statement of type %s"%(
                type(statement)))
            self.concat_result(result, self.visit(statement))
        return self.result

    def visit_Block(self, node):
        for declaration in node.declarations:
            self.visit(declaration)
        self.visit(node.compound_statement)

    def visit_Token(self, token):
        if token.type == 'V_TEXT':
            result = token.value
            logging.debug("Visited token %s"%(repr(token)))
            return result
        else:
            logging.debug("visit_Token is not expecting guest %s"%(token))

    def visit_VarDecl(self, node):
        # Do nothing
        pass

    def visit_Type(self, node):
        # Do nothing
        pass

    def visit_BinOp(self, node):
        leftOrig = self.visit(node.left)
        rightOrig = self.visit(node.right)
        #print(type(leftOrig).__name__)
        if type(leftOrig).__name__ == 'list' and type(rightOrig).__name__ != 'list':
            left = leftOrig[0]
        else:
            left = leftOrig
        if type(leftOrig).__name__ != 'list' and type(rightOrig).__name__ == 'list':
            right = rightOrig[0]
        else:
            right = rightOrig


        if node.op.type == PLUS:
            result = left + right
        elif node.op.type == MINUS:
            result = left - right
        elif node.op.type == MUL:
            result = left * right
        #elif node.op.type == INTEGER_DIV:
        #    return self.visit(node.left) // self.visit(node.right)
        elif node.op.type == DIV:
            result = left / right
        elif node.op.type == LT:
            result = left < right
        elif node.op.type == GT:
            result = left > right
        elif node.op.type == LE:
            result = left <= right
        elif node.op.type == GE:
            result = left >= right
        elif node.op.type == EQ:
            result = left == right
        elif node.op.type == NEQ:
            result = left != right

        logging.debug("visit_BinOp: %s %s %s = %s" % (left, node.op.value, right, result))
        return result

    def visit_Num(self, node):
        logging.debug("visit_Num returning %s"%(node.value))
        return node.value
    def visit_Str(self, node):
        logging.debug("visit_Str returning %s" % (node.value))
        return node.value


    def visit_UnaryOp(self, node):
        op = node.op.type
        if op == PLUS:
            result = +self.visit(node.expr)
        elif op == MINUS:
            result = -self.visit(node.expr)
        logging.debug("visit_UnaryOp returning value %s" % (result))
        return result

    def visit_Assign(self, node):
        var_name = node.left.id
        if var_name in self.GLOBAL_MEMORY and node.left.num_token > 1 :
            index = self.visit(node.left.token[1])
            orig_var_value = self.GLOBAL_MEMORY[var_name][index]
        elif var_name in self.GLOBAL_MEMORY:
            orig_var_value = self.GLOBAL_MEMORY[var_name]

        if node.op.type == ASSIGN :
            var_value = self.visit(node.right)
            #print "var_value %s is of type %s"%(var_value, type(var_value).__name__)
        elif node.op.type in (INCR, DECR):
            if var_name not in self.GLOBAL_MEMORY:
                self.error("variable %s used before being assigned" % (var_name))

            #print("var_name %s value %s" % (var_name, orig_var_value))
            if node.op.type == INCR:
                var_value = orig_var_value + 1
            elif node.op.type == DECR:
                var_value = orig_var_value -1

        if node.left.num_token > 1:
            self.GLOBAL_MEMORY[var_name][index] = var_value
        else:
            if type(var_value).__name__ == 'list':
                self.GLOBAL_MEMORY[var_name] = []
                self.GLOBAL_MEMORY[var_name].extend( var_value)
                #print("Var GM.%s value %s, length %s" % (var_name,
                #        self.GLOBAL_MEMORY[var_name], len(self.GLOBAL_MEMORY[var_name])))
            else:
                self.GLOBAL_MEMORY[var_name] = var_value

    def visit_vBtick(self, node):
        #print("visit_vBtick returning value %s" % (node.left.value))
        return '`'

    def visit_vText(self, node):
        #print("visit_vText returning value %s"%(node.token.value))
        #return node.token.value
        result = ''
        for token in node.tokens :
            result += str(token.value)  # TODO: fix this
        return result


    def visit_foreachStmt(self,node):
        var_name = node.var.id
        var_range = []
        var_range = self.visit(node.range)
        result = ""
        #print("foreach %s in %s, %d items"%(
        #            var_name,var_range,len(var_range)))
        for var_val in var_range:
            #print("---------iter item %s"%(var_val))
            self.GLOBAL_MEMORY[var_name] = var_val
            for stmt in node.path1:
                self.concat_result(result, self.visit(stmt))
        else:
            for stmt in node.path2:
                self.concat_result(result, self.visit(stmt))
        return result

    def visit_forStmt(self,node):
        result = ""
        var_name = node.init_cond.left.id
        self.visit(node.init_cond)
        logging.debug("init: idx value is %d"%(self.GLOBAL_MEMORY[var_name]))
        while self.visit(node.condition):
            for stmt in node.path1:
                self.concat_result(result, self.visit(stmt))
            self.visit(node.loopOp)
            logging.debug("looping: idx value is %d" % (self.GLOBAL_MEMORY[var_name]))
        else:
            logging.debug("ending idx value is %d" % (self.GLOBAL_MEMORY[var_name]))
            for stmt in node.path2:
                self.concat_result(result, self.visit(stmt))
        print("visit_forStmt returning result %s"%(result))
        return result

    def visit_ifStmt(self,node):
        result = ""
        if self.visit(node.condition):
            for stmt in node.path1:
                self.concat_result(result, self.visit(stmt))
        else:
            for stmt in node.path2:
                self.concat_result(result, self.visit(stmt))
        return result

    def visit_comprList(self, node):
        result = []
        for element in node.elements:
            elerslt = self.visit(element)
            if type(elerslt).__name__ == 'list':
                for ele in elerslt:
                    result.append(ele)
            else:
                result.append(elerslt)
            #print("comprList result %s length %d"%(result, len(result)))
        #print("visit_comprList returning value value %s" % (var_value))
        return result

    def visit_Var(self, node):
        var_name = node.id
        num_token = node.num_token
        if var_name not in self.GLOBAL_MEMORY:
            self.error("Variable %s referenced before defined %s" % (var_name, node.tokens[0].__str__))

        if num_token == 1:
            var_value = self.GLOBAL_MEMORY.get(var_name)
            #if (var_name == 'blk_names'):
                #print("blk_names is visted as: %s, len %d" % (
                #    var_value,len(var_value)))
        else :
            index = self.visit(node.tokens[-1])
            #print("GB.mem var %s index %d"%(var_name,index))
            if index >= len(self.GLOBAL_MEMORY.get(var_name)):
                self.error("index %d out of range for variable %s of length %d"%(
                    index, var_name, len(self.GLOBAL_MEMORY.get(var_name))))
            var_value = self.GLOBAL_MEMORY.get(var_name)[index]

        #print("visit_Var returning value value %s" % (var_value))
        return var_value

    def visit_NoOp(self, node):
        pass

    def interpret(self):
        tree = self.tree
        #print("Entering interpret.")
        if tree is None:
            #print("Parse tree is None!")
            return ""
        #print("Interpreting parse tree of type %s."%(type(tree).__name__))
        return self.visit(tree)

