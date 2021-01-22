module mult_display ( clk , data , segment , an ) ;

input  clk ;
input [15:0] data ;
output wire [6:0] segment ;
output reg [3:0] an ; 

reg [19:0] counter ;
reg [3:0] mapper_in ;

seg7 mapper ( segment , mapper_in ) ; 

always@ ( posedge clk )
begin
    counter <= counter + 1 ; 
end


always@ ( * )
begin
    case ( counter[19:18] )
        0 : begin 
            an <= 4'b1110 ;
            mapper_in <= data[3:0] ;
        end 

        1: begin 
            an <= 4'b1101 ;
            mapper_in <= data[7:4] ;
        end

        2: begin
            an <= 4'b1011 ;
            mapper_in <= data[11:8] ;
        end 

        3: begin 
            an <= 4'b0111 ;
            mapper_in <= data[15:12] ;
        end

    endcase

end 


endmodule