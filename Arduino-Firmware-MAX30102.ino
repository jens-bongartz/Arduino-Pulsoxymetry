#include <MAX30105.h>
#include <Wire.h>
#include "MAX30105.h"

MAX30105 particleSensor;

  long ir_wert;
  long rot_wert;
  long t=0;

void setup()
{
 Serial.begin(115200);

  // Initialize sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) //Use default I2C port, 400kHz speed
  {
    Serial.println("MAX30105 was not found. Please check wiring/power. ");
    while (1);
  }

  byte ledBrightness = 90; // Optionen: 0 = Aus bis 255 = 50 mA
  byte sampleAverage = 4 ; // Optionen: 1, 2, 4, 8, 16, 32
  byte ledMode = 2 ; // Optionen: 1 = nur Rot, 2 = Rot + IR, 3 = Rot + IR + Grün
  byte sampleRate = 400 ; // Optionen: 50, 100, 200, 400, 800, 1000, 1600, 3200
  int pulsWidth = 118 ; // Optionen: 69, 118, 215, 411
  int adcRange = 16384 ; // Optionen: 2048, 4096, 8192, 16384

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulsWidth, adcRange); // Sensor mit diesen Einstellungen konfigurieren
}


void loop()
{
  ir_wert= particleSensor.getIR();
  rot_wert= particleSensor.getRed();

  Serial.print("rot:");
  Serial.print(rot_wert);
  Serial.print(",");
  Serial.print("ir:");
  Serial.print(ir_wert);
  Serial.print(",");
  Serial.print("t:");
  Serial.println(millis()-t); 
  t = millis();

}
