`timescale 1ns / 1ps

module tb_i2c_master;

    // Testbench signals
    reg clk;
    reg rst_n;        // <-- Fixed the "gt" typo here!
    reg start;
    reg [6:0] addr;
    reg rw;
    reg [7:0] data_in;
    wire scl;
    wire sda;
    wire busy;

    // Simulate Slave ACK Response behavior
    reg slave_ack_drive;
    
    // Combined Pull-up and Slave Drive emulation for the bidirectional SDA line
    // If slave_ack_drive is active, pull it low. Otherwise, let it float high-impedance (z)
    assign sda = (slave_ack_drive) ? 1'b0 : 1'bz; 

    // Instantiate the Unit Under Test (UUT)
    i2c_master uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .addr(addr),
        .rw(rw),
        .data_in(data_in),
        .scl(scl),
        .sda(sda),
        .busy(busy)
    );

    // 50 MHz System Clock Generator (Period = 20ns)
    always #10 clk = ~clk;

    initial begin
        // Setup Waveform Dumping for Icarus Verilog / GTKWave
        $dumpfile("i2c_sim.vcd");
        $dumpvars(0, tb_i2c_master);

        // Initialize Master Inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        addr = 7'h5A;       // Test Slave Address: 01011010
        rw = 0;             // 0 = Write operation
        data_in = 8'hA5;    // Data byte to send: 10100101
        slave_ack_drive = 0;

        // Release Reset after 100ns
        #100;
        rst_n = 1;
        #40;

        // Pulse Start Signal
        start = 1;
        #20;
        start = 0;

        // Wait loop to simulate slave pulling line down for ACK during the ACK state
        #200000; 
        
        // Transaction complete, end simulation
        $display("Simulation complete. Check GTKWave output.");
        $finish;
    end

endmodule