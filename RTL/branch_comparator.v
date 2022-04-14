// module: branch comparator
// Function: Generates the control signals for each one of the datapath resources

module branch_comparator(
      input wire [63:0] regfile_rdata_1,
      input wire [63:0] regfile_rdata_2,
      output reg branch_taken
   );

   always@(*) begin

      if (regfile_rdata_1 == regfile_rdata_2)  branch_taken = 1'b1;
      else branch_taken = 1'b0;

   end

endmodule
