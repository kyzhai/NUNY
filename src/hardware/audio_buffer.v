module audio_buffer ( rclk,		// read from avalon bus
	  wclk,		// write to audio_effects
     reset,
	 audio_ip,
	  read,     //sample_req from audio_codec
     audio_out,
	  audio_irq
);


input rclk,wclk,reset,read;
input [15:0] audio_ip;
output [15:0] audio_out;
output audio_irq;


reg [15:0] buffer1 [0:99];
reg [15:0] buffer2 [0:99];
reg [6:0]  indexr = 7'd0;
reg [6:0]  indexr_prev = 7'd0;
reg [6:0]  indexw = 7'd0;
reg buf_cnt = 1'b0;
reg start_read;
reg irq;
reg irq_prev;
wire irq_edge;
reg [15:0] audio_out;
assign audio_irq = irq;

always @(posedge rclk) 
	irq_prev<= audio_irq;

assign irq_edge = audio_irq & (~irq_prev);	



always @(posedge rclk) begin
 if (reset ) begin
		start_read <= 0;
		indexr <= 7'd00;
	end else if (irq_edge)
	indexr_prev <= 0;
   else if (indexr_prev < 100) begin
                start_read <= 1'd1;
					 indexr_prev <= indexr;
						indexr <= indexr + 1'b1;
	end else begin 
                start_read <= 1'd0;
					 indexr <= 0;
	end
	end
	
					 
always @(posedge rclk) begin
	if (start_read) begin    // write enable for buffer
		if (buf_cnt==0)
				buffer1[indexr] <= audio_ip;
		else 
				buffer2[indexr] <= audio_ip;
	end
end 


always @(posedge wclk) begin
		if (reset ) begin
		indexw <= 7'd00;
	   irq <= 0;
		end
		else if (read) begin
			if (indexw == 7'd99) begin
                indexw <= 7'd00;
					 buf_cnt <= buf_cnt + 1'b1;
					 irq <= 1;
			end
			else begin
                indexw <= indexw + 1'b1;
					 irq <= 0;
				end
			if (buf_cnt==0)
				 audio_out <= buffer2[indexw];
			else 
				audio_out <= buffer1[indexw];
	end			
end

endmodule
