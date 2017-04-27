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
from vppy_lexer import Token, Lexer

setVppGlobalVars()
logger = logging.getLogger("vppy.Preprocessor")
#logger.setLevel(logging.DEBUG)

class Preprocessor(object):
    def __init__(self, lines, fname):
        # client string input, e.g. "4 + 2 * 3 - 6 / 2"
        self.lines = lines
        self.pp_lines = []
        # self.pos is an index into self.text
        self.fname = fname
        self.line_num = 1
        self.process(self.lines, self.fname+':')
        #print("Proprocessor pp_lines: %s"%(self.pp_lines))

    def process(self, lines, meta):
        vblk_comment_start_patt = re.compile(r"\/\*")
        vblk_comment_end_patt = re.compile(r"\*\/")
        inc_file_patt = re.compile(r"^[ \t]*`include[ \t]+\"(\S+)\"")
        v_comment_st = False

        line_num = 0
        for line in lines:
            line_num += 1
            l_meta = "%s%s"%(meta,line_num)
            print("%s::%s::%s"%(l_meta,v_comment_st,line))
            if not v_comment_st and inc_file_patt.search(line):
                m = inc_file_patt.search(line)
                inc_f_name = m.group(1)
                inc_lines = open(inc_f_name,'r').readlines()
                self.process(inc_lines, l_meta+'/'+inc_f_name+':')
                sub_line = inc_file_patt.sub("",line)
                self.pp_lines.append({'meta':l_meta, 'text':sub_line})
            else:
                self.pp_lines.append({'meta': l_meta, 'text': line})


            if vblk_comment_start_patt.search(line) and not vblk_comment_end_patt.search(line):
                v_comment_st = True
            elif vblk_comment_end_patt.search(line):
                v_comment_st = False



