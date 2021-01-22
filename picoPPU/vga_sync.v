
module vga_sync(clk , reset_n , Hsync , Vsync , video_on , v_count , h_count , v_blank , h_blank );

  input clk , reset_n;
  output wire Hsync , Vsync;
	output wire video_on; 
	output reg  [9:0] v_count;
	output reg  [9:0] h_count;
  output wire v_blank , h_blank ;
    
    wire h_countmaxed = (h_count == 799); // 16 + 48 + 96 + 640
    wire v_countmaxed = (v_count == 524); // 10 + 2 + 33 + 480

    always @(posedge clk )
    begin
      if ( !reset_n )
        h_count <= 0 ;
      else
      begin
        if (h_countmaxed)
          h_count <= 0;
        else
          h_count <= h_count + 1;
      end
    end

    always @(posedge clk )
    begin
      if ( !reset_n )
        v_count <= 0 ;
      else
      begin
        if (h_countmaxed)
        begin
          if(v_countmaxed)
            v_count <= 0;
          else
            v_count <= v_count + 1;
        end
      end
      
    end

    assign Hsync = ~(h_count >= (640 + 16) && (h_count < (640 + 16 + 96)));   // active for 96 clocks
    assign Vsync = ~(v_count >= (480 + 10) && (v_count < (480 + 10 + 2)));   // active for 2 clocks
    assign video_on = (h_count < 640) && (v_count < 480);

    assign v_blank = (v_count >= 480) ;
    assign h_blank = ( h_count >= 640 ) ;  

endmodule
