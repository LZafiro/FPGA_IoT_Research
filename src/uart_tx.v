// Designed by: Luiz Felipe Raveduti Zafiro - 02/10/2021


// Module for the UART_TX (transmiter)
// #########################################################################################
module uart_tx (
    input clock, // External board clock (used in state changing -> independent of baud tick)
    input reset, // Reset signal to IDLE state
    input tx_enable, // Signal to indicate if the recive is enabled -> // TODO: verify if it is realy necessary
    input [7:0] tx_data, // Register with the data that will be transmited
    input baud_tick, // Tick signal produced by the Baud Rate Generator module 
    output reg transmit_done = 1'd0, // Signal to indicate that the recive is done
    output reg tx // Output transmit signal (stored in a register) (1 bit -> serial)
);
// #########################################################################################
    

// Definition of some necessary registers, wires and parameters
// #########################################################################################
// Variables that represent each of the states of the state machine
parameter WRITE = 1'd0, IDLE = 1'd1;
// Sets the number of bits of the data recived (in our case we will recieve 8 bits)
parameter word_size = 4'd8;
// 1 bit register to store curent and next states of state machine
reg curent_state, next_state;
// The start_bit indicates it the current bit is the start bit and 
// read_enable indicates if the read process is or not enabled
reg start_bit = 1'd1, stop_bit = 1'd0, write_enable = 1'd0;
// Register that counts how many bits have been read already (data bits)
reg [4:0] bit_count = 5'd0;
// Counter to make sure we get the value of the bit exactly in the midle of it (must count 16 times in our case)
reg [3:0] counter = 4'd0; 
// Temporary data that will be transmited (stored after data register shift)
reg [7:0] tmp_transmit_data;
// #########################################################################################


/* A brief summary of the code organization:
*   As we are working with state machines we must have some logit to control it
*   A reset/continue logic
*   A next state logic
*   A read enable/disable logic
*   A data recive logic
*   A Output assign logic
*/
// #########################################################################################


// Reset/continue logic -> Same logic as rx module
// #########################################################################################
always@ (posedge clock or posedge reset)
begin
    if(reset) curent_state <= IDLE;
    else curent_state <= next_state;
end
// #########################################################################################


// Next state logic
// #########################################################################################
always@ (curent_state or tx_data or tx_enable or transmit_done)
begin
    case ( curent_state )
        WRITE: 
        begin
            // If the write process is done, returns to IDLE state
            if( transmit_done == 1'd1 )
                next_state = IDLE;
            else next_state = WRITE;
        end
        IDLE:
        begin
            // If the state is IDLE and we detect a start bit and the rx_enable is high
            if( tx_enable )
                next_state = WRITE;
            else next_state = IDLE;
        end 
        // The default case is to set the next state to IDLE (if something unexpected happens)
        default: 
        begin
            next_state = IDLE;
        end
    endcase    
end
// #########################################################################################


// Read enable/disable logic
// #########################################################################################
always@ (curent_state)
begin
    case( curent_state )
        WRITE:
        begin
            write_enable <= 1'd1;
        end
        IDLE:
        begin
            write_enable <= 1'd0;
        end
        // The dafault case is to disable the read
        default:
        begin
            write_enable <= 1'd0;
        end
    endcase
end
// #########################################################################################


// Data recive logic
// #########################################################################################
always@ (posedge baud_tick) 
begin
    // As soon as we are enabled to read, we must set that the reading is not over and increment the counter
    // that will make sure that we are getting the bit correctly
    if( write_enable )
    begin
        counter <= counter + 1;
        // If we are in the start bit, we must procude a low pulse for the transmission start_bit
        if( start_bit & !(stop_bit) )
        begin
            tx <= 1'd0; // Transmit a low pulse
            start_bit <= 1'd0;
            counter <= 4'd0;
            tmp_transmit_data <= tx_data;
        end
        // In these case we are picking each bit of the data from tx_data and sending to tx
        // with a period of 16 ticks
        if( (counter == 4'd16) & (!start_bit) & (bit_count < word_size) )
        begin
            // Here we store the rx input by shifting the received_data register and concatenating the value (FIFO)
            tmp_transmit_data <= {1'd0, tmp_transmit_data[7:1]};
            tx <= tmp_transmit_data[0];
            counter <= 4'd0;
            bit_count <= bit_count + 1;
        end
        // In this case we are in a bit detection but we now exceeded the word_size and we detect rx as 1 (stop bit)
        if( (counter == 4'd16) & (bit_count == word_size) )
        begin
            // Resets all counters 
            bit_count <= 5'd0;
            counter <= 4'd0;
            // Sets the recieve as done 
            transmit_done <= 1'd1;
            // Resets the start_bit signal as high (for the next write)
            start_bit <= 1'd0;
            // Sets stop_bit to high, indicating that we are in this signal
            stop_bit <= 1'd1;
            // Set tx as high (stop_bit)
            tx <= 1'd1;
            // Indicates that transfer is done
            transmit_done <= 1'd1;
        end
    end
    else // Resets these values to prepare for a future transmission
    begin
        start_bit = 1'd1;
        stop_bit = 1'd0;
        transmit_done = 1'd0;
    end
end
// #########################################################################################


// Output assign logic
// #########################################################################################
// always @(posedge clock)
// begin 
//     rx_data <= received_data;
// end
// #########################################################################################
endmodule