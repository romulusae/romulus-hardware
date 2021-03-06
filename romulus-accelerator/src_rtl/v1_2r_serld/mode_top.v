module mode_top (/*AUTOARG*/
   // Outputs
   pdo, pdo_hash_l, pdo_hash_s, counter,
   // Inputs
   pdi, sdi, domain, decrypt, clk, srst, senc, sse, xrst, xenc, xse,
   yrst, yenc, yse, zrst, zenc, zse, erst, correct_cnt, constant,
   constant2, tk1s, hashmode, hashmode_first_cycle, hash_cipher
   ) ;
   output [31:0] pdo;
   output [31:0] pdo_hash_l, pdo_hash_s;
   output [55:0] counter;   

   input [31:0]  pdi;
   input [31:0]  sdi;
   input [7:0]   domain;
   input [3:0]   decrypt;   
   input         clk;
   input         srst, senc, sse;
   input         xrst, xenc, xse;
   input         yrst, yenc, yse;
   input         zrst, zenc, zse;
   input         erst;  
   input         correct_cnt;
   input [5:0]   constant;
   input [5:0]   constant2;
   input         tk1s;
   input 	 hashmode, hashmode_first_cycle, hash_cipher;

   wire [127:0]  tk1, tk2;
   wire [63:0]   tk3;
   wire [127:0]  tka, tkb;
   wire [63:0]   tkc;
   wire [127:0]  skinnyS;
   wire [127:0]  skinnyX, skinnyY;
   wire [63:0]   skinnyZ;
   wire [127:0]  TKX0, TKY0;
   wire [127:0]  TKX1, TKY1;
   wire [63:0]   TKZ0;
   wire [63:0]   TKZ1;
   wire [127:0]  S;   
   wire [55:0]   cin;  

   assign counter = TKZ0[63:8];
   
   state_update_32b STATE (.state(S), .pdo(pdo), .skinny_state(skinnyS), .pdi(pdi),
                           .clk(clk), .rst(srst), .enc(senc), .se(sse), .decrypt(decrypt));
   
   tkx_update_32b TKEYX (.tkx(TKX0), .skinny_tkx(skinnyX), .skinny_tkx_revert(tk2), .sdi(sdi),
                         .clk(clk), .rst(xrst), .enc(xenc), .se(xse));
   
   tky_update_32b TKEYY (.tky(TKY0), .skinny_tky(skinnyY), .skinny_tky_revert(tk1), .pdi(pdi),
                         .clk(clk), .rst(yrst), .enc(yenc), .se(yse));
   
   tkz_update_32b TKEYZ (.tkz(TKZ0), .skinny_tkz(skinnyZ), .skinny_tkz_revert(tk3),
                         .clk(clk), .rst(zrst), .enc(zenc), .se(zse));


   assign cin = correct_cnt ? TKZ0[63:8] : tkc[63:8];
   //assign TKZZ = {TKZ, 64'h0};
   //assign TKZZ2 = 128'h0
   //assign TKZN = skinnyZ;   

   pt8 permA (.tk1o(tka), .tk1i(TKX0));
   pt8 permB (.tk1o(tkb), .tk1i(TKY0));
   pt4 permC (.tk1o(tkc), .tk1i(TKZ0), .ad(tk1s));

   lfsr_gf56 CNT (.so(tk3), .si(cin), .domain(domain));
   lfsr3_20 LFSR2 (.so(tk1), .si(tkb));
   lfsr2_20 LFSR3 (.so(tk2), .si(tka));

   round_function SKINNY (.round_key0({TKZ0, 64'h0, TKY0, TKX0}),
                          .round_key1({TKZ1, 64'h0, TKY1, TKX1}),                           
                          .round_in0(S),
                          .round_in1(128'h0), 
                          .round_out1(skinnyS),
                          .constant0(constant), 
                          .constant1(constant2),
			  .switch(hash_cipher));
   KeyExpansion KEYEXP (.ROUND_KEY2({skinnyZ, skinnyY, skinnyX}),
                        .ROUND_KEY1({TKZ1, TKY1, TKX1}), 
                        .KEY({TKZ0,TKY0,TKX0}));
   
   
   
   
   
   
endmodule // mode_top
