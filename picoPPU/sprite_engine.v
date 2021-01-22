module sprite_engine ( clk , vga_clk , reset_n ,
        /* sec oam dec */ sec_oam_addr , sec_oam_din , sec_oam_dout , sec_oam_en , sec_oam_we ,
        /*prim oam dec */ prim_oam_addr , prim_oam_din , prim_oam_en , prim_oam_we,
        /* main mem dec port b */ main_mem_b_addr , main_mem_b_din , main_mem_b_en ,
        /* cpu interface dec palette */ inter_mem_addr , inter_mem_din , inter_mem_we ,   
                        v_counter , h_blank , v_blank , color_out ) ;

// interface connection to palette memory, test for now, address not completely decoded

input wire [15:0] inter_mem_addr ;
input wire [7:0] inter_mem_din ;
input wire inter_mem_we ;

// main memory interface declarations

output reg [13:0]main_mem_b_addr ;
input wire [31:0]main_mem_b_din ;
output reg main_mem_b_en ;

input clk , vga_clk , reset_n , h_blank , v_blank ;
output reg [5:0] color_out ;
input wire [9:0] v_counter ; // the current scaline we are on

// secondary OAM memory declarations

output reg [4:0] sec_oam_addr ; // can address 24 16-bit words of secondary OAM memory
output reg sec_oam_we ; // secondary OAM write enable
input wire [15:0] sec_oam_din ; // secondary OAM data in
output reg [15:0] sec_oam_dout ; // secondary OAM data out
output reg sec_oam_en ; // secondary OAM enable

// primary OAM memory declarations 

output reg [7:0] prim_oam_addr ; // 256 locations to address
input wire [15:0] prim_oam_din ;
output reg prim_oam_en ;
output reg prim_oam_we ;

// implement FSM , first we write FF into secondary OAM

// evaluate sprites and write into secondary OAM

// finally load sprite units with corresponding pixels and data 
// secondary OAM 8 sprite units

reg [4:0] state ;
reg [15:0] read_buffer ;
reg [1:0] entries_to_copy ;
reg[2:0] sprites_left ;
reg[2:0] unit_index ;
reg [1:0] fields_index ;
reg [1:0] wait_counter ; // used to wait for that 3 cycle delay
reg [15:0] read_buffer2 ;

reg [4:0] sprite_row ; // used as intermediary i hope 
reg [1:0] bit_plane ; 

integer i ;
integer j ;
integer k ;

// sprite units
// for now each sprite units will have a counter for the X position and a 32-bit shift register for the data ( we need more that one for later )
// for testing the pixel shift registers will be loaded with the color red

reg [15:0] x_counter [7:0] ;
reg [4:0] attr_reg[7:0] ; // attribute for each sprite unit,3 bits to choose from the palette and 2 for flipping along X and Y
reg [31:0] pix_shift_reg [7:0][3:0] ;

reg[5:0] palette_mem[7:0][15:0] ; // 8 group of 16 regs corresponding to 8 palettes of 16 colors

// intialize for testing purposes

always @( posedge clk )
begin
    if ( inter_mem_we ) // interface wants to write to palette
    begin
        palette_mem[inter_mem_addr[6:4]][inter_mem_addr[3:0]] = inter_mem_din[5:0]; 
    end    
end


initial begin // for now just initialize the first palette 
   palette_mem[0][0] = 6'h01 ; // black 
   palette_mem[0][1] = 6'h06 ;  // random colors , probably ugly colors as well 
   palette_mem[0][2] = 6'h0f ;
   palette_mem[0][3] = 6'h18 ;
   palette_mem[0][4] = 6'h08 ;
   palette_mem[0][5] = 6'h01 ;
   palette_mem[0][6] = 6'h05 ;
   palette_mem[0][7] = 6'h06 ;
   palette_mem[0][8] = 6'h20 ;
   palette_mem[0][9] = 6'h37 ;
   palette_mem[0][10] = 6'h25 ;
   palette_mem[0][11] = 6'h21 ;
   palette_mem[0][12] = 6'h28 ;
   palette_mem[0][13] = 6'h11 ;
   palette_mem[0][14] = 6'h18 ;
   palette_mem[0][15] = 6'h28 ;

end

