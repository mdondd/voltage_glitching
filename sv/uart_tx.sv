module uart_tx
#(
    parameter CLKS_PER_BIT = 1250 // For 9600 baud with 12MHz clock (12000000/9600)
)
(
    input logic clk,
    input logic rst_n,
    input logic tx_start,
    input logic [7:0] tx_data,
    output logic tx,
    output logic tx_busy,
    output logic tx_done
);
    // UART TX States
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
    logic [7:0] tx_data_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;         // Idle state is high
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            tx_data_reg <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;         // Idle state is high
                    tx_busy <= 1'b0;
                    tx_done <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        tx_busy <= 1'b1;
                        state <= START_BIT;
                    end
                end
                
                START_BIT: begin
                    tx <= 1'b0;  // Start bit is low
                    
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                        state <= START_BIT;
                    end else begin
                        clk_count <= 0;
                        state <= DATA_BITS;
                    end
                end
                
                DATA_BITS: begin
                    tx <= tx_data_reg[bit_index];
                    
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                        state <= DATA_BITS;
                    end else begin
                        clk_count <= 0;
                        
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
                    tx <= 1'b1;  // Stop bit is high
                    
                    if (clk_count < CLKS_PER_BIT-1) begin
                        clk_count <= clk_count + 1;
                        state <= STOP_BIT;
                    end else begin
                        tx_done <= 1'b1;
                        clk_count <= 0;
                        state <= CLEANUP;
                    end
                end
                
                CLEANUP: begin
                    tx_busy <= 1'b0;
                    tx_done <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
