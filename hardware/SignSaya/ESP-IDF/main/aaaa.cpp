#include "Arduino.h"
#include "../components/ICM20948/ICM_20948.h"

void setup(){
  Serial.begin(115200);
}

void loop(){
    Serial.println("Hello world!");
    delay(1000);
}
