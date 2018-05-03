//流水线寄存器实现

//PC register
module PC_Reg(Next_PC, Clk, Reset, Write_En, PC);
    input [31:0] Next_PC;
    input Write_En, Clk, Reset;
    output [31:0] PC;

    Enable_Clk_Rom32 program_counter(Next_PC, Clk, Reset, Write_En, PC);
endmodule

//IR register
module IR_Reg(Next_PC_4, Next_Instruct, Write_En, Clk, Reset, PC_4, Instrcut);
//Next_Instruct -> Instruct 根据En和Reset信号更新Instruct的值
    input [31:0] Next_PC_4, Next_Instruct;
    input Clk, Reset, Write_En;
    output reg [31:0] PC_4, Instrcut;

    wire [31:0] trans_pc, trans_instruct;
   

    

    Enable_Clk_Rom32 instr_reg(Next_Instruct, Clk, Reset, Write_En, trans_instruct);
    Enable_Clk_Rom32 pc_plus4_reg(Next_PC_4, Clk, Reset, Write_En, trans_pc);
   
    always@(posedge Clk or negedge Reset) begin
        if(0 == Reset) begin
            PC_4 <= 32'h3000;
            Instrcut = 32'h0;
        end else begin
          PC_4 = trans_pc;
          Instrcut = trans_instruct;
        end
    end

endmodule // IF_Reg

//ID/EXE register
module ID_EXE_Reg(
    Write_Reg_En, Write_Mem_En, Mem_to_Reg, 
    Alu_Code, Alu_idata, DataIn_1, DataIn_2, idata, 
    Dst_id, Shift, jal, D_PC_4, 
    E_Write_Reg_En, E_Write_Mem_En, E_Mem_to_Reg,
    E_Alu_Code, E_Alu_idata, E_DataIn_1, E_DataIn_2, E_idata,
    E_Dst_id, E_Shift, E_jal, E_PC_4,
    Clk, Reset
);
/* Unkown Signal
Shift/E_Shift: 
D_PC_4: 
Alu_idata: reg choose signal
*/

    input [31:0] DataIn_1, DataIn_2, idata, D_PC_4;
    input [4:0] Dst_id;
    input [3:0] Alu_Code;
    input Write_Mem_En, Write_Reg_En, Mem_to_Reg, Alu_idata, Shift, jal;


    output [31:0] E_DataIn_1, E_DataIn_2, E_idata, E_PC_4;
    output [4:0] E_Dst_id;
    output [3:0] E_Alu_Code;
    output E_Write_Mem_En, E_Write_Reg_En, E_Mem_to_Reg, E_Alu_idata, E_Shift, E_jal;


    input Clk, Reset;


    reg [31:0] E_DataIn_1, E_DataIn_2, E_idata, E_PC_4;
    reg [4:0] E_Dst_id;
    reg [3:0] E_Alu_Code;
    reg E_Write_Mem_En, E_Write_Reg_En, E_Mem_to_Reg, E_Alu_idata, E_Shift, E_jal;


    always@(posedge Clk or negedge Reset)
        if(0 == Reset) begin
            E_DataIn_1 <= 0;    E_DataIn_2 <= 0;    E_idata <= 0;   E_PC_4 = 0;
            E_Dst_id <= 0;      E_Alu_Code <= 0;
            E_Write_Mem_En <= 0;    E_Write_Reg_En <= 0;    E_Mem_to_Reg <= 0;      
            E_Alu_idata <= 0;   E_Shift <= 0;   E_jal <= 0;
        end
        else begin
            E_DataIn_1 <= DataIn_1;    E_DataIn_2 <= DataIn_2;    E_idata <= idata;     E_PC_4 = D_PC_4;
            E_Dst_id <= Dst_id;      E_Alu_Code <= Alu_Code;
            E_Write_Mem_En <= Write_Mem_En;    E_Write_Reg_En <= Write_Reg_En;    E_Mem_to_Reg <= Mem_to_Reg;      
            E_Alu_idata <= Alu_idata;   E_Shift <= Shift;   E_jal <= jal;
        end

endmodule // ID_EXE_Reg


//EXE/MEM register
module EXE_MEM_Reg(
    E_Write_Reg_En, E_Write_Mem_En, E_Mem_to_Reg,  Alu_Result, E_Mem_In, E_Dst_id, 
    M_Write_Reg_En, M_Write_Mem_En, M_Mem_to_Reg,  M_Alu_Result, M_Mem_In, M_Dst_id,
    Clk, Reset  
);
/*Signal Used
M_Mem_In: the data write to memory, such instruct #lw $1, 0($2) 
*/

    input [31:0] Alu_Result, E_Mem_In;
    input [4:0] E_Dst_id;
    input E_Write_Mem_En, E_Write_Reg_En, E_Mem_to_Reg;

    output [31:0] M_Alu_Result, M_Mem_In;
    output [4:0] M_Dst_id;
    output M_Write_Mem_En, M_Write_Reg_En, M_Mem_to_Reg;

    input Clk, Reset;

    reg [31:0] M_Alu_Result, M_Mem_In;
    reg [4:0] M_Dst_id;
    reg M_Write_Mem_En, M_Write_Reg_En, M_Mem_to_Reg;

    always@(posedge Clk or negedge Reset)
        if(0 == Reset) begin
            M_Alu_Result <= 0;      M_Mem_In <= 0;      M_Dst_id <= 0;
            M_Write_Mem_En <= 0;    M_Write_Reg_En <= 0;    M_Mem_to_Reg <= 0;
        end
        else begin
            M_Alu_Result <= Alu_Result;      M_Mem_In <= E_Mem_In;      M_Dst_id <=E_Dst_id;
            M_Write_Mem_En <= E_Write_Mem_En;    M_Write_Reg_En <= E_Write_Reg_En;    M_Mem_to_Reg <= E_Mem_to_Reg;
        end
    
endmodule // EXE_MEM_Reg

//Mem/WB register
module MEM_WB_Reg(
    M_Write_Reg_En, M_Mem_to_Reg, Mem_Out, M_Alu_Result, M_Dst_id,
    W_Write_Reg_En, W_Mem_to_Reg, W_Mem_Out, W_Alu_Result, W_Dst_id,
    Clk, Reset
);
/*Signal
Mem_Out: the data read from memory
*/
    input [31:0] Mem_Out, M_Alu_Result;
    input [4:0] M_Dst_id;
    input M_Mem_to_Reg, M_Write_Reg_En, M_Mem_to_Reg;

    output [31:0] W_Mem_Out, W_Alu_Result;
    output [4:0] W_Dst_id;
    output W_Mem_to_Reg, W_Write_Reg_En;

    input Clk, Reset;

    reg [31:0] W_Mem_Out, W_Alu_Result;
    reg [4:0] W_Dst_id;
    reg W_Mem_to_Reg, W_Write_Reg_En;


    always@(posedge Clk or negedge Reset)
        if(0 == Reset) begin
            W_Mem_Out <= 0;     W_Alu_Result <= 0;
            W_Dst_id <= 0;
            W_Mem_to_Reg <= 0;    W_Write_Reg_En <= 0;
        end
        else begin
            W_Mem_Out <= Mem_Out;     W_Alu_Result <= M_Alu_Result;
            W_Dst_id <= M_Dst_id;
            W_Mem_to_Reg <= M_Mem_to_Reg;    W_Write_Reg_En <= M_Write_Reg_En;
        end
endmodule // MEM_WB_Reg