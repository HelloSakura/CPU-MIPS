//不提供寄存器的实体，而是实现各个阶段的控制状态
//if stage

module IF_Stage(PCSourse, PC, Transfer_PC, R_PC, Jump_PC, Next_PC, PC_4, Instruct);                 //???  R_PC
    input [31:0] PC, Jump_PC, Transfer_PC, R_PC;            //四选一信号输入的PC的几个选项
    input [1:0] PCSourse;                   //PC选择信号

    output [31:0] Next_PC, PC_4, Instruct;
    mux4 Mux4_to_1(PC_4, Transfer_PC, R_PC,Jump_PC, PCSourse,  Next_PC);
    cla32 pc_plus_4(PC, 32'h4, 1'b0, PC_4);

    wire [9:0] addr = {PC[11:2]};
    Instruct_Memory mem(addr, Instruct);
endmodule

//id stage
module ID_Stage(
  Mem_Write_Reg_EN, Mem_Dst_id, Exe_Dst_id, Exe_Wrire_Reg_EN, Exe_MemToReg, Mem_MemToReg, 
  ID_PC4, Instruct, WB_Dst_id, 
  Dst_id_info, Exe_Alu_Res, Mem_Alu_Res, Mem_out, WB_WriteReg_EN, Clock, clrn, Transfer_PC, Jump_PC, PCSourse, 
  NO_Stall, Write_Reg, MemToReg, Write_Mem, Alu_Code, alu_b_in_mux, Alu_dataIn_a, Alu_dataIn_b, immediate, rn, 
  Shift, Jal
);
/*Signal
Exe_Dst_id: write_reg id, before the EXE/Mem Reg
Mem_Dst_idr: write_reg id, after the EXE/Mem Reg
Dst_id_info: the info write to reg
Mem_out: the alu input red from mem
clrn:???
a:
b:
rn:
*/
    input [31:0] ID_PC4, Instruct, Dst_id_info, Exe_Alu_Res, Mem_Alu_Res, Mem_out;
    input [4:0] Exe_Dst_id, Mem_Dst_id, WB_Dst_id;
    input Mem_Write_Reg_EN, Exe_Wrire_Reg_EN, Exe_MemToReg, Mem_MemToReg, WB_WriteReg_EN;
    input Clock, clrn;
    
    output [31:0] Transfer_PC, Jump_PC, Alu_dataIn_a, Alu_dataIn_b, immediate;
    output [4:0] rn;
    output [3:0] Alu_Code;
    output [1:0] PCSourse;
    output NO_Stall, Write_Reg, MemToReg, Write_Mem, alu_b_in_mux, Shift, Jal;

    wire [5:0] opCode, funCode;
    wire [4:0] rs, rt, rd;
    wire [31:0] qa, qb, br_offset;
    wire [15:0] ext16;
    wire [1:0] fwda, fwdb;
    wire regret, sext, rsrtequ, e;
    assign funCode = Instruct[5:0];
    assign opCode = Instruct[31:26];
    assign rs = Instruct[25:21];
    assign rt = Instruct[20:16];
    assign rd = Instruct[15:11];
    assign Jump_PC = {ID_PC4[31:28], Instruct[25:0], 2'b00};

    Controller controller(
        Mem_MemToReg, Mem_Write_Reg_EN, Mem_Dst_id, Exe_MemToReg, Exe_Wrire_Reg_EN, Exe_Dst_id, funCode,
        opCode, rs, rt, rsrtequ, Write_Reg, MemToReg, Write_Mem, Alu_Code, alu_b_in_mux, regret,
        fwda, fwdb, NO_Stall, sext, PCSourse, Shift, Jal
    );

    Register_File reg_file(rs, rt, WB_Dst_id, Dst_id_info, WB_WriteReg_EN, ~Clock, qa, qb);
    mux2x5 dst_id_No(rd, rt, regret, rn);
    mux4 alu_a(qa, Exe_Alu_Res, Mem_Alu_Res, Mem_out, fwda, Alu_dataIn_a);
    mux4 alu_b(qb, Exe_Alu_Res, Mem_Alu_Res, Mem_out, fwdb, Alu_dataIn_b);

    assign rsrtequ = ~|(Alu_dataIn_a ^ Alu_dataIn_b);
    assign e = sext & Instruct[15];
    assign ext16 = {16{e}};
    assign immediate = {ext16, Instruct[15:0]};
    assign br_offset = {immediate[29:0], 2'b00};
    assign Transfer_PC = ID_PC4 + br_offset;

endmodule // ID_Stage

//exe stage
module EXE_Stage(
    Alu_Code, Alu_idata, DataIn_1, DataIn_2,
    Alu_idata_sel, Shift, Dst_id,  PC_4, 
    Jal, Dst_id_After, Alu_Result
);
/*Signal
Alu_idata_sel: use to select alu_dataIn_2 immediate data or from reg
Shift:  
Dst_id_After: unknow signal
*/
    input [31:0] Alu_idata, DataIn_1, DataIn_2, PC_4;
    input [4:0] Dst_id;
    input [3:0] Alu_Code;
    input Alu_idata_sel, Shift, Jal;

    output [4:0] Dst_id_After;
    output [31:0] Alu_Result;

    wire [31:0] to_alu_a_bus, to_alu_b_bus, alu_out_bus, shift_data_bus, pc_bus;
    wire Zero;

    assign shift_data_bus = {Alu_idata[5:0], Alu_idata[31:6]};
    PC_Plus_4 pc_plus_4(PC_4, pc_bus);
    
    mux2 alu_a_in_mux(DataIn_1, shift_data_bus, Shift, to_alu_a_bus);
    mux2 alu_b_in_mux(DataIn_2, Alu_idata, Alu_idata_sel, to_alu_b_bus);
    mux2 alu_result_mux(alu_out_bus, pc_bus, Jal, Alu_Result);

    assign Dst_id_After = Dst_id; //| {5{Jal}};    what fxxk do not support jal

    Alu alu(to_alu_a_bus, to_alu_b_bus, Alu_Code, alu_out_bus);

endmodule // EXE_Stage



//mem stage
module MEM_Stage(
    Write_Mem, Address, DataIn, DataOut
);
    input Write_Mem;
    input [31:0] Address, DataIn;
    output [31:0] DataOut;
    Data_Memory data_Memory(.Write(Write_Mem), .Address(Address), .DataIn(DataIn), .DataOut(DataOut));
endmodule // MEM_Stage








