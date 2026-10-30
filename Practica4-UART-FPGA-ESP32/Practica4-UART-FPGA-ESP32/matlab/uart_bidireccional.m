% uart_bidireccional.m : envia un byte, lee la respuesta de la FPGA
% y la compara contra el valor esperado (byte + 1, modulo 256).
clear; clc;

PORT = "COM3";     % Cambiar por el puerto COM del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
pause(2);          % el ESP32 puede reiniciarse al abrir el puerto
flush(s);          % descarta bytes basura del arranque

disp("Comunicacion bidireccional iniciada (Enter vacio para salir)");
disp("La FPGA regresara el byte recibido mas 1");

while true
    valor = input('Ingrese un numero entre 0 y 255: ');
    if isempty(valor), break; end
    if ~isscalar(valor) || valor < 0 || valor > 255 || valor ~= floor(valor)
        disp('Valor fuera de rango');
        continue;
    end

    flush(s);                               % limpia respuestas anteriores
    write(s, uint8(valor), "uint8");
    disp(['Enviado: ', num2str(valor)]);
    pause(0.1);

    if s.NumBytesAvailable > 0
        respuesta = double(read(s, 1, "uint8"));
        esperado  = mod(valor + 1, 256);    % 255 -> 0
        if respuesta == esperado
            estado = 'OK';
        else
            estado = 'ERROR';
        end
        fprintf('Respuesta de FPGA: %d   (esperado %d)  %s\n\n', ...
                respuesta, esperado, estado);
    else
        disp('No se recibio respuesta');
    end
end

clear s
