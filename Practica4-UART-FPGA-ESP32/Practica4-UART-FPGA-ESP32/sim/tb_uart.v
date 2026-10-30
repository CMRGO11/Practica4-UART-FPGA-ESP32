// Testbench: envia bytes por UART_RX a 9600 8N1 y comprueba que
// UART_TX responde con (byte + 1) mod 256. Incluye bytes consecutivos
// sin espacio entre ellos (prueba del registro 'pending').
`timescale 1ns/1ps
module tb_uart;
    localparam integer BIT_NS = 5208 * 20;   // 5208 ciclos de 20 ns

    reg  CLOCK_50 = 0, RESET_N = 0, UART_RX = 1;
    wire UART_TX;
    wire [7:0] LEDR;
    always #10 CLOCK_50 = ~CLOCK_50;

    top_uart_de10lite dut (.CLOCK_50(CLOCK_50), .RESET_N(RESET_N),
                           .UART_RX(UART_RX), .UART_TX(UART_TX), .LEDR(LEDR));

    integer errors = 0, n_resp = 0;
    reg [7:0] expected [0:15];
    integer n_sent = 0;

    task send_byte(input [7:0] b);
        integer i;
        begin
            UART_RX = 0; #(BIT_NS);                      // inicio
            for (i = 0; i < 8; i = i + 1) begin UART_RX = b[i]; #(BIT_NS); end
            UART_RX = 1; #(BIT_NS);                      // paro
            expected[n_sent] = b + 8'd1;
            n_sent = n_sent + 1;
        end
    endtask

    // Monitor de UART_TX (muestrea en el centro de cada bit)
    reg [7:0] got;
    integer k;
    initial begin
        forever begin
            @(negedge UART_TX);
            #(BIT_NS/2);
            if (UART_TX !== 1'b0) begin $display("FALSO INICIO"); errors = errors + 1; end
            for (k = 0; k < 8; k = k + 1) begin #(BIT_NS); got[k] = UART_TX; end
            #(BIT_NS);
            if (UART_TX !== 1'b1) begin $display("ERROR: bit de paro"); errors = errors + 1; end
            if (got === expected[n_resp]) $display("OK  : respuesta %0d (esperado %0d)", got, expected[n_resp]);
            else begin $display("FAIL: respuesta %0d (esperado %0d)", got, expected[n_resp]); errors = errors + 1; end
            n_resp = n_resp + 1;
        end
    end

    initial begin
        #200 RESET_N = 1;
        #(BIT_NS*2);
        send_byte(8'd50);  #(BIT_NS*12);
        send_byte(8'd66);  #(BIT_NS*12);
        send_byte(8'd23);  #(BIT_NS*12);
        send_byte(8'd255); #(BIT_NS*12);   // caso limite -> 0
        send_byte(8'd0);   #(BIT_NS*12);
        send_byte(8'hA5);  #(BIT_NS*12);   // patron asimetrico (detecta corrimientos)
        send_byte(8'd10);  send_byte(8'd25); send_byte(8'd100);   // consecutivos
        #(BIT_NS*30);
        if (n_resp == n_sent && errors == 0) $display("RESULTADO: PASS (%0d/%0d respuestas correctas)", n_resp, n_sent);
        else $display("RESULTADO: FAIL (errores=%0d, respuestas=%0d/%0d)", errors, n_resp, n_sent);
        $finish;
    end
endmodule
