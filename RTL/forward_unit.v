// Module forward_unit

module forward_unit(
        input wire [4:0] Rs1_ID_EXE,
        input wire [4:0] Rs2_ID_EXE,
        input wire [4:0] Rd_EXE_MEM,
        input wire [4:0] Rd_MEM_WB,
        input wire reg_write_EXE_MEM,
        input wire reg_write_MEM_WB,
        output reg [1:0] alu_forward_A,
        output reg [1:0] alu_forward_B
     );

     always@(*) begin

        // alu_forward_A
    		if(reg_write_EXE_MEM && (Rd_EXE_MEM != 0) && (Rd_EXE_MEM == Rs1_ID_EXE))
    			alu_forward_A = 2'b10;

    		else if (reg_write_MEM_WB && (Rd_MEM_WB != 0) && !(reg_write_EXE_MEM && (Rd_EXE_MEM!=0) && (Rd_EXE_MEM==Rs1_ID_EXE)) && (Rd_MEM_WB == Rs1_ID_EXE))
    			alu_forward_A = 2'b01;

    		else alu_forward_A = 2'b00;


        // alu_forward_B
        if(reg_write_EXE_MEM && (Rd_EXE_MEM != 0) && (Rd_EXE_MEM == Rs2_ID_EXE))
    			alu_forward_B = 2'b10;

    		else if(reg_write_MEM_WB && (Rd_MEM_WB != 0) && !(reg_write_EXE_MEM && (Rd_EXE_MEM!=0) && (Rd_EXE_MEM==Rs1_ID_EXE)) && (Rd_MEM_WB == Rs2_ID_EXE))
    			alu_forward_B = 2'b01;

    		else alu_forward_B = 2'b00;

     end

endmodule
