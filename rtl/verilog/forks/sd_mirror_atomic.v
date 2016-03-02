// Copyright (c) 2012 XPliant, Inc -- All rights reserved
//-----------------------------------------------------------------------------
// sd_mirror_atomic.v
// 
// Description:
//      - A simple mirror (100% throughput) for forwarding the same output from 
//          a sender to multiple receivers. The sender only forwards data if
//          all receivers are ready to accept data.
//
//      - In the simplest case, the mirror design has no register inside, only logic. 
//          This may causes combo loop if the I/O of senders and receivers
//          don't have registers for timing closure.
//
//      - For timing closure and avoiding combo loop, 
//        set option values for c_closure and p_closure by:
//
//          + c_closure = 0: no timing closure at the comsuming side; 
//                          this option assumes the outputs of senders already 
//                          have sd_input or sd_output 
//                          (please double check the RTL of senders 
//                          before choosing this option).
//          + c_closure = 1: add sd_input at the consuming side
//          + c_closure = 2: add sd_output at the consuming side
//          + c_closure = 3: add sd_iofull at the consuming side
//
//      - Also consider to use sd_mirror.v which already support timing closure
// Author: Anh Tran
// Written: 2012/12/18
//  
//-----------------------------------------------------------------------------

`ifndef SD_MIRROR_ATOMIC_V
`define SD_MIRROR_ATOMIC_V
module sd_mirror_atomic 
    #(  parameter mirror_cnt=2,
        parameter width=32,
        parameter c_closure=0,
        parameter isinput = 0,  // if this mirror is at input of the block, set this to 1
        parameter p_closure=0 // no-applied
    )
    (

    input   clk,
    input   rst,
    
    input              c_srdy,
    output             c_drdy,
    input [width-1:0]  c_data,
    
    output [mirror_cnt-1:0] p_srdy,
    input [mirror_cnt-1:0]      p_drdy,
    output [width-1:0]  p_data

    /*AUTOINPUT*/    
    );

    logic ic_srdy;
    logic ic_drdy;
    logic [width-1:0]   ic_data;
    
    logic out_srdy;

    logic [mirror_cnt-1:0]  ip_srdy;
    logic [mirror_cnt-1:0]  ip_drdy;
    logic [width-1:0]   ip_data;
    
    //================== BODY ==================
    
    //----------- c_closure option
    generate
        case (c_closure)
            0:  begin:  c_closure_no
                assign ic_srdy = c_srdy;
                assign c_drdy = ic_drdy;
                assign ic_data = c_data;
            end
            1:  begin:  c_closure_sd_input
                sd_input #(.width(width))
                    ic_sd_input (
                        .clk (clk),
                        .reset (rst),
                        .c_srdy (c_srdy),
                        .c_drdy (c_drdy),
                        .c_data (c_data),

                        .ip_srdy (ic_srdy),
                        .ip_drdy (ic_drdy),
                        .ip_data (ic_data)
                    );
            end
            2:  begin:  c_closure_sd_output
                sd_output #(.width(width))
                    ic_sd_output (
                        .clk (clk),
                        .reset (rst),
                        .ic_srdy (c_srdy),
                        .ic_drdy (c_drdy),
                        .ic_data (c_data),

                        .p_srdy (ic_srdy),
                        .p_drdy (ic_drdy),
                        .p_data (ic_data)
                    );
            end
            3:  begin:  c_closure_sd_iofull
                sd_iofull #(.width(width),
                            .isinput (isinput)
                            )
                    ic_sd_iofull (
                        .clk (clk),
                        .reset (rst),
                        .c_srdy (c_srdy),
                        .c_drdy (c_drdy),
                        .c_data (c_data),

                        .p_srdy (ic_srdy),
                        .p_drdy (ic_drdy),
                        .p_data (ic_data)
                    );
            end
        endcase
    endgenerate
    
    //----------- internal logic
    assign ic_drdy = &(ip_drdy);
    
    assign out_srdy = ic_srdy & ic_drdy;
    
    genvar i;
    generate
        for(i=0; i<mirror_cnt; i=i+1) begin: ip_srdy_i
//            assign p_srdy[i] = c_srdy & (c_drdy | ~p_drdy[i]);
            assign ip_srdy[i] = out_srdy;
        end
    endgenerate

    assign ip_data = ic_data;

    //======== DON'T SUPPORT P_CLOSURE AT OUTPUT OF MIRROR_SIMPLE 
    //         (WILL NOT WORK BECAUSE MULTIPLE OUTPUT PATHS CANNOT SHARE THE SAME A P_CLOSURE CELL)
    
    assign p_srdy = ip_srdy;
    assign ip_drdy = p_drdy;
    
    assign p_data = ip_data;
    
