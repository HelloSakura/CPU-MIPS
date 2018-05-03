module pipelineCpu(
    Clock, memClock, Reset, PC, inst, 
    ealu, malu, walu
);
    input Clock, memClock, Reset;
    output [31:0] PC, inst, ealu, malu, walu;
    wire [31:0] bpc, jpc, npc, instruct, dpc4, ins, pc4, inst, da, db, dimm, ea, eb, eimm;
    wire [31:0] epc4, mb, mmo, wmo, wdi;
    wire [4:0] drn, ern0, ern, mrn, wrn;
    wire [3:0] daulc, ealuc;
    wire [1:0] pcsource;
    wire wpcir;
    wire dwreg, dm2reg, dwmem, daluimm, dshift, djal;
    wire ewreg, em2reg, ewmem, ealuimm, eshift, ejal;
    wire mwreg, mm2reg, mwmem;
    wire wwreg, wm2reg;


    PC_Reg pc_reg(npc, Clock, Reset, wpcir, PC);
    IF_Stage if_stage(pcsource, PC, bpc, da, jpc, npc, pc4, ins);

    IR_Reg ir_reg(pc4, ins, wpcir, Clock, Reset, dpc4, inst);
    ID_Stage id_stage(
        mwreg, mrn, ern, ewreg, em2reg, mm2reg, dpc4, inst,
        wrn, wdi, ealu, malu, mmo, wwreg, Clock, Reset,
        bpc, jpc, pcsource, wpcir, dwreg, dm2reg, dwmem,
        daulc, daluimm, da, db, dimm, drn, dshift, djal
    );

    ID_EXE_Reg exe_reg(
        dwreg, dwmem, dm2reg, daulc, daluimm, da, db, dimm, 
        drn, dshift, djal, dpc4,
        ewreg, ewmem, em2reg, ealuc, ealuimm, ea, eb, eimm,
        ern0, eshift, ejal, epc4,
        Clock, Reset
    );

    EXE_Stage exe_stage(
        ealuc, eimm, ea, eb, ealuimm, eshift, ern0, epc4, ejal, ern, ealu
    );


    EXE_MEM_Reg mem_reg(
        ewreg, ewmem, em2reg, ealu, eb, ern,  
        mwreg, mwmem, mm2reg, malu, mb, mrn,
        Clock, Reset
    );

    MEM_Stage mem_stage(mwmem, malu, mb, mmo);


    MEM_WB_Reg wb_reg(
        mwreg, mm2reg, mmo, malu, mrn,
        wwreg, wm2reg, wmo, walu, wrn,
        Clock, Reset
    );

    mux2 wb_stage(walu, wmo, wm2reg, wdi);

    

endmodule // pipelineCpu