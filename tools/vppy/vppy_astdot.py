""" vpp and extended, in Python 
AST visualizer - generates a DOT file for Graphviz.
To generate an image from the DOT file run $ dot -Tpng -o ast.png ast.dot
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
import argparse
import textwrap
from collections import OrderedDict
from vppy_global import *
import logging
from vppy_lexer import Lexer
from vppy_parser import Parser
from vppy_interpreter import NodeVisitor


class ASTVisualizer(NodeVisitor):
    def __init__(self, tree):
        self.tree = tree
        self.ncount = 1
        self.dot_header = [textwrap.dedent("""\
        digraph astgraph {
          node [shape=circle, fontsize=12, fontname="Courier", height=.1];
          ranksep=.3;
          edge [arrowsize=.5]

        """)]
        self.dot_body = []
        self.dot_footer = ['}']

    def visit_Program(self, node):
        s = '  node{} [label="Program"]\n'.format(self.ncount)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        for stmt in node.block:
            logging.debug("stmt is of type %s"%(type(stmt).__name__))
            self.visit(stmt)
            s = '  node{} -> node{}\n'.format(node._num, stmt._num)
            self.dot_body.append(s)

        #s = '  node{} -> node{}\n'.format(node._num, node.block._num)
        #self.dot_body.append(s)

    def visit_Block(self, node):
        s = '  node{} [label="Block"]\n'.format(self.ncount)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        for declaration in node.declarations:
            self.visit(declaration)
        self.visit(node.compound_statement)

        for decl_node in node.declarations:
            s = '  node{} -> node{}\n'.format(node._num, decl_node._num)
            self.dot_body.append(s)

        s = '  node{} -> node{}\n'.format(
            node._num,
            node.compound_statement._num
        )
        self.dot_body.append(s)

    def visit_VarDecl(self, node):
        s = '  node{} [label="VarDecl"]\n'.format(self.ncount)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.var_node)
        s = '  node{} -> node{}\n'.format(node._num, node.var_node._num)
        self.dot_body.append(s)

        self.visit(node.type_node)
        s = '  node{} -> node{}\n'.format(node._num, node.type_node._num)
        self.dot_body.append(s)

    def visit_ProcedureDecl(self, node):
        s = '  node{} [label="ProcDecl:{}"]\n'.format(
            self.ncount,
            node.proc_name
        )
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.block_node)
        s = '  node{} -> node{}\n'.format(node._num, node.block_node._num)
        self.dot_body.append(s)

    def visit_Type(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, node.token.value)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

    def visit_Num(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, node.token.value)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1
        #print("visit_Num seeing number %s"%(node.token.value))

    def visit_Str(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, node.value)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

    def visit_BinOp(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, node.op.value)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.left)
        self.visit(node.right)

        for child_node in (node.left, node.right):
            s = '  node{} -> node{}\n'.format(node._num, child_node._num)
            self.dot_body.append(s)

    def visit_UnaryOp(self, node):
        s = '  node{} [label="unary {}"]\n'.format(self.ncount, node.op.value)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.expr)
        s = '  node{} -> node{}\n'.format(node._num, node.expr._num)
        self.dot_body.append(s)

    def visit_Compound(self, node):
        s = '  node{} [label="Compound"]\n'.format(self.ncount)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        for child in node.children:
            self.visit(child)
            s = '  node{} -> node{}\n'.format(node._num, child._num)
            self.dot_body.append(s)

    def visit_Assign(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, node.op.value)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.left)
        self.visit(node.right)

        for child_node in (node.left, node.right):
            s = '  node{} -> node{}\n'.format(node._num, child_node._num)
            self.dot_body.append(s)

    def visit_forStmt(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, "forStmt")
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.init_cond)
        self.visit(node.condition)
        self.visit(node.loopOp)
        for stmt in node.path1:
            logging.debug("stmt is of type %s"%(type(stmt).__name__))
            self.visit(stmt)
            s = '  node{} -> node{}\n'.format(node._num, stmt._num)
            self.dot_body.append(s)

        #TODO: self.visit(node.path2)

        for child_node in (node.init_cond, node.condition,node.loopOp):
            s = '  node{} -> node{}\n'.format(node._num, child_node._num)
            self.dot_body.append(s)

    def visit_foreachStmt(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, "foreachStmt")
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        self.visit(node.var)
        self.visit(node.range)
        for stmt in node.path1:
            logging.debug("stmt is of type %s"%(type(stmt).__name__))
            self.visit(stmt)
            s = '  node{} -> node{}\n'.format(node._num, stmt._num)
            self.dot_body.append(s)

        #TODO: self.visit(node.path2)

        for child_node in (node.var, node.range):
            s = '  node{} -> node{}\n'.format(node._num, child_node._num)
            self.dot_body.append(s)

    def visit_vText(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, "vTextStmt")
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

        for token in node.tokens:
            logging.debug("token is %s"%(token.value))
            s = '  node{} [label="{}"]\n'.format(self.ncount, token.value)
            self.dot_body.append(s)
            token._num = self.ncount
            self.ncount += 1
            s = '  node{} -> node{}\n'.format(node._num, token._num)
            self.dot_body.append(s)

    def visit_Var(self, node):
        if node.num_token == 1:
            s = '  node{} [label="{}"]\n'.format(self.ncount, node.id)
        else:
            s = '  node{} [label="{}.{}"]\n'.format(self.ncount, node.id)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1
        if node.num_token > 1:
            self.visit(node.tokens[-1])

    def visit_comprList(self, node):
        s = '  node{} [label="{}"]\n'.format(self.ncount, "comprList")
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1
        for element in node.elements:
            self.visit(element)
            s = '  node{} -> node{}\n'.format(node._num, element._num)
            self.dot_body.append(s)

    def visit_NoOp(self, node):
        s = '  node{} [label="NoOp"]\n'.format(self.ncount)
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

    def visit_Token(self, node):
        if (node.value)>10 :
            s = '  node{} [label="Token:{}\n{}..."]\n'.format(self.ncount, node.type, node.value[0:7])
        else:
            s = '  node{} [label="Token:{}\n{}"]\n'.format(self.ncount, node.type, node.value[0:10])
        self.dot_body.append(s)
        node._num = self.ncount
        self.ncount += 1

    def gendot(self):
        tree = self.tree
        self.visit(tree)
        return ''.join(self.dot_header + self.dot_body + self.dot_footer)


def main():
    argparser = argparse.ArgumentParser(
        description='Generate an AST DOT file.'
    )
    argparser.add_argument(
        '-f', '--fname',
        action="store",
        default="sample.vpp",
        help='VPP source file'
    )
    args = argparser.parse_args()
    fname = args.fname
    text = open(fname, 'r').read()

    lexer = Lexer(text)
    parser = Parser(lexer)
    viz = ASTVisualizer(parser)
    content = viz.gendot()
    print(content)


if __name__ == '__main__':
    main()
