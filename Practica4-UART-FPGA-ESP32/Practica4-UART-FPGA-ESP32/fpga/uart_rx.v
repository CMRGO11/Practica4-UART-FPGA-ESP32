// ============================================================
// uart_rx.v : Receptor UART 8N1 (version corregida)
//
// Correcciones respecto a la guia:
//  1) La entrada rx es asincrona: se sincroniza con 2 flip-flops.
//  2) Maquina de estados IDLE/START/DATA/STOP. Tras detectar el
//     flanco de bajada se espera medio bit, se confirma que el bit
//     de inicio sigue en 0 y SOLO ENTONCES se muestrean los 8 bits
//     de datos, cada uno en su centro. (En la version original el
//     primer muestreo caia sobre el bit de inicio y los datos
//     quedaban desplazados un bit.)
//  3) data_valid solo se activa si el bit de paro es 1.
// ============================================================
module uart_rx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       reset,        // activo en alto (asincrono)
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        data_valid    // pulso de 1 ciclo
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;   // 5208
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;       // 2604

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift;

    // Sincronizador de 2 flip-flops
    reg rx_meta, rx_s;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_s    <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_s    <= rx_meta;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= S_IDLE;
            clk_count  <= 16'd0;
            bit_index  <= 3'd0;
            rx_shift   <= 8'd0;
            data_out   <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (rx_s == 1'b0)             // flanco de bajada: posible inicio
                        state <= S_START;
                end

                S_START: begin                    // ir al centro del bit de inicio
                    if (clk_count == HALF_BIT - 1) begin
                        clk_count <= 16'd0;
                        if (rx_s == 1'b0)
                            state <= S_DATA;      // inicio valido
                        else
                            state <= S_IDLE;      // ruido: descartar
                    end else
                        clk_count <= clk_count + 16'd1;
                end

                S_DATA: begin                     // un muestreo por bit, en su centro
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count          <= 16'd0;
                        rx_shift[bit_index] <= rx_s;
                        if (bit_index == 3'd7)
                            state <= S_STOP;
                        else
                            bit_index <= bit_index + 3'd1;
                    end else
                        clk_count <= clk_count + 16'd1;
                end

                S_STOP: begin                     // centro del bit de paro
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        state     <= S_IDLE;
                        if (rx_s == 1'b1) begin
                            data_out   <= rx_shift;
                            data_valid <= 1'b1;
                        end
                    end else
                        clk_count <= clk_count + 16'd1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
