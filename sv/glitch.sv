module fault_injector (
    input logic clk,
    input logic rst_n,
    input logic rx_done,
    input logic [7:0] rx_data,
    input logic trigger_in,
    output logic fault_out,
    output logic tx_start,
    output logic [7:0] tx_data,
    input logic tx_busy
);
    // Parameter command definitions
    localparam SET_OFFSET_CMD = 8'hA0;
    localparam SET_WIDTH_CMD = 8'hA1;
    localparam SET_REPEAT_CMD = 8'hA2;
    localparam GET_OFFSET_CMD = 8'hB0;
    localparam GET_WIDTH_CMD = 8'hB1;
    localparam GET_REPEAT_CMD = 8'hB2;
    localparam PING_CMD = 8'hC0;
    localparam ARM_CMD = 8'h01;
    localparam DISARM_CMD = 8'h02;
    localparam GET_ARM_STATE_CMD = 8'h03;
    localparam MANUAL_TRIGGER_CMD = 8'h04;
    
    // Response magic number for PING command
    localparam PING_RESPONSE = 8'h42;
    
    // UART command processing states
    typedef enum logic [4:0] {
        IDLE,
        WAIT_FOR_VALUE,
        WAIT_FOR_MULTI_BYTE_VALUE_BYTE0,
        WAIT_FOR_MULTI_BYTE_VALUE_BYTE1,
        WAIT_FOR_MULTI_BYTE_VALUE_BYTE2,
        WAIT_FOR_MULTI_BYTE_VALUE_BYTE3,
        PREPARE_RESPONSE,
        WAIT_TX_COMPLETE,
        SEND_MULTI_BYTE_RESPONSE_BYTE0,
        SEND_MULTI_BYTE_RESPONSE_BYTE1,
        SEND_MULTI_BYTE_RESPONSE_BYTE2,
        SEND_MULTI_BYTE_RESPONSE_BYTE3
    } uart_state_t;
    
    // Fault injection states
    typedef enum logic [2:0] {
        FI_IDLE,
        FI_WAIT_FOR_TRIGGER,
        FI_COUNT_OFFSET,
        FI_INJECT_FAULT,
        FI_WAIT_BETWEEN_REPEATS
    } fi_state_t;
    
    uart_state_t uart_state, next_uart_state;
    fi_state_t fi_state;
    
    // Fault injection parameters
    logic [31:0] offset;
    logic [31:0] width;
    logic [31:0] repeat_count;
    
    // Current command being processed and data for multi-byte operations
    logic [7:0] current_cmd;
    logic [31:0] response_data;
    logic [31:0] received_data;
    
    // Counters for operation
    logic [31:0] cycle_counter;
    logic [31:0] repeat_counter;
    
    // Flags
    logic disabled;
    logic enabled;

    // UART command processing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_state <= IDLE;
            next_uart_state <= IDLE;
            current_cmd <= 8'h00;
            offset <= 32'd0;
            width <= 32'd0;
            repeat_count <= 32'd1;
            enabled <= 1'b0;
            tx_start <= 1'b0;
            tx_data <= 8'h00;
            response_data <= 32'd0;
            received_data <= 32'd0;
        end else begin
            if (disabled == 1'b1) begin
                enabled <= 1'b0;
            end

            case (uart_state)
                IDLE: begin
                    tx_start <= 1'b0;
                    
                    // Check auto_disable from fault injection state machine
                    if (rx_done) begin
                        case (rx_data)
                            SET_OFFSET_CMD, SET_WIDTH_CMD, SET_REPEAT_CMD: begin
                                current_cmd <= rx_data;
                                received_data <= 32'd0; // Clear received data
                                uart_state <= WAIT_FOR_MULTI_BYTE_VALUE_BYTE0;
                            end
                            GET_OFFSET_CMD: begin
                                current_cmd <= rx_data;
                                response_data <= offset;
                                uart_state <= SEND_MULTI_BYTE_RESPONSE_BYTE0;
                            end
                            GET_WIDTH_CMD: begin
                                current_cmd <= rx_data;
                                response_data <= width;
                                uart_state <= SEND_MULTI_BYTE_RESPONSE_BYTE0;
                            end
                            GET_REPEAT_CMD: begin
                                current_cmd <= rx_data;
                                response_data <= repeat_count;
                                uart_state <= SEND_MULTI_BYTE_RESPONSE_BYTE0;
                            end
                            PING_CMD: begin
                                current_cmd <= rx_data;
                                uart_state <= PREPARE_RESPONSE;
                                tx_data <= PING_RESPONSE;
                            end
                            ARM_CMD: begin
                                enabled <= 1'b1;
                                uart_state <= IDLE;
                            end
                            DISARM_CMD: begin
                                enabled <= 1'b0;
                                uart_state <= IDLE;
                            end
                            GET_ARM_STATE_CMD: begin
                                current_cmd <= rx_data;
                                uart_state <= PREPARE_RESPONSE;
                                tx_data <= 8'b11110000 | enabled;
                            end
                            MANUAL_TRIGGER_CMD: begin
                                // Just send the manual trigger, fault injection state machine will handle it
                                current_cmd <= rx_data;
                                enabled <= 1'b1;
                                uart_state <= IDLE;
                            end
                            default: uart_state <= IDLE;
                        endcase
                    end
                end
                
                // States for receiving multi-byte values
                WAIT_FOR_MULTI_BYTE_VALUE_BYTE0: begin
                    if (rx_done) begin
                        received_data[31:24] <= rx_data; // MSB
                        uart_state <= WAIT_FOR_MULTI_BYTE_VALUE_BYTE1;
                    end
                end
                
                WAIT_FOR_MULTI_BYTE_VALUE_BYTE1: begin
                    if (rx_done) begin
                        received_data[23:16] <= rx_data;
                        uart_state <= WAIT_FOR_MULTI_BYTE_VALUE_BYTE2;
                    end
                end
                
                WAIT_FOR_MULTI_BYTE_VALUE_BYTE2: begin
                    if (rx_done) begin
                        received_data[15:8] <= rx_data;
                        uart_state <= WAIT_FOR_MULTI_BYTE_VALUE_BYTE3;
                    end
                end
                
                WAIT_FOR_MULTI_BYTE_VALUE_BYTE3: begin
                    if (rx_done) begin
                        received_data[7:0] <= rx_data; // LSB
                        
                        // Store the complete value based on the command
                        case (current_cmd)
                            SET_OFFSET_CMD: offset <= {received_data[31:8], rx_data};
                            SET_WIDTH_CMD: width <= {received_data[31:8], rx_data};
                            SET_REPEAT_CMD: repeat_count <= {received_data[31:8], rx_data};
                            default: ; // Do nothing
                        endcase
                        
                        uart_state <= IDLE;
                    end
                end
                
                
                PREPARE_RESPONSE: begin
                    if (!tx_busy) begin
                        tx_start <= 1'b1;
                        uart_state <= WAIT_TX_COMPLETE;
                    end
                end
                
                WAIT_TX_COMPLETE: begin
                    tx_start <= 1'b0;
                    if (!tx_busy) begin
                        // For single-byte responses (like PING)
                        if (current_cmd != GET_OFFSET_CMD && current_cmd != GET_WIDTH_CMD && current_cmd != GET_REPEAT_CMD) begin
                            uart_state <= IDLE;
                        end else begin
                            // For multi-byte responses, transition to the next state
                            uart_state <= next_uart_state;
                        end
                    end
                end
                
                // States for sending multi-byte responses
                SEND_MULTI_BYTE_RESPONSE_BYTE0: begin
                    if (!tx_busy) begin
                        tx_data <= response_data[31:24]; // MSB
                        tx_start <= 1'b1;
                        uart_state <= WAIT_TX_COMPLETE;
                        // Set the next state after WAIT_TX_COMPLETE
                        next_uart_state <= SEND_MULTI_BYTE_RESPONSE_BYTE1;
                    end
                end
                
                SEND_MULTI_BYTE_RESPONSE_BYTE1: begin
                    if (!tx_busy) begin
                        tx_data <= response_data[23:16];
                        tx_start <= 1'b1;
                        uart_state <= WAIT_TX_COMPLETE;
                        // Set the next state after WAIT_TX_COMPLETE
                        next_uart_state <= SEND_MULTI_BYTE_RESPONSE_BYTE2;
                    end
                end
                
                SEND_MULTI_BYTE_RESPONSE_BYTE2: begin
                    if (!tx_busy) begin
                        tx_data <= response_data[15:8];
                        tx_start <= 1'b1;
                        uart_state <= WAIT_TX_COMPLETE;
                        // Set the next state after WAIT_TX_COMPLETE
                        next_uart_state <= SEND_MULTI_BYTE_RESPONSE_BYTE3;
                    end
                end
                
                SEND_MULTI_BYTE_RESPONSE_BYTE3: begin
                    if (!tx_busy) begin
                        tx_data <= response_data[7:0]; // LSB
                        tx_start <= 1'b1;
                        uart_state <= WAIT_TX_COMPLETE;
                        // Set the next state after WAIT_TX_COMPLETE
                        next_uart_state <= IDLE;
                    end
                end
                
                default: uart_state <= IDLE;
            endcase
        end
    end

    // Fault injection processing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fi_state <= FI_IDLE;
            cycle_counter <= 32'd0;
            repeat_counter <= 32'd0;
            fault_out <= 1'b0;
            disabled <= 1'b0;
        end else begin
            case (fi_state)
                FI_IDLE: begin
                    fault_out <= 1'b0;
                    disabled <= 1'b0;
                    if (enabled) begin
                        fi_state <= FI_WAIT_FOR_TRIGGER;
                    end
                end

                FI_WAIT_FOR_TRIGGER: begin
                    if (!enabled) begin
                        fi_state <= FI_IDLE;
                    end else if (trigger_in || (current_cmd == MANUAL_TRIGGER_CMD && rx_done)) begin
                        cycle_counter <= 32'd0;
                        repeat_counter <= 32'd0;
                        fi_state <= FI_COUNT_OFFSET;
                    end
                end

                FI_COUNT_OFFSET: begin
                    if (!enabled) begin
                        fi_state <= FI_IDLE;
                    end else if (cycle_counter >= offset - 1) begin
                        cycle_counter <= 32'd0;
                        fi_state <= FI_INJECT_FAULT;
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end

                FI_INJECT_FAULT: begin
                    if (!enabled) begin
                        fault_out <= 1'b0;
                        fi_state <= FI_IDLE;
                    end else begin
                        fault_out <= 1'b1;
                        if (cycle_counter >= width - 1) begin
                            fault_out <= 1'b0;
                            cycle_counter <= 32'd0;
                            if (repeat_counter >= repeat_count - 1) begin
                                fi_state <= FI_IDLE;
                                disabled <= 1'b1;
                            end else begin
                                repeat_counter <= repeat_counter + 1;
                                fi_state <= FI_WAIT_BETWEEN_REPEATS;
                            end
                        end else begin
                            cycle_counter <= cycle_counter + 1;
                        end
                    end
                end

                FI_WAIT_BETWEEN_REPEATS: begin
                    if (!enabled) begin
                        fi_state <= FI_IDLE;
                    end else if (cycle_counter >= 32'd10 - 1) begin
                        cycle_counter <= 32'd0;
                        fi_state <= FI_INJECT_FAULT;
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end

                default: fi_state <= FI_IDLE;
            endcase
        end
    end
endmodule
