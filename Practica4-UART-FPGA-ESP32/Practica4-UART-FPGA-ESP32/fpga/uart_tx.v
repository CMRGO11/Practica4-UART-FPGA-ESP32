// ============================================================
// uart_tx.v : Transmisor UART 8N1
// Trama de 10 bits: inicio(0) + 8 datos (LSB primero) + paro(1)
// Cada bit dura CLKS_PER_BIT ciclos de clk.
// ============================================================
module uart_tx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       reset,      // activo en alto (asincrono)
    input  wire       tx_start,   // pulso de 1 ciclo para iniciar
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        busy
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;   // 5208

    reg [15:0] clk_count;
    reg [3:0]  bit_index;
    reg [9:0]  tx_shift;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx        <= 1'b1;
            busy      <= 1'b0;
            clk_count <= 16'd0;
            bit_index <= 4'd0;
            tx_shift  <= 10'b1111111111;
        end else begin
            if (!busy) begin
                tx <= 1'b1;
                if (tx_start) begin
                    busy      <= 1'b1;
                    tx_shift  <= {1'b1, data_in, 1'b0};   // paro, datos, inicio
                    clk_count <= 16'd0;
                    bit_index <= 4'd0;
                end
            end else begin
                tx <= tx_shift[0];
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 16'd1;
                end else begin
                    clk_count <= 16'd0;
                    tx_shift  <= {1'b1, tx_shift[9:1]};
                    if (bit_index < 9)
                        bit_index <= bit_index + 4'd1;
                    else begin
                        busy <= 1'b0;
                        tx   <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
