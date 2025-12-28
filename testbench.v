`timescale 1ns / 1ps

module test_bench;

    reg         clk;
    reg         reset;
    reg [15:0]  datain;

    wire        spi_cs_l;
    wire        spi_sclk;
    wire        spi_data;
    wire [4:0]  counter;

    integer frame_count;

    // DUT
    spi_state dut ( clk, reset, datain, spi_cs_l, spi_sclk, spi_data, counter );

    // ---------------- Clock Generation ----------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------- Frame Counter ----------------
    initial frame_count = 0;

    // ---------------- SPI Frame Completion Monitor ----------------
    always @(posedge spi_cs_l) begin
        if (!reset) begin
            frame_count = frame_count + 1;
            $display("--------------------------------------------------");
            $display("SPI FRAME %0d COMPLETED", frame_count);
            $display("Time      : %0t ns", $time);
            $display("Data Sent : 0x%04h", datain);
            $display("--------------------------------------------------");
        end
    end

    // OPTIONAL: Bit-level monitor (enable if needed)

    always @(posedge spi_sclk) begin
        if (spi_cs_l == 0)
            $display("Time=%0t | SCLK↑ | MOSI=%b | BitCount=%0d",
                      $time, spi_data, counter);
    end


    // ---------------- Test Sequence ----------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, test_bench);

        reset  = 1'b1;
        datain = 16'h0000;

        #30;
        reset = 1'b0;

        // -------- FRAME 1 --------
        wait (spi_cs_l == 1'b1);
        #10 datain = 16'h0412;
        wait (spi_cs_l == 1'b0);
        wait (spi_cs_l == 1'b1);

        #40;

        // -------- FRAME 2 --------
        datain = 16'h4839;
        wait (spi_cs_l == 1'b0);
        wait (spi_cs_l == 1'b1);

        #40;

        // -------- FRAME 3 --------
        datain = 16'hABEB;
        wait (spi_cs_l == 1'b0);
        wait (spi_cs_l == 1'b1);

        #50;

        $display("All SPI frames completed successfully at time %0t ns", $time);
        $finish;
    end

endmodule
