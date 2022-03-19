//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,

		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag, zero_flag_EXE_MEM;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;
wire [      31:0] instruction;
wire [       1:0] alu_op, alu_op_ID_EXE;
wire [       3:0] alu_control;
wire              reg_dst,branch, branch_ID_EXE, branch_EXE_MEM,mem_read, mem_read_ID_EXE, mem_read_EXE_MEM,
				  mem_2_reg, mem_2_reg_ID_EXE, mem_2_reg_EXE_MEM, mem_2_reg_MEM_WB,
                  mem_write,mem_write_ID_EXE, mem_write_EXE_MEM, alu_src, alu_src_IDE_EXE, reg_write, reg_write_ID_EXE, reg_write_EXE_MEM, reg_write_MEM_WB, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata_MEM_WB,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2, regfile_rdata_2_EXE_MEM,
                  alu_operand_2;

wire signed [63:0] immediate_extended, immediate_extended_ID_EXE;

// instruction
wire [31:0] instruction_IF_ID;
wire [9:0] instruction_ID_EXE,
wire [4:0] instruction_EXE_MEM, instruction_MEM_WB;

// ALU
wire [63:0] alu_out_EXE_MEM;

// register file
wire [63:0]  regfile_rdata_1_ID_EXE, regfile_rdata_2_ID_EXE;

// program counter
wire [63:0] branch_pc_EXE_MEM, jump_pc_EXE_MEM, updated_pc_IF_ID, updated_pc_ID_EXE;

// WB
wire [63:0] mem_data_MEM_WB, alu_out_MEM_WB;

///////// IF stage begin

// program counter
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc_EXE_MEM ),
   .jump_pc   (jump_pc_EXE_MEM   ),
   .zero_flag (zero_flag_EXE_MEM ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

// The instruction memory.
sram_BW32 #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ),
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

///////// IF stage end

///////// IF_ID REG BEGIN

// IF_ID Pipeline register for updated program counter Signal
reg_arstn_en #(
	.DATA_W(64)
	)reg_updated_pc(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din (updated_pc),
		 .dout (updated_pc_IF_ID)
);

// IF_ID Pipeline register for write address instruction Signal
reg_arstn_en #(
	.DATA_W(32)
	)reg_instruction(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din (instruction),
		 .dout (instruction_IF_ID)
);

///////// IF_ID REG END


///////// ID STAGE BEGIN

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);

control_unit control_unit(
   .opcode   (instruction[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write_MEM_WB      ),
   .raddr_1  (instruction_IF_ID[19:15]),
   .raddr_2  (instruction_IF_ID[24:20]),
   .waddr    (instruction_MEM_WB),
   .wdata    (regfile_wdata_MEM_WB    ),
   .rdata_1  (regfile_rdata_1),
   .rdata_2  (regfile_rdata_2)
);

///////// ID STAGE END


///////// ID_EX REG BEGIN

// immediate pipeline register
reg_arstn_en #(
	.DATA_W(64)
	)reg_im_ext(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din (immediate_extended),
		 .dout (immediate_extended_ID_EXE)
);

// ID_EXE Pipeline register for program counter Signal
reg_arstn_en #(
	.DATA_W(64)
	)reg_updated_pc_IF_ID(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din (updated_pc_IF_ID),
		 .dout (updated_pc_ID_EXE)
);

// ID_EXE Pipeline register for instruction Signal
reg_arstn_en #(
	.DATA_W(10)
	)reg_instruction_ID_EXE(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din ({ instruction_IF_ID[30], instruction_IF_ID[25], instruction_IF_ID[14:12], instruction_IF_ID[11:7] }),
		 .dout (instruction_ID_EXE)
);

// ID_EXE Pipeline register for rdata Signal
reg_arstn_en #(
	.DATA_W(128)
	)reg_regfile_rdata(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din ({regfile_rdata_1, regfile_rdata_2}),
		 .dout ({regfile_rdata_1_ID_EXE, regfile_rdata_2_ID_EXE})
);

// ID_EXE Pipeline register for control signals
reg_arstn_en #(
	.DATA_W(8)
	)reg2_control(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din ({reg_write, mem_2_reg, mem_write, mem_read, branch, alu_src, alu_op}),
		 .dout ({reg_write_ID_EXE, mem_2_reg_ID_EXE, mem_write_ID_EXE, mem_read_ID_EXE, branch_ID_EXE, alu_src_ID_EXE, alu_op_ID_EXE})
);

///////// ID_EX REG END


///////// EX STAGE BEGIN

