% uart_recepcion.m : muestra los bytes que llegan desde la FPGA
% (Ctrl+C para detener)
clear; clc;

PORT = "COM3";     % Cambiar por el puerto COM del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
pause(2);
flush(s);

disp("Esperando datos desde FPGA ...");

while true
    if s.NumBytesAvailable > 0
        dato = read(s, 1, "uint8");
        disp(['Recibido: ', num2str(double(dato))]);
    end
    pause(0.01);   % evita ocupar el 100 % de la CPU
end
