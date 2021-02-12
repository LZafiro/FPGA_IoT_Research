module uart_hc05(
	input clock,
	input rx,
	output tx,
	output [7:0] rx_data
);

reg [7:0] data = 8'b11001100;

wire tick, receive_done, rx_enable, transmit_done, tx_enable;

uart_baud_rate_generator baud(
		.clock(clock),
		.reset(1'b0),
		.baud_tick(tick),
);

uart_rx uartRx(
	.clock(clock), 
   .reset(1'b0), 
   .rx(rx),
   .rx_enable(1'b1), 
   .baud_tick(tick),
   .receive_done(receive_done),
   .rx_data(rx_data)
);

uart_tx uartTx(
	.clock(clock),
	.reset(1'b0),
	.tx_enable(1'b1),
	.tx_data(data),
	.baud_tick(tick),
	.transmit_done(transmit_done),
	.tx(tx)
);	

endmodule 