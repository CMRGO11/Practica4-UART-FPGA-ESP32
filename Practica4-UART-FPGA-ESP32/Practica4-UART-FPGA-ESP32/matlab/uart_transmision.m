% uart_transmision.m : envia bytes (0-255) a la FPGA a traves del ESP32
clear; clc;

PORT = "COM3";     % Cambiar por el puerto COM del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
pause(2);          % el ESP32 puede reiniciarse al abrir el puerto
flush(s);          % descarta bytes basura del arranque

disp("Transmision iniciada (Enter vacio para salir)");

while true
    valor = input('Ingrese un numero entre 0 y 255: ');
    if isempty(valor), break; end
    if ~isscalar(valor) || valor < 0 || valor > 255 || valor ~= floor(valor)
        disp('Valor fuera de rango');
        continue;
    end
    write(s, uint8(valor), "uint8");
    disp(['Enviado: ', num2str(valor)]);
end

clear s
