// Module forwarding unit

module forwarding_unit(
        input wire [4:0] Rs1_ID_EXE,
        input wire [4:0] Rs2_ID_EXE,
        input wire [4:0] Rd_EXE_MEM,
        input wire [4:0] Rd_MEM_WB,
        input wire reg_write_EXE_MEM,
        input wire reg_write_MEM_WB,
        output reg alu_forward_A,
        output reg alu_forward_B
     );

     always@(*) begin
        // EXE_MEM data hazard


        // MEM_WB data hazard

     end
endmodule
