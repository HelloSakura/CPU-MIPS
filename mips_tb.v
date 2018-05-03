module MIPS_tb();

   reg clk, rst;
    
   pipelineCpu U_MIPS(.Clock(clk), .memClock(), .Reset(rst), .PC(), .inst(), .ealu(), .malu(), .walu());
    
   initial begin
      $readmemh( "code.txt" , U_MIPS.if_stage.mem.instruct_memory);
      $monitor("PC = 0x%8X, IR = 0x%8X", U_MIPS.PC, U_MIPS.inst); 
      clk = 0;
      rst = 0;
      #5;
      clk = 1;
      #5;
      rst = 1;
      #5;
   end
   
   always
	   #(50) clk = ~clk;

endmodule

