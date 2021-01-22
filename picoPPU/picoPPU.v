module picoPPU( clk , btnC , JC , NMI , JB , vgaRed , vgaGreen , vgaBlue , Hsync , Vsync , /*debug*/ seg , an ) ;

input clk , btnC ;
output [3:0] vgaRed ;
output [3:0] vgaGreen ;
output [3:0] vgaBlue ;
output wire Hsync , Vsync ;

output wire [6:0] seg ;
output wire [3:0] an ;

inout wire [7:0] JB ;// data bus for interface 
input wire [6:0] JC ;// control signals
output wire NMI ;

wire video_enable;
wire [9:0] v_count ;
wire [9:0] h_count ;

// get a 25Mhz clock 

reg [1:0] divider = 0 ;

always@( posedge clk )
begin
    divider <= divider + 1 ;
end

wire clk_25Mhz = divider[1] ; // divided by 4 = 25Mhz

wire [4:0] spr_sec_oam_addr ;
wire spr_sec_oam_we ; // secondary OAM write enable
wire [15:0] spr_sec_oam_din ; // secondary OAM data in
wire [15:0] spr_sec_oam_dout ; // secondary OAM data out
wire spr_sec_oam_en ; // secondary OAM enable 

reg [7:0] prim_oam_addr ;
reg prim_oam_we , prim_oam_en ; 
wire [15:0] prim_oam_din ;
wire [15:0] prim_oam_dout ; 

reg  main_mem_a_we ;

wire v_blank , h_blank ;
wire [5:0] pix_out ;

// sprite_engine declarations 

wire [7:0] spr_prim_oam_addr ;
wire [15:0] spr_prim_oam_din ;
wire  spr_prim_oam_en , spr_prim_oam_we ;

wire [13:0] spr_main_mem_b_addr ;
wire [31:0] spr_main_mem_b_din ;
wire spr_main_mem_b_en ;

wire reset_n = !btnC ;
wire spr_reset_n = !(h_count == 799) ; // | (reset_n) ;

// INTERFACE

wire chip_select = !JC[1] && JC[2] && JC[3] ; // !CSB && CS && PHI2

// PRIMARY OAM AND PPU MAIN MEMORY MUXs

wire [7:0] inter_prim_oam_addr ;
wire [15:0] inter_prim_oam_dout ;
wire inter_prim_oam_en , inter_prim_oam_we ; 

wire [15:0] inter_main_mem_a_addr ;
wire [7:0] inter_main_mem_a_dout ;
wire inter_main_mem_a_en , inter_main_mem_a_we  ;


assign prim_oam_din = inter_prim_oam_dout ;// interface writes, sprite_eng doesn't 
assign spr_prim_oam_din = prim_oam_dout ; // sprite_eng only reads , interface doesn't

always @(*)
begin

    if ( v_blank ) // if vblank , cpu_interface controls main oam and ppu main memory 
    begin
        prim_oam_addr = inter_prim_oam_addr ;

        prim_oam_en = inter_prim_oam_en;
        prim_oam_we = inter_prim_oam_we;
        main_mem_a_we = inter_main_mem_a_we ; 
    end
    else
    begin
        prim_oam_addr = spr_prim_oam_addr ;

        prim_oam_en = spr_prim_oam_en ;
        prim_oam_we = spr_prim_oam_we ; 
        main_mem_a_we = 0 ;// interface shouldn't write when not in vblank
    end
end


cpu_interface pico_ppu_interface (.clk(clk) , .reset_n(reset_n) , .data_bus(JB) , .cs(chip_select) ,
         .we_b(JC[0]) , .reg_select(JC[6:4]) ,
         .oam_addr(inter_prim_oam_addr) , .oam_dout(inter_prim_oam_dout) , .oam_we(inter_prim_oam_we) ,
         .oam_en(inter_prim_oam_en) ,
         .mem_addr(inter_main_mem_a_addr) , .mem_dout(inter_main_mem_a_dout) , .mem_en(inter_main_mem_a_en) ,
         .mem_we(inter_main_mem_a_we) , .v_blank(v_blank) , .cpu_nmi(NMI) , .seg(seg) , .an(an) ) ;

sprite_engine myEngine ( .clk(clk) , .vga_clk(clk_25Mhz) , .reset_n(spr_reset_n) ,
         .sec_oam_addr(spr_sec_oam_addr) , .sec_oam_din(spr_sec_oam_din) , .sec_oam_dout(spr_sec_oam_dout) , .sec_oam_en(spr_sec_oam_en) , .sec_oam_we(spr_sec_oam_we) ,
         .prim_oam_addr(spr_prim_oam_addr) , .prim_oam_din(spr_prim_oam_din) , .prim_oam_en(spr_prim_oam_en) , .prim_oam_we(spr_prim_oam_we) ,
         .main_mem_b_addr(spr_main_mem_b_addr) , .main_mem_b_din(spr_main_mem_b_din) , .main_mem_b_en(spr_main_mem_b_en) ,
         .inter_mem_addr(inter_main_mem_a_addr) , .inter_mem_din(inter_main_mem_a_dout) , .inter_mem_we(inter_main_mem_a_we) ,
         .v_counter(v_count) , .h_blank(h_blank) , .v_blank(v_blank) , .color_out(pix_out) ) ;


// leaves these lines ( inter_main_mem_a_dout , inter_main_mem_a_addr ) connected although they are not currently being used
PPU_main_mem_wrapper main_PPU_mem ( .BRAM_PORTA_0_addr(inter_main_mem_a_addr) , .BRAM_PORTA_0_clk(clk) ,
 .BRAM_PORTA_0_din(inter_main_mem_a_dout) , .BRAM_PORTA_0_en(0) , .BRAM_PORTA_0_we(0),
  .BRAM_PORTB_0_addr(spr_main_mem_b_addr) , .BRAM_PORTB_0_clk(clk) , .BRAM_PORTB_0_dout(spr_main_mem_b_din) ,
   .BRAM_PORTB_0_en(spr_main_mem_b_en)) ;

Primary_OAM_wrapper my_prim_oam ( .BRAM_PORTA_0_addr(prim_oam_addr) , .BRAM_PORTA_0_clk(clk)  ,
             .BRAM_PORTA_0_din(prim_oam_din) , .BRAM_PORTA_0_dout(prim_oam_dout) , .BRAM_PORTA_0_en(prim_oam_en) , .BRAM_PORTA_0_we(prim_oam_we) ) ;

Secondary_OAM_wrapper my_sec_oam ( .BRAM_PORTA_0_addr(spr_sec_oam_addr) , .BRAM_PORTA_0_clk(clk) , .BRAM_PORTA_0_din(spr_sec_oam_dout) ,
             .BRAM_PORTA_0_dout(spr_sec_oam_din) , .BRAM_PORTA_0_en(spr_sec_oam_en) , .BRAM_PORTA_0_we(spr_sec_oam_we) ) ;


wire [11:0] decoder_out ; 
color_decoder ppu_color_decoder ( .color(pix_out) , .vga_color(decoder_out)  ) ;

vga_sync ppu_vga_sync ( .clk(clk_25Mhz) , .reset_n(reset_n) , .Hsync(Hsync) , .Vsync(Vsync) , .video_on(video_enable) , .v_count(v_count) , .h_count(h_count) , .v_blank(v_blank) , .h_blank(h_blank)  ) ;

assign {vgaRed , vgaGreen , vgaBlue } = video_enable ? decoder_out : 0 ; // pull all colors to 0 when in vblank and hblank


endmodule
