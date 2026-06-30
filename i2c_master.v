module i2c_master (
    input wire clk,          // High-speed system clock (e.g., 50MHz)
    input wire rst_n,        // Active-low asynchronous reset
    input wire start,        // Trigger pulse to start a transaction
    input wire [6:0] addr,   // 7-bit Slave target address
    input wire rw,           // 0 for Write, 1 for Read
    input wire [7:0] data_in,// 8-bit data byte to transmit
    output reg scl,          // I2C Serial Clock line
    inout wire sda,          // I2C Serial Data line (bidirectional)
    output reg busy          // High when a transaction is active
);

    // State Encoding using Localparams
    localparam STATE_IDLE   = 3'b000;
    localparam STATE_START  = 3'b001;
    localparam STATE_ADDR   = 3'b010;
    localparam STATE_ACK    = 3'b011;
    localparam STATE_DATA   = 3'b100;
    localparam STATE_STOP   = 3'b101;

    reg [2:0] current_state, next_state;
    reg [7:0] clock_divider;  // To generate SCL from system clock
    reg scl_enable;           // Controls when SCL toggles
    reg [3:0] bit_counter;    // Keeps track of bits shifted out
    reg [7:0] tx_buffer;      // Internal buffer for Address/Data shifts
    reg sda_out;              // Internal register driving the SDA line
    reg sda_oe;               // SDA Output Enable (1 = Drive line, 0 = High Impedance/Listen)

    // Bidirectional SDA line handling
    assign sda = (sda_oe) ? sda_out : 1'bz;

    // Simple Clock Divider for SCL (Generates slower I2C clock tick)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clock_divider <= 8'd0;
            scl <= 1'b1;
        end else begin
            if (clock_divider == 8'd249) begin // Adjust for your clock frequencies
                clock_divider <= 8'd0;
                if (scl_enable) scl <= ~scl;
                else scl <= 1'b1;
            end else begin
                clock_divider <= clock_divider + 1'b1;
            end
        end
    end

    // FSM State Transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= STATE_IDLE;
        else
            current_state <= next_state;
    end

    // FSM Next-State & Combinational Logic
    always @(*) begin
        next_state = current_state;
        sda_out = 1'b1;
        sda_oe = 1'b1;
        scl_enable = 1'b1;
        busy = 1'b1;

        case (current_state)
            STATE_IDLE: begin
                busy = 1'b0;
                scl_enable = 1'b0;
                sda_out = 1'b1;
                sda_oe = 1'b1;
                if (start) next_state = STATE_START;
            end

            STATE_START: begin
                sda_out = 1'b0; // SDA pulled LOW while SCL is HIGH
                sda_oe = 1'b1;
                scl_enable = 1'b0; 
                if (clock_divider == 8'd249) next_state = STATE_ADDR;
            end

            STATE_ADDR: begin
                sda_out = tx_buffer[7]; // MSB first
                sda_oe = 1'b1;
                if (clock_divider == 8'd249 && scl == 1'b0) begin
                    if (bit_counter == 4'd7) next_state = STATE_ACK;
                end
            end

            STATE_ACK: begin
                sda_oe = 1'b0; // Release SDA line to listen for Slave ACK
                if (clock_divider == 8'd249 && scl == 1'b0) begin
                    next_state = STATE_DATA;
                end
            end

            STATE_DATA: begin
                sda_out = tx_buffer[7];
                sda_oe = 1'b1;
                if (clock_divider == 8'd249 && scl == 1'b0) begin
                    if (bit_counter == 4'd7) next_state = STATE_STOP;
                end
            end

            STATE_STOP: begin
                sda_out = 1'b0;
                sda_oe = 1'b1;
                if (clock_divider == 8'd249 && scl == 1'b1) begin
                    sda_out = 1'b1; // SDA pulled HIGH while SCL is HIGH
                    next_state = STATE_IDLE;
                end
            end
        endcase
    end

    // Sequential Control Logic for Counters and Buffers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 4'd0;
            tx_buffer <= 8'd0;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    if (start) begin
                        tx_buffer <= {addr, rw}; // Pack address and R/W bit
                        bit_counter <= 4'd0;
                    end
                end
                STATE_ADDR, STATE_DATA: begin
                    if (clock_divider == 8'd249 && scl == 1'b0) begin
                        if (bit_counter == 4'd7) begin
                            bit_counter <= 4'd0;
                            tx_buffer <= data_in; // Pre-load data buffer
                        end else begin
                            bit_counter <= bit_counter + 1'b1;
                            tx_buffer <= {tx_buffer[6:0], 1'b0}; // Shift left
                        end
                    end
                end
            endcase
        end
    end

endmodule