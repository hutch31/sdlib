#!/usr/bin/python
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
import sys, logging
from vppy_global import setVppGlobalVars
from vppy_lexer import Lexer
from vppy_parser import *
from vppy_interpreter import Interpreter
from vppy_preprocessor import Preprocessor
import time
#from vppy_symbolTable import SymbolTableBuilder

logger = logging.getLogger("vppy")
logger.setLevel(logging.DEBUG)

def main():
    setVppGlobalVars()
    if len(sys.argv) >1 :
        fname = sys.argv[1]

    else:
        fname = 'sample.vpp'
    lines = open(fname, 'r').readlines()
    print lines

    pp_text = Preprocessor(lines,fname)
    lexer = Lexer(pp_text.pp_lines)
    parser = Parser(lexer)
    tree = parser.parse()
    #symtab_builder = SymbolTableBuilder()
    #symtab_builder.visit(tree)
    #print('')
    #print('Symbol Table contents:')
    #print(symtab_builder.symtab)

    interpreter = Interpreter(tree)
    result = interpreter.interpret()

    logger.debug('=====================================================')
    logger.debug("Run results:\n" + result + '=====================================================')
    logger.debug('Run-time GLOBAL_MEMORY contents:')

    for k, v in sorted(interpreter.GLOBAL_MEMORY.items()):
        logger.debug('%s = %s' % (k, v))
    print('=====================================================')

    if len(sys.argv) >2 :
        fh = open(sys.argv[2], 'w')
        fh.write(result)
    else:
        time.sleep(0.1)
        print result


if __name__ == '__main__':
    main()
