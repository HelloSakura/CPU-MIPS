module Register_File(Rs, Rt, Reg_Wb, WriteData, Write, Clk, DataOut_1, DataOut_2);
	input [4:0] Rs;
	input [4:0] Rt;
	input [4:0] Reg_Wb;				//the write back regiter id 
	input [31:0] WriteData;
	input Write, Clk;
	
	output [31:0] DataOut_1;
	output [31:0] DataOut_2;
	
	reg [31:0] regiter_file[31:0];
	
	always@(posedge Clk)
	begin
		if(1 == Write) begin
			regiter_file[Reg_Wb] = WriteData;
		end
		$display("R[00-07]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", 0, regiter_file[1], regiter_file[2], regiter_file[3], regiter_file[4], regiter_file[5], regiter_file[6], regiter_file[7]);
        $display("R[08-15]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", regiter_file[8], regiter_file[9], regiter_file[10], regiter_file[11], regiter_file[12], regiter_file[13], regiter_file[14], regiter_file[15]);
        $display("R[16-23]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", regiter_file[16], regiter_file[17], regiter_file[18], regiter_file[19], regiter_file[20], regiter_file[21], regiter_file[22], regiter_file[23]);
        $display("R[24-31]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", regiter_file[24], regiter_file[25], regiter_file[26], regiter_file[27], regiter_file[28], regiter_file[29], regiter_file[30], regiter_file[31]);
        $display("R_write[%5X]=%8X R_in1[%5X]=%8X, R_in2[%5X]=%8X", Reg_Wb, regiter_file[Reg_Wb], Rs, regiter_file[Rs], Rt, regiter_file[Rt]);
	end
	
	assign DataOut_1 = (0 == Rs) ? 0 : regiter_file[Rs];
	assign DataOut_2 = (0 == Rt) ? 0 : regiter_file[Rt];
	
endmodule