import jinja2
import logging, sys, os, yaml
import math, re, textwrap

logging.basicConfig()
logging.getLogger().setLevel(logging.INFO)
logging.getLogger().setLevel(logging.DEBUG)
logger = logging.getLogger(__name__)
logger.info("Logger {}".format(__name__))
class Environment(jinja2.Environment):
    def __init__(self, *args, **kwargs):
        # logging.basicConfig()
        # logging.getLogger().setLevel(logging.INFO)
        # self.logger = logging.getLogger(__name__)
        # self.logger.info(f"Logger {__name__}")
        jinja2.Environment.__init__(
                self,
                trim_blocks = True,
                variable_start_string = "{{",
                variable_end_string = "}}",
                line_statement_prefix = "`#",
                *args,
                **kwargs
                )
        self.undefined = jinja2.StrictUndefined

class Generator():
    def __init__(self, source):
        # logging.basicConfig()
        # logging.getLogger().setLevel(logging.INFO)
        # logging.getLogger().setLevel(logging.DEBUG)
        # self.logger = logging.getLogger(__name__)
        # self.logger.info("Logger {}".format(__name__))
        try:
            src_dir = os.path.dirname(source)
            src_file = os.path.basename(source)
            logger.debug(f"source dir: {src_dir}")
            logger.debug(f"source file: {src_file}")
            self.env = Environment(loader=jinja2.FileSystemLoader(src_dir))
            self.template = self.env.get_template(src_file)
        except:
            logger.error(f"can not load template {source}")

    def gen(self, target, config_file, gen_vars, gen_mods):
        _render_vars = {}
        _import_mods = {}
        _import_key_word = "imports"

        if config_file is not None:
            with open(config_file, 'r') as f:
                parsed_cfg = yaml.safe_load(f)
                for mod_as, mod_from in parsed_cfg[_import_key_word].items():
                    _import_mods[mod_as] = mod_from
                    logger.debug(f"CFG: {mod_as} = to_import_from({mod_from})")
                for vname, vval in parsed_cfg.items():
                    if vname != _import_key_word:
                        _render_vars[vname] = vval
                        logger.debug(f"CFG: {vname} = {vval}")

        for mod_as, mod_from in gen_mods.items():
            _import_mods[mod_as] = mod_from
            logger.debug(f"MOD: {mod_as} = to_import_from({mod_from})")

        for mod_as, mod_from in _import_mods.items():
            _render_vars[mod_as] = __import__(mod_from)
            logger.debug(f"IMPORT: {mod_as} = __import__({mod_from})")
        for vname, vval in gen_vars.items():
            _render_vars[vname] = vval
            logger.debug(f"VAR: {vname} = {vval}")
        logger.debug(_render_vars)

        content = self.template.render(_render_vars)
        logger.debug(f"==========generated content==============\n{content}")
        with open(target, mode="w", encoding="utf-8") as message:
            message.write(content)
            logger.info(f"... wrote to {target}")

def clog2(v): return int ( math.ceil ( math.log(v) / math.log(2) ) )

class svSig():
    def __init__(self, sig=["foo", "logic", 1]):
        self.sname = "ERROR_wrong_svSig"
        stype = "logic"
        swidth = 1
        self.sig = sig
        if (len(sig) == 3):
            (self.sname, stype, swidth) = sig
        elif (len(sig) == 2):
            (self.sname, stype) = sig
        elif (len(sig) == 1):
            self.sname = sig[0]

        if isinstance(swidth, int) and swidth == 1:
            self.type_str = f"{stype}"
        else:
            self.type_str = f"{stype} [{swidth}-1:0]"

    def get_decl(self, prefix="", direction="", reverse=False):
        line_end = ","
        if direction.startswith("i"):
            port_dir = "input  " if not reverse else "output "
        elif direction.startswith("o"):
            port_dir = "output " if not reverse else "input  "
        elif direction.startswith("d") or direction == "":
            port_dir = ""
            line_end = ";"
        else:
            port_dir = "ERROR: unrecogonized direction (input/output/declaration)"

        if prefix != "":
            prfx_str = prefix + "_"
        else:
            prfx_str = ""
        decl_str = f"{port_dir}{self.type_str:25} {prfx_str}{self.sname}{line_end}"
        return decl_str

    def __str__(self):
        return f"{self.sig[0]}::{self.type_str}"

