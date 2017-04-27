//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
// Author: Frank Wang
//
//----------------------------------------------------------------------
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org/> 
//----------------------------------------------------------------------
import unittest
import subprocess
import time
import logging

logger = logging.getLogger("vppy")
logger.setLevel(logging.INFO)

class InterpreterTestCase(unittest.TestCase):
    def makeInterpreter(self, text):
        #import vppy
        from vppy_interpreter import Interpreter
        from vppy_lexer import Lexer
        from vppy_parser import Parser
        from vppy_astdot import ASTVisualizer
        from vppy_preprocessor import Preprocessor

        pp_text = Preprocessor(text.split("(\n)"), 'root')
        lexer = Lexer(pp_text.pp_lines)
        parser = Parser(lexer)
        tree = parser.parse()
        #symtab_builder = SymbolTableBuilder()
        #symtab_builder.visit(tree)

        astdot      = ASTVisualizer(tree)
        interpreter = Interpreter(tree)
        return interpreter, astdot

    #@unittest.skip("skipping test as part of incremental test suite")
    def test_integer_arithmetic_expressions(self):
        test_num = -1
        for expr, result in (  # results values below are not used.
            ('3.2', 3),
            ('2 + 7.0 / 4', 30),
            ('7 - 8 / 4', 5),
            ('14 + 2 * 30 - 6 / 2', 17),
            ('7 + 3 * (10 / (12 / (3 + 1) - 1))', 22),
            ('7 + 3 * 10 / 2 ', 22),
            ('7 + 3 * (10 / (12 / (3 + 1) - 1)) / (2 + 3) - 5 - 3 + (8)', 10),
            ('7 + (((3 + 2)))', 12),
            ('- 3', -3),
            ('+ 3', 3),
            ('5 - - - + - 3', 8),
            ('5 - - - + - (3 + 4) - +2', 10),
        ):
            time.sleep(0.1)
            test_num += 1
            text = "`let a = %s \n" % (expr)
            print("INFO: testing int arithmetic expression: %s" % (text))
            (interpreter, astdot) = self.makeInterpreter( text  )
            interpreter.interpret()
            time.sleep(0.1)
            globals = interpreter.GLOBAL_MEMORY
            try:
                self.assertEqual(globals['a'], eval(expr))
            except:
                print "ERROR: test %d failed."%(test_num)
                dottxt = astdot.gendot()
                time.sleep(0.1)
                open("astdot_testcase_%d.dot" % (test_num), 'w').write(dottxt)
                subprocess.call(["dot", "-Tpng", "-o", "astdot_testcase_%s.png" % (test_num),
                                 "astdot_testcase_%s.dot" % (test_num)])
                subprocess.call(['rm', '-f', "astdot_testcase_%s.dot" % (test_num)])
            print "INFO: test %d run result is %d, should be %d." % (test_num, globals['a'], eval(expr))

    #@unittest.skip("skipping test as part of incremental test suite")
    def test_variable_instantiation(self):
        text = """\
`let idx = 3
assign signal_b_`idx::_out = signal_`idx::_in
"""
        (interpreter, astdot) = self.makeInterpreter(text)
        vtxt = interpreter.interpret()


        print("Generated output text:")
        print("==================================")
        print(vtxt + "==================================")
        globals = interpreter.GLOBAL_MEMORY
        self.assertEqual(globals['idx'], 3)


        dottxt = astdot.gendot()
        time.sleep(0.1)
        test_num = 0
        open("astdot_testcase_%d.dot" % (test_num), 'w').write(dottxt)
        subprocess.call(["dot", "-Tpng", "-o", "astdot_testcase_%s.png" % (test_num),
                         "astdot_testcase_%s.dot" % (test_num)])
        subprocess.call(['rm', '-f', "astdot_testcase_%s.dot" % (test_num)])

    #@unittest.skip("skipping test as part of incremental test suite")
    def test_for_statement(self):
        text = """\
`for name in ["a", "b", "c"]
    `for ( idx = 2; idx < 5; idx++)
assign signal_`name::_`idx::_out = signal_`name::_`idx::_in; //// half line comment
/* Verilog block comment */
    `endfor
`endfor
"""

        (interpreter, astdot) = self.makeInterpreter(text)
        vtxt = interpreter.interpret()

        print("Generated output text:")
        print("==================================")
        print(vtxt + "==================================")
        globals = interpreter.GLOBAL_MEMORY
        self.assertEqual(globals['idx'], 5)

        dottxt = astdot.gendot()
        time.sleep(0.1)
        test_num = 0
        open("astdot_testcase_%d.dot" % (test_num), 'w').write(dottxt)
        subprocess.call(["dot", "-Tpng", "-o", "astdot_testcase_%s.png" % (test_num),
                         "astdot_testcase_%s.dot" % (test_num)])
        subprocess.call(['rm', '-f', "astdot_testcase_%s.dot" % (test_num)])

    #@unittest.skip("skipping test as part of incremental test suite")
    def test_if_statement(self):
        text = """\

//// whole line comment
    // verilog line comment 3
`let idx = 2
    // verilog line comment 4
`if (idx < 3)
    assign idx_eq_`idx::_lt_3 = 1'b1;   // half line Verilog comment 1
`else
    assign idx_eq_`idx::_lt_3 = 1'b0;   // half line Verilog comment 2
`endif
/* Verilog block comment */
`if (idx < 1)
assign idx_eq_`idx::_lt_1 = 1'b1;
`else
assign idx_eq_`idx::_lt_1 = 1'b0;
`endif

"""
        (interpreter, astdot) = self.makeInterpreter(text)
        vtxt = interpreter.interpret()


        print("Generated output text:")
        print("==================================")
        print(vtxt + "==================================")
        globals = interpreter.GLOBAL_MEMORY
        self.assertEqual(globals['idx'], 2)


        #dottxt = astdot.gendot()
        #time.sleep(0.1)
        #test_num = 0
        #open("astdot_testcase_%d.dot" % (test_num), 'w').write(dottxt)
        #subprocess.call(["dot", "-Tpng", "-o", "astdot_testcase_%s.png" % (test_num),
        #                 "astdot_testcase_%s.dot" % (test_num)])
        #subprocess.call(['rm', '-f', "astdot_testcase_%s.dot" % (test_num)])

    #@unittest.skip("skipping test as part of incremental test suite")
    def test_sample_vpp(self):
        text = """\
// `include "xp_search.vpph"
// reset fanout
logic [22-1:0]   rst_d;
mod_flop #(
    .width  (1),
    .mirror ($bits(rst_d))
) u_flop_rst
   (.d      (rst),
    .q      (rst_d),
    .rst    (1'b0),
    /*AUTOINST*/
);

// flow control memory pair
assign pair_dout_srdy[0] = tile_0_dout_srdy;
assign pair_dout_srdy[1] = tile_1_dout_srdy;
assign tile_0_dout_drdy  = pair_dout_drdy[0];
assign tile_1_dout_drdy  = pair_dout_drdy[1];
"""
        (interpreter, astdot) = self.makeInterpreter(text)
        vtxt = interpreter.interpret()


        print("Generated output text:")
        print("==================================")
        print(vtxt + "==================================")
        #globals = interpreter.GLOBAL_MEMORY
        #self.assertEqual(globals['idx'], 2)

if __name__ == '__main__':
    #unittest.main()
    suite = unittest.TestSuite()
    suite.addTest(InterpreterTestCase("test_integer_arithmetic_expressions"))
    runner = unittest.TextTestRunner()
    runner.run(suite)
