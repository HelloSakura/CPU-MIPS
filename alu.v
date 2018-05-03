`include "ctrl_encode_def.v"

module shift(
      d, sa, right, arith, sh
);
      input [4:0] sa;
      input [31:0] d;
      input right, arith;
      output [31:0] sh;
      reg [31:0] sh;

      always@ * begin
        if(!right) begin
            sh = d << sa;
        end else if(!arith) begin
            sh = d >> sa;
        end else begin
            sh = $signed(d) >>> sa;
        end
      end   

endmodule // shift


//add
module add(a, b, c, g, p, s);
      input a, b, c;
      output g, p, s;
      assign s = a^b^c;
      assign g = a & b;
      assign p = a | b;
endmodule // add

//gp
module g_p(g, p, c_in, g_out, p_out, c_out);
      input [1:0] g, p;
      input c_in;
      output g_out, p_out,c_out;

      assign g_out = g[1] | p[1] & g[0];
      assign p_out = p[1] & p[0];
      assign c_out = g[0] | p[0] & c_in;
endmodule


//2
module cla_2(a, b, c_in, g_out, p_out, s);
      input [1:0] a, b;
      input c_in;
      output g_out, p_out;
      output [1:0] s;
      wire [1:0] g, p;
      wire c_out;

      add add0(a[0], b[0], c_in, g[0], p[0], s[0]);
      add add1(a[1], b[1], c_out, g[1], p[1], s[1]);
      g_p g_p0(g, p, c_in, g_out, p_out, c_out);
endmodule

//4
module cla_4(a, b, c_in, g_out, p_out, s);
      input [3:0] a, b;
      input c_in;
      output g_out, p_out;
      output [3:0] s;
      wire [1:0] g,p;
      wire c_out;
      
      cla_2 cla0(a[1:0], b[1:0], c_in, g[0], p[0], s[1:0]);
      cla_2 cla1(a[3:2], b[3:2], c_out, g[1], p[1], s[3:2]);
      g_p g_p0(g, p, c_in, g_out, p_out, c_out);
endmodule

//8
module cla_8(a, b, c_in, g_out, p_out, s);
      input [7:0] a, b;
      input c_in;
      output g_out, p_out;
      output [7:0] s;
      wire [1:0] g,p;
      wire c_out;
      
      cla_4 cla0(a[3:0], b[3:0], c_in, g[0], p[0], s[3:0]);
      cla_4 cla1(a[7:4], b[7:4], c_out, g[1], p[1], s[7:4]);
      g_p g_p0(g, p, c_in, g_out, p_out, c_out);
endmodule



//16
module cla_16(a, b, c_in, g_out, p_out, s);
      input [15:0] a, b;
      input c_in;
      output g_out, p_out;
      output [15:0] s;
      wire [1:0] g,p;
      wire c_out;
      
      cla_8 cla0(a[7:0], b[7:0], c_in, g[0], p[0], s[7:0]);
      cla_8 cla1(a[15:8], b[15:8], c_out, g[1], p[1], s[15:8]);
      g_p g_p0(g, p, c_in, g_out, p_out, c_out);
endmodule




//32
module cla_32(a, b, c_in, g_out, p_out, s);
      input [31:0] a, b;
      input c_in;
      output g_out, p_out;
      output [31:0] s;
      wire [1:0] g,p;
      wire c_out;
      
      cla_16 cla0(a[15:0], b[15:0], c_in, g[0], p[0], s[15:0]);
      cla_16 cla1(a[31:16], b[31:16], c_out, g[1], p[1], s[31:16]);
      g_p g_p0(g, p, c_in, g_out, p_out, c_out);
endmodule

//cla32
module cla32(
  a, b, ci, s, co
);
      input [31:0] a, b;
      input ci;
      output [31:0] s;
      output co;
      wire g_out, p_out;

      cla_32 cla(a, b, ci, g_out, p_out, s);
      assign co = g_out | p_out & ci;
endmodule // cla32

//addsub32
module addsub32(a, b, sub, s);
      input [31:0] a, b;
      input sub;
      output [31:0] s;

      cla32 as32(a, b^{32{sub}}, sub, s);      
endmodule


module Alu(DataIn1, DataIn2, AluCtrl, AluResult);

	input [31:0] DataIn1, DataIn2;
      input [3:0] AluCtrl;
      output [31:0] AluResult;

      wire [31:0] d_and = DataIn1 & DataIn2;
      wire [31:0] d_or = DataIn1 | DataIn2;
      wire [31:0] d_xor = DataIn1 ^ DataIn2;
      wire [31:0] d_lui = {DataIn2[15:0], 16'b0};
      wire [31:0] d_and_or = AluCtrl[2] ? d_or : d_and;
      wire [31:0] d_xor_lui = AluCtrl[2] ? d_lui : d_xor;
      wire [31:0] d_slt = DataIn1 < DataIn2 ? 0 : 1;
      wire [31:0] d_as, d_sh, d_sh_slt;
      addsub32 as32(DataIn1, DataIn2, AluCtrl[2], d_as);
      shift shifter(DataIn2, DataIn1[4:0], AluCtrl[2], AluCtrl[3], d_sh);
      mux2 shSlt32(d_sh, d_slt, AluCtrl[3], d_sh_slt);
      mux4 select(d_as, d_and_or, d_xor_lui, d_sh_slt, AluCtrl[1:0], AluResult);
endmodule
