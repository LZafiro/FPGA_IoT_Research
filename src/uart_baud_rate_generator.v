module uart_baud_rate_generator(
    input clock,
    input reset,
    output baud_tick = 1'd0
);

// Register used to count for tick creation
reg [15:0] baudRate_count = 16'd0; 

parameter baudRate = 16'd325; // Explain equation

always@ (posedge clock or posedge reset)
begin
	if(reset)
		baudRate_count <= 16'd1;
	else if(baud_tick == 1'd1)
		baudRate_count <= 16'd1;
		else
			baudRate_count <= baudRate_count + 1;
end

assign baud_tick = (baudRate_count == 16'd325);

endmodule 

