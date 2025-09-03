#!/usr/local/bin/python3

import sd_jinja2 as sdjj
import argparse, os, logging, json
import yaml
import logging

parser = argparse.ArgumentParser(
            description='srdy/drdy lib Jinja2 template based generator'
         )
parser.add_argument('-s', '--source', type=str, dest='src',
        default="./templates/message.txt.pp",
        help='source file')
parser.add_argument('-t', '--target', type=str, dest='tgt',
        default="./output/message.txt",
        help='target file to be generated')
parser.add_argument('-c', '--config', type=str, dest='cfg',
        help='YAML file name to config variables to template')
parser.add_argument('-v', '--var', type=json.loads, dest='var',
        default={},
        help='Variables to template, this overrides the yaml configs, e.g. {"key0":"value0", "key1":1}')
parser.add_argument('-m', '--module', type=json.loads, dest='mod',
        default={},
        help='Python modules to template, this overrides the yaml configs, e.g. {"asName":"moduleName"}')
args = parser.parse_args()

logging.basicConfig()
logging.getLogger().setLevel(logging.DEBUG)
logger = logging.getLogger(__name__)
logger.info("Logger {}".format(__name__))

logger.debug("cfg file: {}".format(args.cfg))
g = sdjj.Generator(args.src)
g.gen(target = args.tgt,
      config_file = args.cfg,
      gen_vars = args.var,
      gen_mods = args.mod)