alu_control alu_ctrl(
   .func7_5       (instruction_ID_EXE[9]  ),
	 .funct7_0		(instruction_ID_EXE[8]),
   .func3          (instruction[7:5]),
   .alu_op         (alu_op_ID_EXE    ),
   .alu_control    (alu_control      )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EXE),
   .input_b (regfile_rdata_2_ID_EXE   ),
   .select_a (alu_src_IDE_EXE          ),
   .mux_out (alu_operand_2     )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (regfile_rdata_1_ID_EXE ),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(zero_flag       ),
   .overflow (                )
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (updated_pc_ID_EXE     ),
   .immediate_extended (immediate_extended_ID_EXE),
   .branch_pc          (branch_pc         ),
   .jump_pc            (jump_pc           )
);

///////// EX STAGE END


///////// EX_MEM REG BEGIN

// EXE_MEM Pipeline register for write address instruction Signal
reg_arstn_en #(
	.DATA_W(5)
	)reg_instruction_EXE_MEM(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din (instruction_ID_EXE),
		 .dout (instruction_EXE_MEM)
);

// ALU + zero flag pipeline reg
reg_arstn_en #(
	.DATA_W(65)
	)reg_ALU_zero_flag(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din ({zero_flag, alu_out}),
		 .dout ({zero_flag_EXE_MEM, alu_out_EXE_MEM})
);

// EXE_MEM Pipeline register for immediate extend signal
reg_arstn_en #(
	.DATA_W(64)
	)reg3_imm_extend(
		 .clk	(clk),
		 .arst_n(arst_n),
		 .en	(enable),
		 .din (regfile_rdata_2_ID_EXE),
		 .dout (regfile_rdata_2_EXE_MEM)
);

// EX_MEM Pipeline register for branch_pc and jump_pc Signal
reg_arstn_en #(
	.DATA_W(128)
	)reg_branch_unit_EXE_MEM(
		 .clk	(clk),
		 .arst_n(arst_n),
		 .en	(enable),
		 .din ({branch_pc, jump_pc}),
		 .dout ({branch_pc_EXE_MEM, jump_pc_EXE_MEM})
);

// EX_MEM Pipeline register for control signals
reg_arstn_en #(
	.DATA_W(5)
	)reg3_control(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din ({reg_write_ID_EXE, mem_2_reg_ID_EXE, mem_write_ID_EXE, mem_read_ID_EXE, branch_ID_EXE}),
		 .dout ({reg_write_EXE_MEM, mem_2_reg_EXE_MEM, mem_write_EXE_MEM, mem_read_EXE_MEM, branch_EXE_MEM})
);

///////// EX_MEM REG END


///////// MEM STAGE BEGIN

// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_EXE_MEM),
   .wen      (mem_write_EXE_MEM),
   .ren      (mem_read_EXE_MEM),
   .wdata    (regfile_rdata_2_EXE_MEM),
   .rdata    (mem_data       ),
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

///////// MEM STAGE END


///////// MEM_WB REG BEGIN

// MEM_WB Pipeline register for instruction Signal
reg_arstn_en #(
	.DATA_W(5)
	)reg_instruction_MEM_WB(
		 .clk	(clk),
		 .arst_n	(arst_n),
		 .en	(enable),
		 .din (instruction_EXE_MEM),
		 .dout (instruction_MEM_WB)
);

// MEM_WB Pipeline register for mem data
reg_arstn_en #(
	.DATA_W(64)
	)reg_mem_data_MEM_WB(
		 .clk	(clk),
		 .arst_n(arst_n),
		 .en	(enable),
		 .din (mem_data),
		 .dout (mem_data_MEM_WB)
);

// MEM_WB Pipeline register for ALU data
reg_arstn_en #(
	.DATA_W(64)
	)reg_alu_out_MEM_WB(
		 .clk	(clk),
		 .arst_n(arst_n),
		 .en	(enable),
		 .din (alu_out_EXE_MEM),
		 .dout (alu_out_MEM_WB)
);

// MEM_WB Pipeline register for control signals
reg_arstn_en #(
	.DATA_W(2)
	)reg_control_MEM_WB(
		 .clk	(clk),
		 .arst_n(arst_n),
		 .en	(enable),
		 .din ({reg_write_EXE_MEM, mem_2_reg_EXE_MEM}),
		 .dout ({reg_write_MEM_WB, mem_2_reg_MEM_WB})
);

///////// MEM_WB REG END


///////// WB STAGE BEGIN

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_MEM_WB     ),
   .input_b  (alu_out_MEM_WB      ),
   .select_a (mem_2_reg_MEM_WB    ),
   .mux_out  (regfile_wdata_MEM_WB)
);

///////// WB STAGE END


endmodule
