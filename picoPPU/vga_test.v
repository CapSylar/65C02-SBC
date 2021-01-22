`timescale 1ns / 1ps

module vga_test(  clk , vgaRed , vgaGreen , vgaBlue , Hsync , Vsync );

    input clk ;
    output [3:0] vgaRed ;
    output [3:0] vgaGreen ;
    output [3:0] vgaBlue ;
    output Hsync , Vsync ;
    
    wire video_enable ;
    wire generator_clock ; 
   
    vga_sync unit ( clk , Hsync , Vsync , video_enable , generator_clock ) ;
    
    reg [11:0] pixel_reg = 12'b111100000000 ;
   
    assign vgaRed = video_enable ? pixel_reg [11:8] : 0  ;
    assign vgaGreen = video_enable ? pixel_reg[7:4] : 0  ;
    assign vgaBlue = video_enable ? pixel_reg [3:0] : 0 ; 
    
endmodule
