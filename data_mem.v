//数据存储器
module Data_Memory(Write, Address, DataIn, DataOut);
    input [31:0] Address, DataIn;
    input Write;
    
    output [31:0] DataOut;
    reg [31:0] DataOut;
    
    reg [31:0] data_memory[1023:0];
    always@(Address or DataIn) begin
          if(1 == Write) begin
              data_memory[Address] = DataIn;
          end

          DataOut = data_memory[Address];
        end
endmodule