reg[3:0] color_number;
reg[3:0] pix_shift_color[7:0] ; // joins the 4 different bits from the pix registers, used to address palette memory
reg[2:0] palette_number; // palette number from the group of 8 that are available 
always@( * )
begin
    
    color_number = 0 ; //default state
    palette_number = 0 ;

        for ( k = 0 ; k < 8 ; k = k + 1 )
    begin
        pix_shift_color[k] = { pix_shift_reg[k][3][31] , pix_shift_reg[k][2][31] , pix_shift_reg[k][1][31] , pix_shift_reg[k][0][31] } ;
    end

    if ( x_counter[0] == 0 && pix_shift_color[0] )
    begin
        color_number = pix_shift_color[0] ;
        palette_number = attr_reg[0][2:0] ;
    end

    else if ( x_counter[1] == 0 && pix_shift_color[1] )
    begin
        color_number = pix_shift_color[1] ;
        palette_number = attr_reg[1][2:0] ; 
    end

    else if ( x_counter[2] == 0 && pix_shift_color[2] )
    begin
        color_number = pix_shift_color[2] ;
        palette_number = attr_reg[2][2:0] ;
    end

    else if ( x_counter[3] == 0 && pix_shift_color[3] )
    begin
        color_number = pix_shift_color[3] ;
        palette_number = attr_reg[3][2:0] ;
    end

    else if ( x_counter[4] == 0 && pix_shift_color[4] )
    begin
        color_number = pix_shift_color[4] ;
        palette_number = attr_reg[4][2:0] ;
    end

    else if ( x_counter[5] == 0 && pix_shift_color[5] )
    begin
        color_number = pix_shift_color[5] ;
        palette_number = attr_reg[5][2:0] ;
    end
    else if ( x_counter[6] == 0 && pix_shift_color[6] )
    begin
        color_number = pix_shift_color[6] ;
        palette_number = attr_reg[6][2:0] ;
    end
    else if ( x_counter[7] == 0 && pix_shift_color[7] )
    begin
        color_number = pix_shift_color[7] ;
        palette_number = attr_reg[7][2:0] ;
    end
    
    color_out = palette_mem[palette_number][color_number] ; // final 6 bits out

end

