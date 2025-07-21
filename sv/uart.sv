module uart_rx
#(
    parameter CLKS_PER_BIT = 1250 // For 9600 baud with 12MHz clock (12000000/9600)
)
(
    input logic clk,
    input logic rst_n,
    input logic rx,
    output logic rx_done,
    output logic [7:0] rx_data
);
    // UART RX States
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT,
        CLEANUP
    } state_t;
    
    state_t state = IDLE;
    
    logic [31:0] clk_count;
    logic [2:0] bit_index;
    logic [7:0] rx_data_temp;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            rx_data <= 8'h00;
            rx_data_temp <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    rx_done <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (rx == 1'b0)  // Start bit detected
                        state <= START_BIT;
                    else
                        state <= IDLE;
                end
                
                START_BIT: begin
                    // Check middle of start bit
                    if (clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (rx == 1'b0) begin
                            // Still low, confirmed start bit
                            clk_count <= 0;
                            state <= DATA_BITS;
                        end else
                            state <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                        state <= START_BIT;
                    end
                end
                
                DATA_BITS: begin
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                        state <= DATA_BITS;
                    end else begin
                        clk_count <= 0;
                        // Sample the data bit
                        rx_data_temp[bit_index] <= rx;
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                            state <= DATA_BITS;
                        end else begin
                            bit_index <= 0;
                            state <= STOP_BIT;
                        end
                    end
                end
                
                STOP_BIT: begin
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                        state <= STOP_BIT;
                    end else begin
                        rx_done <= 1'b1;
                        clk_count <= 0;
                        state <= CLEANUP;
                        rx_data <= rx_data_temp;
                    end
                end
                
                CLEANUP: begin
                    state <= IDLE;
                    rx_done <= 1'b0;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule