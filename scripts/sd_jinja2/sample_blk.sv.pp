`# set cfgs = None if sample_blk is not defined else sample_blk
package sample_pkg;

typedef struct packed {
  logic magic0;
  logic magic1;
} magic_type_sv;

{{ cfgs.intf_data.get_struct() }}

endpackage

module sample_blk (
  input logic clk,
  input logic rst,
{{ cfgs.intf_data.get_decl(direction="input", prefix="c", 
                            struct=True, pkg="sample_pkg", indent=2) }}
{{ cfgs.intf_data.get_decl(direction="output", prefix="p", indent=2, rstrip=True) }}
);

{{ cfgs.intf_data.get_decl(direction="declaration", prefix="i0", indent=0) }}

{{ cfgs.intf_data.get_decl(direction="declaration", prefix="i1",
                           struct=True, pkg="sample_pkg", indent=0) }}

endmodule
