module Instruct_Memory(Address, Instruct);				//指令存储器
	input [9:0] Address;
	output [31:0] Instruct;
	
	reg [31:0] temp;
	reg [31:0] instruct_memory[1023:0];
	
	always@(Address)
	begin
		temp = instruct_memory[Address];
	end
	
	assign Instruct = temp;
endmodule