class svIntf():
    _registry = []

    def __init__(self, name="", sigs=[], valids=[], readys=[], struct=False, pkg="", indent=2):
        self.sigs = []
        self.valids = []
        self.readys = []
        for sig in sigs:
            self.sigs.append(svSig(sig))
        for sig in valids:
            self.valids.append(svSig(sig))
        for sig in readys:
            self.readys.append(svSig(sig))
        self.name = name
        self.init_struct = struct
        self.pkg = pkg
        self.sv_struct_name = f"{name}_sv"
        self.description = ""
        self.indent = indent
        self._registry.append(self)
        if name == "":
            self.struct = False
            logger.error(f"interface without name should not be used as struct {self}")
        elif len(self.sigs) <= 1:
            self.struct = False
        else:
            self.struct = struct

    def __str__(self):
        intf_strs = []
        for sig in self.sigs:
            intf_strs.append(f"{sig}")
        return f"svIntf {self.name} with {len(self.sigs)} signals: {sig_str.join(',')}"

    def add_sig(self, name="foo", t="logic", sz=1):
        self.sigs.append(svSig([name, t, sz]))
        if len(self.sigs) > 1:
            self.struct = self.init_struct

    def set_description(self, desc=""):
        self.description = re.sub(r"[\n \t]+", " ", desc)
        self.description = self.description.lstrip()
        self.description = self.description.rstrip()

    def get_description(self, indent=None):
        indent = self.indent if indent is None else indent
        desc_str = ""
        if self.description != "":
            desc_str = " " * indent + "// "
            desc_str += textwrap.fill(self.description, width = 75,
                      subsequent_indent = " " * indent + "//   ",
                      break_long_words = False)
        return desc_str

    def get_decl(self, direction="", prefix="", struct=None, pkg=None, indent=None, rstrip=False):
        struct = self.struct if struct is None else struct
        pkg = self.pkg if pkg is None else pkg
        indent = self.indent if indent is None else indent

        decl_str = []
        desc_str = self.get_description(indent=indent)
        if ( (desc_str != "") and
                (direction.startswith("i") or direction.startswith("o")) ):
            decl_str.append(desc_str)

        for sig in self.valids:
            decl_str.append(' ' * indent + sig.get_decl(prefix, direction))
        for sig in self.readys:
            decl_str.append(' ' * indent + sig.get_decl(prefix, direction, reverse=True))

        if struct and pkg != "":
            type_str = pkg + "::" + self.sv_struct_name
            sig = svSig(["data", type_str])
            decl_str.append(' ' * indent + sig.get_decl(prefix, direction))
        else:
            for sig in self.sigs:
                decl_str.append(' ' * indent + sig.get_decl(prefix, direction))

        if rstrip:
            decl_str[-1] = decl_str[-1][:-1]

        return "\n".join(decl_str)

    def get_struct(self, indent=2):
        indent = self.indent if indent is None else indent
        struct_str = "typedef struct packed {\n"
        for sig in self.sigs:
            struct_str += " " * indent
            struct_str += sig.get_decl(prefix="", direction="d") + "\n"
        struct_str += "} " + self.sv_struct_name + ";"
        return struct_str


class sdIntf(svIntf):
    def __init__(self, name="", sigs=[], valids=[], readys=[], struct=False, pkg="", indent=2):
        super().__init__(name, sigs,
                         valids=[["srdy", "logic"]],
                         readys=[["drdy", "logic"]],
                         struct=struct, pkg=pkg, indent=indent)
