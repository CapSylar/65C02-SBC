module cpu_interface( clk , reset_n , data_bus , cs , we_b , reg_select ,
    /*oam memory interface*/ oam_addr , oam_dout , oam_we , oam_en ,
    /*ppu mem interface*/ mem_addr , mem_dout , mem_en , mem_we , v_blank , cpu_nmi , /*debug*/ seg , an );

input clk , v_blank , reset_n;
input wire cs , we_b ;
input wire [2:0] reg_select ;
inout wire [7:0] data_bus ;

output reg cpu_nmi;

// oam memory declarations 

output reg [7:0] oam_addr ; 
output reg [15:0] oam_dout;
output reg oam_we , oam_en;

// main memory declarations 

output reg [15:0] mem_addr ;
output reg [7:0] mem_dout;
output reg mem_en , mem_we ;

wire our_time_input = (!we_b && cs);

reg [7:0] ppu_ctrl ;
wire oam_addr_inc = ppu_ctrl[0] ; // autoincrement for oam
wire mem_addr_inc = ppu_ctrl[1] ; // autoincrement for ppu mem 
wire enable_nmi = ppu_ctrl[2] ;
wire rendering = ppu_ctrl[3] ; // if rendering is enabled

reg oam_data_second ; // used to control the oam_data and ppu_addr shift r/w bahvior

// state machine

reg[1:0] state;
reg oam_write;

reg [7:0] save_data = 0 ;
reg [2:0] reg_sel_save = 0 ;

// DEBUG 
output wire [6:0] seg ;
output wire [3:0] an ;
reg [7:0] write_counter ; 

mult_display display_controller ( clk , {ppu_ctrl , write_counter } , seg , an ) ;

// WRITING TO THE PPU


reg pipeline = 0;
reg pipeline2 = 0 ;
reg pipeline3 = 0 ; 

// debug ILA 
// ILA_core_wrapper debug_core_robin ( .clk_in1_0 (clk) , .reset_0(!reset_n) , 
//              .data_bus(data_bus) , .control_signals( { 1'b0 , reg_select , pipeline3 , pipeline2 , pipeline , our_time_input } ) , .chip_select(cs) ,
//                 .probe3_0(oam_addr) , .probe4_0(oam_dout[7:0]) , .probe5_0(save_data) , .probe6_0(reg_sel_save) ) ;

always@( negedge our_time_input )
begin
        save_data = data_bus ;
        reg_sel_save = reg_select ;    
end

always @( posedge clk )
begin
    pipeline <= our_time_input ;
    pipeline2 <= pipeline ;
    pipeline3 <= pipeline2 ; 
end

always@( posedge clk ) // 65C02 pulls this up to write
begin
    if ( !reset_n )
    begin
        oam_addr <= 0;
        oam_dout <= 0;
        mem_addr <= 0;
        mem_dout <= 0;
        ppu_ctrl <= 0;

        oam_write <= 0;
        state <= 2 ;
        oam_data_second <= 0 ;
        write_counter <= 0 ;
    end

    else
    begin

        if ( !pipeline2 && pipeline3 && !state )
        begin
            write_counter <= write_counter+1 ;

            case (reg_sel_save)
                0: // PPUCTRL/PPUSTATUS
                    ppu_ctrl <= save_data ;
                1: // PPU ADDR, shift in a byte after each write
                begin
                    mem_addr <= { mem_addr[7:0] , save_data };
                end
                2: // PPU DATA , a write here will write the byte at location pointed to by PPU ADDR 
                begin
                    mem_dout <= save_data ; // a write
                    oam_write <= 0 ;// tell the FSM that this is not an oam write
                    state <= 1;
                end
                3: // OAM ADDR 
                begin
                    oam_addr <= save_data ; 
                end
                4: // OAM DATA , 16 bits as well , will write the 16-bit word every second time 
                begin
                    oam_data_second <= oam_data_second + 1;

                    if ( oam_data_second ) // second write, write the data to oam_ram
                    begin
                        oam_write <= 1 ; // tell FSM that this is an OAM write
                        state <= 1 ; 
                    end

                    oam_dout <= { oam_dout[7:0] , save_data }; 
                end
            endcase
        end
        else 
        begin
            case (state)
                1:
                begin
                    state <= 2;
                    if ( oam_write && oam_addr_inc )
                        oam_addr <= oam_addr + 1;
                    else if ( mem_addr_inc )
                        mem_addr <= mem_addr + 1;
                end
                2:
                begin
                    state <= 0; // return control to the rest of the module 
                end 
            endcase   
        end
    end
end

// READING FROM THE PPU 

reg[7:0] driver;
assign data_bus = driver ;
always @(*)
begin
    if ( cs && we_b )
    begin
        case (reg_select)
            0:
                driver = { 7'b0 , v_blank }  ; // for now
            1:
                driver = mem_addr[7:0] ;
            2:
                driver = mem_dout ;
            3:
                driver = oam_addr ;
            4:
                driver = oam_dout[7:0] ;

            default:
                driver = 8'hFF ;

        endcase
    end
    else begin
        driver = 8'bZ ;
    end
end

always @(*)
begin
    oam_we = 0;
    oam_en = 0;
    mem_we = 0;
    mem_en = 0;

    case(state)
        1:
        begin
            if ( oam_write )
            begin
                oam_we = 1 ;
                oam_en = 1 ;
            end
            else
            begin
                mem_we = 1;
                mem_en = 1;
            end
        end
    endcase
end


// logic for to drive NMI line of CPU

reg nmi_done;
reg [3:0] nmi_counter;

always @( posedge clk )
begin
    if ( !reset_n )
    begin
        nmi_done <= 0;
        nmi_counter <= 0;
        cpu_nmi <= 1; // nmi line high 
    end
    else if ( v_blank )
    begin
        if ( !nmi_done && ppu_ctrl[2] ) // if NMI enabled and we should produce an NMI
        begin
            nmi_counter <= nmi_counter + 1;
            cpu_nmi <= 0;

            if ( nmi_counter == 4'b1111 )
            begin
                nmi_done <= 1 ;
                cpu_nmi <= 1 ;
            end
        end
    end
    else
    begin
        nmi_done <= 0 ;
        nmi_counter <= 0 ;
    end
end



endmodule