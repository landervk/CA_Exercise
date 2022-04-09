// Module hazard detection

module hazard_detection_unit(
        input wire mem_read_ID_EXE,
        input wire [4:0] Rd_ID_EXE,
        input wire [4:0] Rs1_IF_ID,
        input wire [4:0] Rs2_IF_ID,
        input wire enable,
        output reg PCWrite,
        output reg IFIDWrite,
        output reg stallControl
     );

     always@(*) begin

         if (mem_read_ID_EXE && ((Rd_ID_EXE == Rs1_IF_ID) || (Rd_ID_EXE == Rs2_IF_ID))) begin

            PCWrite = 1'b0;
            IFIDWrite = 1'b0;
            stallControl = 1'b0;

         end else begin

             PCWrite = enable;
             IFIDWrite = enable;
             stallControl = 1'b1;

         end
     end

endmodule