//     //----------- p_closure
//     generate
//         case (p_closure)    
//             0: begin:   p_closure_no
//                 for(i=0; i<mirror_cnt; i=i+1) begin: p_closure_no_i
//                     assign p_srdy[i] = ip_srdy[i];
//                     assign ip_drdy[i] = p_drdy[i];
//                 end
//                 assign p_data = ip_data;
//             end
//             1: begin:   p_closure_sd_input
//                     sd_input #(.width(width))
//                         ip_sd_input_0 (
//                             .clk (clk),
//                             .reset (rst),
//                             .c_srdy (ip_srdy[0]),
//                             .c_drdy (ip_drdy[0]),
//                             .c_data (ip_data),
// 
//                             .ip_srdy (p_srdy[0]),
//                             .ip_drdy (p_drdy[0]),
//                             .ip_data (p_data)
//                         );                    
//             
//                 for(i=1; i<mirror_cnt; i=i+1) begin: p_closure_sd_input_i
//                     sd_input #(.width(1))   // dont care about data
//                         ip_sd_input_i (
//                             .clk (clk),
//                             .reset (rst),
//                             .c_srdy (ip_srdy[i]),
//                             .c_drdy (ip_drdy[i]),
//                             .c_data (1'b0), // dont' care
// 
//                             .ip_srdy (p_srdy[i]),
//                             .ip_drdy (p_drdy[i]),
//                             .ip_data ()     // don't need; share p_data with p0
//                         );                    
//                 end
//             end
//             2: begin:   p_closure_sd_output
//                     sd_output #(.width(width))
//                         ip_sd_output_0 (
//                             .clk (clk),
//                             .reset (rst),
//                             .ic_srdy (ip_srdy[0]),
//                             .ic_drdy (ip_drdy[0]),
//                             .ic_data (ip_data),
// 
//                             .p_srdy (p_srdy[0]),
//                             .p_drdy (p_drdy[0]),
//                             .p_data (p_data)
//                         );
//             
//                 for(i=1; i<mirror_cnt; i=i+1) begin: p_closure_sd_output_i
//                     sd_output #(.width(1))  // dont care about data
//                         ip_sd_output_i (
//                             .clk (clk),
//                             .reset (rst),
//                             .ic_srdy (ip_srdy[i]),
//                             .ic_drdy (ip_drdy[i]),
//                             .ic_data (1'b0),
// 
//                             .p_srdy (p_srdy[i]),
//                             .p_drdy (p_drdy[i]),
//                             .p_data ()  // don't need; share p_data with p0
//                         );
//                 
//                 end
//             end
// //             3: begin:   p_closure_sd_iofull
// //                     sd_iofull #(.width(width))
// //                         ip_sd_iofull_0 (
// //                             .clk (clk),
// //                             .reset (rst),
// //                             .c_srdy (ip_srdy[0]),
// //                             .c_drdy (ip_drdy[0]),
// //                             .c_data (ip_data),
// // 
// //                             .p_srdy (p_srdy[0]),
// //                             .p_drdy (p_drdy[0]),
// //                             .p_data (p_data)
// //                         );
// //                         
// //                 for(i=1; i<mirror_cnt; i=i+1) begin: p_closure_sd_iofull_i
// //                 sd_iofull #(.width(1))  // dont care about data
// //                     ic_sd_iofull_i (
// //                         .clk (clk),
// //                         .reset (rst),
// //                         .c_srdy (ip_srdy[i]),
// //                         .c_drdy (ip_drdy[i]),
// //                         .c_data (1'b0),
// // 
// //                         .p_srdy (p_srdy[i]),
// //                         .p_drdy (p_drdy[i]),
// //                         .p_data ()  // dont care
// //                     );                
// //                 end
// //             end
//         endcase
//     endgenerate
    
//     sd_mirror #( .mirror(mirror_cnt),
//                     .width(width)
//                    )
//         internal_mirror (
//             .clk (clk),
//             .reset (rst),
// 
//             .c_srdy (c_srdy),
//             .c_drdy (c_drdy),
//             .c_data (c_data),
//             .c_dst_vld ({mirror_cnt{1'b0}}),
// 
//             .p_srdy (p_srdy),
//             .p_drdy (p_drdy),
//             .p_data (p_data)
//         );
    
endmodule
`endif // SD_MIRROR_ATOMIC_V