// reg [1:0] clk_divider = 0 ; // generate the 25Mhz clock
reg wait_for_down = 0 ;
always@ ( posedge clk ) // no work on vblank 
begin
    if ( !reset_n )
    begin
        state <= 0 ; // reset state
        sec_oam_addr <= 0;
        sec_oam_dout <= 16'hFFFF ; // for first state 

        prim_oam_addr <= 0 ;

        sprites_left <= 8 ; // 8 sprites per scanline now
        unit_index <= 0 ;
        fields_index <= 0 ;

        main_mem_b_addr <= 0;
        wait_for_down <= 0;

        read_buffer <= 0 ;
        entries_to_copy <= 0 ;
        sprites_left <= 0 ;
        unit_index <= 0 ;
        fields_index <= 0 ;
        wait_counter <= 0 ;
        read_buffer2 <= 0 ;

        sprite_row <= 0 ;
        bit_plane <= 0 ;
    end

    else if ( !v_blank )
    begin

        if ( !vga_clk )
            wait_for_down <= 0 ;
        else if ( !h_blank && vga_clk && !wait_for_down ) // push out pixels at the rate of vga_clk
        begin
            wait_for_down <= 1; 
            for ( i = 0 ; i < 8 ; i = i + 1 )
            begin
                if ( x_counter[i] == 0 ) // active unit
                begin
                    for ( j = 0 ; j < 4 ; j = j + 1 )
                        pix_shift_reg[i][j][31:0] <= { pix_shift_reg[i][j][30:0] , 1'b0 } ;
                end
                else
                    x_counter[i] <= x_counter[i] - 1;
            end
        end


        else
        begin
            case (state)
                0: // begin writing $FF to secondary OAM 
                begin
                    sec_oam_addr <= sec_oam_addr + 1 ;

                    if ( sec_oam_addr == 23 ) // done
                    begin
                        sec_oam_addr <= 0 ;
                        state <= 1 ;                
                    end
                end

                1: // begin sprite evaluation 
                begin
                    // 2 cycles read delay
                    state <= 2 ;
                end

                2: // read
                begin
                    state <= 3 ;
                end

                3:
                begin
                    read_buffer <= prim_oam_din ; // read Y into buffer 
                    state <= 4 ;
                end

                4:
                begin
                    // check if y for sprite is within range 
                    // for now we only support 32x32 sprites
                    if ( !(read_buffer > (v_counter+1) || (v_counter+1) > (read_buffer+31)) ) // is in range 
                    begin
                        state <= 5;
                        entries_to_copy <= 3 ; // Y, X and tile address ,each 16 bits 
                        sprites_left <= sprites_left - 1 ;
                    end
                    else if ( prim_oam_addr == 189 ) // done with primary OAM , mem goes till 191 
                    begin
                        state <= 10 ;
                        sec_oam_addr <= 0 ;
                    end
                    else
                    begin
                        prim_oam_addr <= prim_oam_addr + 3 ; // skip x and tile number of current entry 
                        state <= 1 ;  
                    end
                end

                5:
                begin // oam entry has a sprite that is in range , copy all entries to sec oam
                state <= 6 ; 
                end

                6:
                begin
                    state <= 7; 
                end

                7:
                begin
                    sec_oam_dout <= prim_oam_din; // read into buffer
                    entries_to_copy <= entries_to_copy-1 ; 
                    state <= 9 ;
                end

                9:
                begin

                    if ( prim_oam_addr == 191 || sprites_left == 0 ) // we are done with sprite evaluation, we can proceed
                    begin
                        state <= 10 ;
                        sec_oam_addr <= 0 ;
                    end
                    else 
                    begin
                        sec_oam_addr <= sec_oam_addr + 1;
                        prim_oam_addr <= prim_oam_addr + 1;

                        if ( entries_to_copy == 0 ) // done, continue evaluating next entries 
                            state <= 1 ;
                        else
                            state <= 5; // continue copying remaining entries
                    end
                    
                end

                10:
                begin // wait for video_off at the end of the current scanline 
                    if ( h_blank )// sprite evaluation done, copy data from secondary OAM to the 8 sprite units for now
                        state <= 11; 
                    else 
                        state <= 10 ;
                end

                11:
                begin
                    state <= 12 ;
                end

                12:
                begin
                    state <= 13 ;
                end

                13:
                begin
                    // we use Y to load the correct sprite "row" from pattern memory 
                    // subtract line_count from Y and use this to index into mem 
                    if ( fields_index == 0 ) // handle Y 
                    begin
                        fields_index <= fields_index + 1;
                        state <= 11 ;
                        read_buffer <= sec_oam_din ; // read Y in , save for later 
                    end
                    else if ( fields_index == 1 )
                    begin
                        fields_index <= fields_index + 1;
                        state <= 11 ;
                        x_counter[unit_index] <= sec_oam_din ; // read in X 
                    end
                    else if ( fields_index == 2 ) // read in tile index 
                    begin
                        read_buffer2 <= sec_oam_din[6:0] ; // read in tile number and misc info
                        attr_reg[unit_index] <= sec_oam_din[11:7] ; // read in attr bits which are stored along the tile number 
                        // calculate the address to fetch the sprite row from main PPU memory 
                        state <= 14 ;
                        bit_plane <= 0;
                        wait_counter <= 0 ; // just once to go to state 14
                        fields_index <= 0 ; // reset 
                    end

                    sec_oam_addr <= sec_oam_addr + 1;
                end

                14: // prepare for tile fetches, we need 4 fetches of 4 bytes each, 3 cycles delay per fetch 
                begin

                    sprite_row = (v_counter+1) - read_buffer ;
                    main_mem_b_addr <= { read_buffer2[6:0] , bit_plane , sprite_row } ;
                    state <= 15;
                end

                15:
                begin
                    if ( wait_counter == 3 ) // done waiting, data is ready 
                    begin
                        // pix_shift_reg[unit_index][bit_plane][31:0] <= main_mem_b_din[31:0] ; // read in sprite row
                        
                        pix_shift_reg[unit_index][bit_plane][31:0] <= {main_mem_b_din[7:0] , main_mem_b_din[15:8] , main_mem_b_din[23:16] , main_mem_b_din[31:24] } ; 

                        if( bit_plane == 3 ) // we are done with this sprite
                        begin
                            if ( sec_oam_addr == 24 ) // one over max, done , PPU goes idle
                                state <= 16; // idle state
                            else
                            begin
                                state <= 11 ; // process next sprite
                                unit_index <= unit_index + 1 ; 
                            end
                        end
                        else
                        begin
                            state <= 14; // go fetch next sprite row 
                        end
                        
                        bit_plane <= bit_plane + 1; // advance to next bit plane
                    end

                    wait_counter <= wait_counter + 1 ; // continue waiting for RAM 
                end

            endcase
        end
    end
end


always@ (*)
begin

    prim_oam_en = 0 ;
    prim_oam_we = 0 ;
    sec_oam_en = 0 ;
    sec_oam_we = 0 ;

    main_mem_b_en = 0;

    case (state)
        0:
        begin
            sec_oam_en = 1 ;
            sec_oam_we = 1 ; 
        end 

        1:
        begin
            prim_oam_en = 1 ;
            prim_oam_we = 0 ;
        end

        2:
        begin
            prim_oam_en = 1 ;
            prim_oam_we = 0 ; 
        end

        5:
        begin
            prim_oam_en = 1; 
            prim_oam_we = 0; 
        end

        6:
        begin
            prim_oam_en = 1; 
            prim_oam_we = 0; 
        end

        9:
        begin
            sec_oam_en = 1;
            sec_oam_we = 1; 
        end


        11:
        begin
            sec_oam_en = 1;
            sec_oam_we = 0;
        end

        12:
        begin
            sec_oam_en = 1;
            sec_oam_we = 0;
        end


        15:
        begin
            main_mem_b_en = 1 ;
        end
        
    endcase

end

endmodule