netlist clock clk -period 10
formal netlist constraint reset 1'b0

formal compile -d wrap_fifo_c -cuname fv_top
formal verify -effort unlimited -timeout 30m

