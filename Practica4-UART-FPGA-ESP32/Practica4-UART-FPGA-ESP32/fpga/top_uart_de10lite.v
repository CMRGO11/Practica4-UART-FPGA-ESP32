// ============================================================
// top_uart_de10lite.v : Modulo superior (DE10-Lite)
// Recibe un byte por UART, le suma 1 y lo retransmite.
// El byte procesado tambien se muestra en LEDR[7:0].
//
// El registro 'pending' guarda que hay un byte por responder, de
// modo que no se pierde si el transmisor aun esta ocupado.
// ============================================================
module top_uart_de10lite (
    input  wire       CLOCK_50,
    input  wire       RESET_N,     // KEY0 (activo en bajo)
    input  wire       UART_RX,     // desde GPIO17 del ESP32
    output wire       UART_TX,     // hacia  GPIO16 del ESP32
    output reg  [7:0] LEDR
);

    wire reset = ~RESET_N;

    wire [7:0] rx_data;
    wire       rx_done;
    reg  [7:0] tx_data;
    reg        tx_start;
    wire       tx_busy;
    reg        pending;

    uart_rx #(.CLK_FREQ(50000000), .BAUD_RATE(9600)) RX0 (
        .clk        (CLOCK_50),
        .reset      (reset),
        .rx         (UART_RX),
        .data_out   (rx_data),
        .data_valid (rx_done)
    );

    uart_tx #(.CLK_FREQ(50000000), .BAUD_RATE(9600)) TX0 (
        .clk      (CLOCK_50),
        .reset    (reset),
        .tx_start (tx_start),
        .data_in  (tx_data),
        .tx       (UART_TX),
        .busy     (tx_busy)
    );

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            tx_data  <= 8'd0;
            tx_start <= 1'b0;
            pending  <= 1'b0;
            LEDR     <= 8'd0;
        end else begin
            tx_start <= 1'b0;

            if (rx_done)
                pending <= 1'b1;                    // hay un byte por responder

            if (pending && !tx_busy) begin          // transmisor libre
                tx_data  <= rx_data + 8'd1;         // procesamiento: +1 (255 -> 0)
                LEDR     <= rx_data + 8'd1;
                tx_start <= 1'b1;
                pending  <= 1'b0;
            end
        end
    end

endmodule
