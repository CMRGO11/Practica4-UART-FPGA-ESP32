// ============================================================
// esp32_puente_uart.ino : Puente transparente USB <-> UART (FPGA)
//   Serial       (USB)   <-> PC / MATLAB
//   FPGA_Serial  (UART2) <-> FPGA DE10-Lite
//
// Conexion (cruzada, con GND comun):
//   GPIO17 (TX ESP32) -> UART_RX FPGA
//   GPIO16 (RX ESP32) <- UART_TX FPGA
//   GND               -> GND
//
// Nota: no se imprime ningun mensaje de bienvenida; cualquier byte
// extra que salga por USB llegaria a MATLAB como si fuera una
// respuesta de la FPGA.
// ============================================================
#include <Arduino.h>

static const int      FPGA_RX_PIN = 16;   // RX del ESP32 <- TX de la FPGA
static const int      FPGA_TX_PIN = 17;   // TX del ESP32 -> RX de la FPGA
static const uint32_t PC_BAUD     = 9600;
static const uint32_t FPGA_BAUD   = 9600;

HardwareSerial FPGA_Serial(2);

void setup() {
  Serial.begin(PC_BAUD);
  delay(500);
  FPGA_Serial.begin(FPGA_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
}

void loop() {
  // PC -> FPGA
  while (Serial.available()) {
    uint8_t dato = (uint8_t)Serial.read();
    FPGA_Serial.write(dato);
  }
  // FPGA -> PC
  while (FPGA_Serial.available()) {
    uint8_t dato = (uint8_t)FPGA_Serial.read();
    Serial.write(dato);
  }
}
