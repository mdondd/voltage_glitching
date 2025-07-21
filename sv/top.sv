module fault_injection_top (
    input logic sysclk,
    input logic [1:0] btn,
    input logic uart_rx_pin,
    input logic trigger_in,

    output logic fault_out,
    output logic uart_tx_pin,

    output logic [1:0] test
);
    // Internal signals
    logic rx_done;
    logic [7:0] rx_data;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic tx_done;
    
    // Instantiate UART receiver
    uart_rx #(
        .CLKS_PER_BIT(1250)
    ) uart_receiver (
        .clk(sysclk),
        .rst_n(rst_n),
        .rx(uart_rx_pin),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );
    
    // Instantiate UART transmitter
    uart_tx #(
        .CLKS_PER_BIT(1250)
    ) uart_transmitter (
        .clk(sysclk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(uart_tx_pin),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );
    
    // Instantiate fault injector
    fault_injector fault_controller (
        .clk(sysclk),
        .rst_n(rst_n),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .trigger_in(trigger_in),
        .fault_out(fault_out),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_busy(tx_busy)
    );

    assign rst_n = 1;//~btn[0];

    assign test[0] = sysclk;
    //assign test[1] = uart_rx_pin;

endmodule
