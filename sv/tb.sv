// Testbench for fault injection tool
module fault_injection_tb;
    // Testbench signals
    logic clk;
    logic rst_n;
    logic uart_rx_pin;
    logic trigger_in;
    logic fault_out;
    
    // Instantiate DUT
    fault_injection_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx_pin(uart_rx_pin),
        .trigger_in(trigger_in),
        .fault_out(fault_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // UART bit period for 115200 baud
    localparam BIT_PERIOD = 8680; // ns for 115200 baud
    
    // Task for sending a UART byte
    task send_uart_byte(input logic [7:0] data);
        // Start bit (low)
        uart_rx_pin = 1'b0;
        #BIT_PERIOD;
        
        // Data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            uart_rx_pin = data[i];
            #BIT_PERIOD;
        end
        
        // Stop bit (high)
        uart_rx_pin = 1'b1;
        #BIT_PERIOD;
    endtask
    
    // Test sequence
    initial begin
        // Initialize
        rst_n = 0;
        uart_rx_pin = 1;
        trigger_in = 0;
        #100;
        rst_n = 1;
        #100;
        
        // Set offset to 20 cycles
        send_uart_byte(8'hA0); // SET_OFFSET_CMD
        #BIT_PERIOD;
        send_uart_byte(8'h14); // 20 in decimal
        #(BIT_PERIOD * 2);
        
        // Set width to 10 cycles
        send_uart_byte(8'hA1); // SET_WIDTH_CMD
        #BIT_PERIOD;
        send_uart_byte(8'h0A); // 10 in decimal
        #(BIT_PERIOD * 2);
        
        // Set repeat to 3
        send_uart_byte(8'hA2); // SET_REPEAT_CMD
        #BIT_PERIOD;
        send_uart_byte(8'h03); // 3 repeats
        #(BIT_PERIOD * 2);
        
        // Enable the fault injector
        send_uart_byte(8'h01); // ENABLE_CMD
        #(BIT_PERIOD * 2);
        
        // Wait a bit then apply trigger
        #1000;
        trigger_in = 1;
        #20;
        trigger_in = 0;
        
        // Let simulation run to see fault injection
        #2000;
        
        // End simulation
        #10000 $finish;
    end
    
    // Monitor fault output
    initial begin
        $monitor("Time %t: fault_out = %b", $time, fault_out);
    end
endmodule