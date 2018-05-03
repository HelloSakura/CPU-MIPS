//PC所有模块

module Enable_Clk_Rom32(IN, Clk, Reset, Write_En, Out);          //一个元器件，支持reset，clk信号，写使能
    input wire Clk, Reset, Write_En;            //Write_En写使能
    input wire [31:0] IN;
    output reg [31:0] Out;

    always@(posedge Clk or negedge Reset) begin
      if(0 == Reset) begin
          Out = 32'b0;
      end
      else begin
          if(Write_En)
             Out = IN;
      end
    end
endmodule  


module PC_Transfer(O_PC, T_Addr, PC);       //用于beq和bne指令
    input [31:0] O_PC;
    input [15:0] T_Addr;
    output [31:0] PC;

    wire [31:0] temp;                //存储T_Addr移位结果
    
    assign temp = {14'b0, T_Addr[15:0], 2'b0};      //移位后结果

    assign PC = O_PC + temp;
endmodule

module PC_Jump(O_PC, Shift_addr, PC);                 //jump指令使用，Shift_addr即跳转指令的低26位
    input [31:0] O_PC;
    input [25:0] Shift_addr;
    output [31:0] PC;

    assign PC = {O_PC[31:28], Shift_addr[25:0]};
endmodule