//控制单元

module Controller(
        M_Mem_to_Reg, M_Write_Reg, M_Dst_Reg_id,
        E_Mem_to_Reg, E_Write_Reg, E_Dst_Reg_id,
        func, opCode, Reg_S, Reg_T, Transfer_Equal, 
        Write_Reg, Mem_to_Reg, Write_Mem, Alu_Code, Alu_idata_sel, regst_sel, Mux4to1_A_Sel, Mux4to1_B_Sel, No_Stall,
        Extern_Sel, PCSource, Shift, Jal
    );
/*Signal
Mux4to1_X_Sel: use the while data will transfer to the ID/EXE Reg(next the data will transfer to the alu) 
No_Stall: block  signal
Shift:
Transfer_Equal: Beq指令在Id级的比较跳转结果
regst_sel: 挑选写回的寄存器id来源
问题：
1、为什么有些信号还需要从流水线寄存器返回给主控单元
*/

    input [5:0] func, opCode;
    input [4:0] M_Dst_Reg_id, E_Dst_Reg_id, Reg_S, Reg_T; 
    input M_Write_Reg, M_Mem_to_Reg, E_Mem_to_Reg, E_Write_Reg, Transfer_Equal;
    
    output [3:0] Alu_Code;
    output [1:0] PCSource, Mux4to1_A_Sel, Mux4to1_B_Sel;
    output No_Stall;
    output Write_Reg, Mem_to_Reg, Write_Mem, regst_sel, Extern_Sel, Shift, Jal, Alu_idata_sel;
    reg [1:0] Mux4to1_A_Sel, Mux4to1_B_Sel;

    wire r_type, i_add, i_sub, i_and, i_or, i_xor, i_sll, i_srl, i_slt, i_jr,  i_addu, i_subu;           //R-type instruction
    wire i_addi, i_andi, i_ori, i_xori, i_lw, i_sw, i_beq, i_bne, i_lui, i_j, i_jal;        //I-type, J_type

    and(r_type, ~opCode[5], ~opCode[4], ~opCode[3], ~opCode[2], ~opCode[1], ~opCode[0]);

    //R-type, judged by func(6bits) and opcode(6 bits)
    and(i_add, r_type, func[5], ~func[4], ~func[3], ~func[2], ~func[1], ~func[0]);      //100000
    and(i_sub, r_type, func[5], ~func[4], ~func[3], ~func[2], func[1], ~func[0]);       //100010
    and(i_and, r_type, func[5], ~func[4], ~func[3], func[2], ~func[1], ~func[0]);       //100100
    and(i_or, r_type, func[5], ~func[4], ~func[3], func[2], ~func[1], func[0]);        //100101
    and(i_xor, r_type, func[5], ~func[4], ~func[3], func[2], func[1], ~func[0]);       //100110
    and(i_sll, r_type, ~func[5], ~func[4], ~func[3], ~func[2], ~func[1], ~func[0]);     //000000
    and(i_srl, r_type, ~func[5], ~func[4], ~func[3], ~func[2], func[1], ~func[0]);       //000010
    and(i_jr, r_type, ~func[5], ~func[4], func[3], ~func[2], ~func[1], ~func[0]);        //001000
    and(i_slt, r_type, func[5], ~func[4], func[3], ~func[2], func[1], ~func[0]);       //101010
    and(i_addu, r_type, func[5], ~func[4], ~func[3], ~func[2], ~func[1], func[0]);       //100001
    and(i_subu, r_type, func[5], ~func[4], ~func[3], ~func[2], func[1], func[0]);       //100011

    //I-type, J-type just judged by opcode(6bits)
    and(i_addi,  ~opCode[5], ~opCode[4], opCode[3], ~opCode[2], ~opCode[1], ~opCode[0]);    //001000
    and(i_andi,  ~opCode[5], ~opCode[4], opCode[3], opCode[2], ~opCode[1], ~opCode[0]);   //001100
    and(i_ori, ~opCode[5], ~opCode[4], opCode[3], opCode[2], ~opCode[1], opCode[0]);     //001101
    and(i_xori, ~opCode[5], ~opCode[4], opCode[3], opCode[2], opCode[1], ~opCode[0]);    //001110
    and(i_lw, opCode[5], ~opCode[4], ~opCode[3], ~opCode[2], opCode[1], opCode[0]);      //100011
    and(i_sw, opCode[5], ~opCode[4], opCode[3], ~opCode[2], opCode[1], opCode[0]);      //101011
    and(i_beq, ~opCode[5], ~opCode[4], ~opCode[3], opCode[2], ~opCode[1], ~opCode[0]);     //000100
    and(i_bne, ~opCode[5], ~opCode[4], ~opCode[3], opCode[2], ~opCode[1], opCode[0]);     //000101
    and(i_lui, ~opCode[5], ~opCode[4], opCode[3], opCode[2], opCode[1], opCode[0]);     //001111
    and(i_j, ~opCode[5], ~opCode[4], ~opCode[3], ~opCode[2], opCode[1], ~opCode[0]);     //000010
    and(i_jal, ~opCode[5], ~opCode[4], ~opCode[3], ~opCode[2], opCode[1], opCode[0]);      //000011


    //judge the register rs, rt used
    wire used_rs = i_add | i_sub | i_or | i_xor |  i_jr | i_addi | i_ori | i_xori | i_lw | i_sw | i_beq | i_bne | i_slt | i_addu | i_subu;
    wire used_rt = i_add | i_sub | i_or | i_xor | i_sll | i_srl | i_slt | i_sw | i_beq | i_bne | i_slt | i_addu | i_subu;
    
    //block signal
    /*Risk condithion
    Exe risk: rs & (rd == rs)
              rt & (rd == rs)
    the next instruct need the last instruct's alu calc result(this will be happen when the instruct used the special reg)

    Exe risk: Write_Reg & Write_Mem
    No_Stall: true when the risk condition is not exist
    */
    assign No_Stall = ~(E_Write_Reg & E_Mem_to_Reg & (E_Dst_Reg_id != 0) & (used_rs & (E_Dst_Reg_id == Reg_S) | used_rt & (E_Dst_Reg_id == Reg_T)));


    //the always will produce the result that solve the exe/mem risk according to different condition 
    always@(E_Write_Reg or M_Write_Reg or E_Dst_Reg_id or M_Dst_Reg_id or E_Mem_to_Reg or M_Mem_to_Reg or Reg_S or Reg_T) begin
        Mux4to1_A_Sel = 2'b00;
        if(E_Write_Reg & (E_Dst_Reg_id != 0) & (E_Dst_Reg_id == Reg_S) & ~E_Mem_to_Reg) begin
            Mux4to1_A_Sel = 2'b01;         //choose exe_alu result
        end else begin
            if(M_Write_Reg & (M_Dst_Reg_id != 0) & (M_Dst_Reg_id == Reg_S) & ~M_Mem_to_Reg) begin
                Mux4to1_A_Sel = 2'b10;          //choose mem
            end else begin
                if(M_Write_Reg & (M_Dst_Reg_id != 0) & (M_Dst_Reg_id == Reg_S) & M_Mem_to_Reg) begin
                    Mux4to1_A_Sel = 2'b11;
                end 
            end
        end

        Mux4to1_B_Sel = 2'b00;
        if(E_Write_Reg & (E_Dst_Reg_id != 0) & (E_Dst_Reg_id == Reg_T) & ~E_Mem_to_Reg) begin
            Mux4to1_B_Sel = 2'b01;         //choose exe_alu result
        end else begin
            if(M_Write_Reg & (M_Dst_Reg_id != 0) & (M_Dst_Reg_id == Reg_T) & ~M_Mem_to_Reg) begin
                Mux4to1_B_Sel = 2'b10;          //choose mem
            end else begin
                if(M_Write_Reg & (M_Dst_Reg_id != 0) & (M_Dst_Reg_id == Reg_T) & M_Mem_to_Reg) begin
                    Mux4to1_B_Sel = 2'b11;
                end 
            end
        end

    end

    //???? why & No_Stall
    assign Write_Reg = (i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_slt | i_addi | i_andi | i_ori | i_xori | i_lw | i_lui | i_jal | i_addu | i_subu) & No_Stall;

    //???regrt
    assign regst_sel = i_addi | i_andi | i_ori | i_xori | i_lw | i_lui;
    assign Jal = i_jal;
    assign Mem_to_Reg = i_lw;
    assign Shift = i_sll | i_srl;
    assign Alu_idata_sel = i_addi | i_andi | i_ori | i_xori | i_lw | i_lui | i_sw;
    assign Extern_Sel = i_addi | i_lw | i_sw | i_beq | i_bne;
    
    //how ot produce these signal
    assign Alu_Code[3] = i_slt;
    assign Alu_Code[2] = i_sub | i_or | i_srl | i_slt | i_ori | i_lui | i_subu;
    assign Alu_Code[1] = i_xor | i_sll | i_srl | i_slt | i_xori | i_beq | i_bne | i_lui;
    assign Alu_Code[0] = i_and | i_or | i_sll | i_srl | i_slt | i_andi | i_ori;
    
    assign Write_Mem = i_sw & No_Stall;
    assign PCSource[1] = i_jr | i_j | i_jal;
    assign PCSource[0] = i_beq & Transfer_Equal | i_bne & ~Transfer_Equal | i_j | i_jal;
endmodule // Controller