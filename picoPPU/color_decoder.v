module color_decoder( color , vga_color );

input wire [5:0] color ;
output reg [11:0] vga_color ; // red, green blue in order, 4 bits each 

always @(*)
begin

    case (color)
        6'h00: vga_color = { 4'h5 , 4'h5 , 4'h5  } ;
        6'h01: vga_color = { 4'h0 , 4'h1 , 4'h7 } ;

        6'h02: vga_color = { 4'h0 , 4'h1 , 4'h9  } ; 
        6'h03: vga_color = { 4'h3 , 4'h0 , 4'h8 } ;

        6'h04: vga_color = { 4'h4 , 4'h0 , 4'h6  } ; 
        6'h05: vga_color = { 4'h5 , 4'h0 , 4'h3 } ;

        6'h06: vga_color = { 4'h5 , 4'h0 , 4'h0  } ; 
        6'h07: vga_color = { 4'h3 , 4'h1 , 4'h0 } ;

        6'h08: vga_color = { 4'h2 , 4'h2 , 4'h0  } ; 
        6'h09: vga_color = { 4'h0 , 4'h3 , 4'h0 } ;

        6'h0a: vga_color = { 4'h0 , 4'h4 , 4'h0  } ; 
        6'h0b: vga_color = { 4'h0 , 4'h4 , 4'h0 } ;

        6'h0c: vga_color = { 4'h0 , 4'h3 , 4'h3  } ;
        6'h0d: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;

        6'h0e: vga_color = { 4'h0 , 4'h0 , 4'h0  } ;
        6'h0f: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;

        6'h10: vga_color = { 4'h9 , 4'h9 , 4'h9  } ; 
        6'h11: vga_color = { 4'h0 , 4'h4 , 4'hC } ;
        
        6'h12: vga_color = { 4'h3 , 4'h3 , 4'hE  } ; 
        6'h13: vga_color = { 4'h5 , 4'h1 , 4'hE } ; 

        6'h14: vga_color = { 4'h8 , 4'h1 , 4'hB  } ; 
        6'h15: vga_color = { 4'hA , 4'h1 , 4'h6 } ; 

        6'h16: vga_color = { 4'h9 , 4'h2 , 4'h2  } ; 
        6'h17: vga_color = { 4'h7 , 4'h3 , 4'h0 } ; 

        6'h18: vga_color = { 4'h5 , 4'h5 , 4'h0  } ;  
        6'h19: vga_color = { 4'h2 , 4'h7 , 4'h0 } ; 

        6'h1a: vga_color = { 4'h0 , 4'h7 , 4'h0  } ;  
        6'h1b: vga_color = { 4'h0 , 4'h7 , 4'h2 } ;

        6'h1c: vga_color = { 4'h0 , 4'h6 , 4'h7 } ;
        6'h1d: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;

        6'h1e: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;
        6'h1f: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;

        6'h20: vga_color = { 4'hE , 4'hE , 4'hE } ;
        6'h21: vga_color = { 4'h4 , 4'h9 , 4'hE } ;

        6'h22: vga_color = { 4'h7 , 4'h7 , 4'hE } ;
        6'h23: vga_color = { 4'hB , 4'h6 , 4'hE } ;

        6'h24: vga_color = { 4'hE , 4'h5 , 4'hE } ;
        6'h25: vga_color = { 4'hE , 4'h5 , 4'hB } ;

        6'h26: vga_color = { 4'hE , 4'h6 , 4'h6 } ;
        6'h27: vga_color = { 4'hD , 4'h8 , 4'h2 } ;

        6'h28: vga_color = { 4'hA , 4'hA , 4'h0 } ;
        6'h29: vga_color = { 4'h7 , 4'hC , 4'h0 } ;

        6'h2a: vga_color = { 4'h4 , 4'hD , 4'h2 } ;
        6'h2b: vga_color = { 4'h3 , 4'hC , 4'h6 } ;

        6'h2c: vga_color = { 4'h3 , 4'hB , 4'hC } ;
        6'h2d: vga_color = { 4'h3 , 4'h3 , 4'h3 } ;

        6'h2e: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;
        6'h2f: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;

        6'h30: vga_color = { 4'hE , 4'hE , 4'hE } ;
        6'h31: vga_color = { 4'hA , 4'hC , 4'hE } ;

        6'h32: vga_color = { 4'hB , 4'hB , 4'hE } ;
        6'h33: vga_color = { 4'hD , 4'hB , 4'hE } ;

        6'h34: vga_color = { 4'hE , 4'hA , 4'hE } ;
        6'h35: vga_color = { 4'hE , 4'hA , 4'hD } ;

        6'h36: vga_color = { 4'hE , 4'hB , 4'hB } ;
        6'h37: vga_color = { 4'hE , 4'hC , 4'h9 } ;

        6'h38: vga_color = { 4'hC , 4'hD , 4'h7 } ;
        6'h39: vga_color = { 4'hB , 4'hD , 4'h7 } ;

        6'h3a: vga_color = { 4'hA , 4'hE , 4'h9 } ;
        6'h3b: vga_color = { 4'h9 , 4'hE , 4'hB } ;

        6'h3c: vga_color = { 4'hA , 4'hD , 4'hE } ;
        6'h3d: vga_color = { 4'hA , 4'hA , 4'hA } ;

        6'h3e: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;
        6'h3f: vga_color = { 4'h0 , 4'h0 , 4'h0 } ;

        default: vga_color = { 4'h0 , 4'h0 , 4'h0 } ; 
    endcase









end


endmodule