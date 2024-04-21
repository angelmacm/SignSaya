//#include <Arduino.h>
#include "types.h"
#include "config.h"
#include "bleSetup.h"
// #include "dmpIMU.h"
#include "imutest.h"
#include "fingers.h"

accelSensor ACCEL;
bleInstance ble;

FingerInstance pinkyFinger(PINKYPIN);
FingerInstance ringFinger(RINGPIN);
FingerInstance middleFinger(MIDDLEPIN);
FingerInstance indexFinger(INDEXPIN);
FingerInstance thumbFinger(THUMBPIN);

int packageSent = 0;

fingerError fingerErrorCheck = { 0, 0, 0, 0, 0 };

QueueHandle_t pinkyQueue;
QueueHandle_t ringQueue;
QueueHandle_t middleQueue;
QueueHandle_t indexQueue;
QueueHandle_t thumbQueue;
QueueHandle_t handQueue;
QueueHandle_t IMUQueue;

TaskHandle_t imuTask;
TaskHandle_t imuChecker;
TaskHandle_t pinkyTask;
TaskHandle_t ringTask;
TaskHandle_t middleTask;
TaskHandle_t indexTask;
TaskHandle_t thumbTask;
TaskHandle_t senderTask;
TaskHandle_t parserTask;

int missedIMUData = 0;

long lastCountdown = 0;

uint8_t core1Tel = 0;
uint8_t core0Tel = 0;

volatile unsigned long lastIMUrun = millis();

void pinkyFingerFunc(void *pvParameters);
void ringFingerFunc(void *pvParameters);
void middleFingerFunc(void *pvParameters);
void indexFingerFunc(void *pvParameters);
void thumbFingerFunc(void *pvParameters);
void accelGyroFunc(void *pvParameters);
void dataParser(void *pvParameters);
void bleSender(void *pvParameters);


void setup() {
  pinMode(HANDPIN, INPUT);
  Serial.begin(115200);
  while (!Serial) {
    delay(10);
  };
  String handSide;
  int randNumber = random(100000);
  String UBluetoothName = bluetoothName;
  if (digitalRead(HANDPIN)) {
    handSide = "R";
  } else {
    handSide = "L";
  }

  UBluetoothName += handSide + randNumber;
  char uBlCharArray[UBluetoothName.length() + 1];
  UBluetoothName.toCharArray(uBlCharArray, UBluetoothName.length() + 1);
  ble.begin(uBlCharArray);
  ACCEL.begin(I2C_SDA_PIN, I2C_SCL_PIN, IMU_INTERRUPT);

  // attachInterrupt(digitalPinToInterrupt(IMU_INTERRUPT), sensorISR, RISING);

  pinkyQueue = xQueueCreate(fingerQueueLength, sizeof(uint8_t));
  ringQueue = xQueueCreate(fingerQueueLength, sizeof(uint8_t));
  middleQueue = xQueueCreate(fingerQueueLength, sizeof(uint8_t));
  indexQueue = xQueueCreate(fingerQueueLength, sizeof(uint8_t));
  thumbQueue = xQueueCreate(fingerQueueLength, sizeof(uint8_t));

  handQueue = xQueueCreate(handQueueLength, sizeof(handData_t));
  IMUQueue = xQueueCreate(IMUQueueLength, sizeof(uint16_t));

  xTaskCreatePinnedToCore(&bleChecker, "bleBoss", 10240, NULL, 1, NULL, SYSTEMCORE);
  xTaskCreatePinnedToCore(&telPrint, "telPrint", 10240, NULL, 1, NULL, SYSTEMCORE);

  xTaskCreatePinnedToCore(&telemetryCore1, "telemetry1", 2048, NULL, 0, NULL, 1);
  xTaskCreatePinnedToCore(&telemetryCore0, "telemetry0", 2048, NULL, 0, NULL, 0);
}

void loop() {
}

/*--------------------------------------------------*/
/*---------------------- Tasks ---------------------*/
/*--------------------------------------------------*/

void bleChecker(void *pvParameters) {
  bool initializedTasks = false;
  Serial.println("No devices connected... waiting to connect to run tasks");
  for (;;) {
    if (ble.isConnected() && !initializedTasks) {
      Serial.println("Running Tasks");
      xTaskCreatePinnedToCore(&pinkyFingerFunc, "pinkyFunc", fingerStackSize, NULL, fingerPriority, &pinkyTask, APPCORE);
      xTaskCreatePinnedToCore(&ringFingerFunc, "ringFunc", fingerStackSize, NULL, fingerPriority, &ringTask, APPCORE);
      xTaskCreatePinnedToCore(&middleFingerFunc, "middleFunc", fingerStackSize, NULL, fingerPriority, &middleTask, APPCORE);
      xTaskCreatePinnedToCore(&indexFingerFunc, "indexFunc", fingerStackSize, NULL, fingerPriority, &indexTask, APPCORE);
      xTaskCreatePinnedToCore(&thumbFingerFunc, "thumbFunc", fingerStackSize, NULL, fingerPriority, &thumbTask, APPCORE);

      xTaskCreatePinnedToCore(&accelGyroFunc, "mpuFunc", mpuStackSize, NULL, 10, &imuTask, APPCORE);
      // xTaskCreatePinnedToCore(&checkIMUData, "mpuChecker", 1024, NULL, accelPriority, &imuChecker, APPCORE);

      xTaskCreatePinnedToCore(&dataParser, "dataPreparation", 10240, NULL, blePriority, &parserTask, SYSTEMCORE);
      xTaskCreatePinnedToCore(&bleSender, "dataTransmission", 10240, NULL, blePriority, &senderTask, SYSTEMCORE);
      initializedTasks = true;
      Serial.println("Tasks successfuly ran");
    } else {
      vTaskDelay(pdMS_TO_TICKS(1000));
    }
  }
}

void bleSender(void *pvParameters) {
  handData_t message;
  for (;;) {
    if ((int)xQueueReceive(handQueue, &message, 0) == pdTRUE) {
      uint8_t sendData[] = { message.pinky,
                             message.ring,
                             message.middle,
                             message.index,
                             message.thumb,
                             message.angles.q0,
                             message.angles.q1,
                             message.angles.q2,
                             message.angles.q3 };
      ble.write(sendData);
    }
    vTaskDelay(pdMS_TO_TICKS(1));
  }
}

void dataParser(void *pvParameters) {
  handData_t machineData;
  for (;;) {
    // unsigned long start = micros();
    //Receive data from gloves queue
    int pinkyStatus = xQueueReceive(pinkyQueue, &machineData.pinky, fingerQueueWait);
    int ringStatus = xQueueReceive(ringQueue, &machineData.ring, fingerQueueWait);
    int middleStatus = xQueueReceive(middleQueue, &machineData.middle, fingerQueueWait);
    int indexStatus = xQueueReceive(indexQueue, &machineData.index, fingerQueueWait);
    int thumbStatus = xQueueReceive(thumbQueue, &machineData.thumb, fingerQueueWait);
    int accelStatus = xQueueReceive(IMUQueue, &machineData.angles, IMUQueueWait);
    if ((pinkyStatus == pdTRUE) || (ringStatus == pdTRUE) || (middleStatus == pdTRUE) || (indexStatus == pdTRUE) || (thumbStatus == pdTRUE) || (accelStatus == pdTRUE)) {
      if (xQueueSend(handQueue, &machineData, IMUQueueWait) != pdPASS) {
      }  //updates approx @ 125hz
    } else {
      // Serial.println("No Data to be saved");
    }
    // Serial.println(micros() - start);
    vTaskDelay(pdMS_TO_TICKS(1));
  }
}

// void checkIMUData(void *pvParameters) {
//   for (;;) {
//     if (ACCEL.checkDataReady()) {
//       xTaskNotifyGive(imuTask);
//     } else {
//       vTaskDelay(pdMS_TO_TICKS(10));
//     }
//   }
// }

void accelGyroFunc(void *pvParameters) {
  uint32_t notificationValue;
  int ctr = 0;
  quaternion_t imuData;
  bool ledState = false;
  lastIMUrun = millis();
  for (;;) {

    // ulTaskNotifyTake(pdTRUE, portMAX_DELAY);

    if (millis() - lastIMUrun >= 200) {
      Serial.println("Resetting FIFO");
      ACCEL.resetFIFO();
    } else {
      while (ACCEL.checkDataReady()) {
      }
      imuData = ACCEL.getData();
      if (xQueueSend(IMUQueue, &imuData, pdMS_TO_TICKS(IMUQueueWait)) != pdPASS) {
        missedIMUData++;
      }
      lastIMUrun = millis();
    }

    vTaskDelay(pdMS_TO_TICKS(10));
  }
}

void pinkyFingerFunc(void *pvParameters) {
  for (;;) {
    uint16_t fingerData = pinkyFinger.read();  // Assuming read() returns uint16_t
    if (xQueueSend(pinkyQueue, &fingerData, pdMS_TO_TICKS(fingerQueueWait)) != pdPASS) {
      fingerErrorCheck.pinky++;
    }
    vTaskDelay(pdMS_TO_TICKS(1000 / fingerSamplingRate));
  }
}

void ringFingerFunc(void *pvParameters) {
  for (;;) {
    uint16_t fingerData = ringFinger.read();
    if (xQueueSend(ringQueue, &fingerData, pdMS_TO_TICKS(fingerQueueWait)) != pdPASS) {
      fingerErrorCheck.ring++;
    }
    vTaskDelay(pdMS_TO_TICKS(1000 / fingerSamplingRate));
  }
}

void middleFingerFunc(void *pvParameters) {
  for (;;) {
    uint16_t fingerData = middleFinger.read();
    if (xQueueSend(middleQueue, &fingerData, pdMS_TO_TICKS(fingerQueueWait)) != pdPASS) {
      fingerErrorCheck.middle++;
    }
    vTaskDelay(pdMS_TO_TICKS(1000 / fingerSamplingRate));
  }
}

void indexFingerFunc(void *pvParameters) {
  for (;;) {
    uint16_t fingerData = indexFinger.read();
    if (xQueueSend(indexQueue, &fingerData, pdMS_TO_TICKS(fingerQueueWait)) != pdPASS) {
      fingerErrorCheck.index++;
    }
    vTaskDelay(pdMS_TO_TICKS(1000 / fingerSamplingRate));
  }
}

void thumbFingerFunc(void *pvParameters) {
  for (;;) {
    uint16_t fingerData = thumbFinger.read();
    if (xQueueSend(thumbQueue, &fingerData, pdMS_TO_TICKS(fingerQueueWait)) != pdPASS) {
      fingerErrorCheck.thumb++;
    }
    vTaskDelay(pdMS_TO_TICKS(1000 / fingerSamplingRate));
  }
}

void telemetryCore0(void *pvParameters) {
  Serial.println("Core 0: Telemetry Setup");
  long lastRun = millis();
  int ctr = 0;
  while (1) {
    if (millis() - lastRun >= 1000) {
      core0Tel = ctr;
      ctr = 0;
      lastRun = millis();
    } else {
      //  Serial.println("CORE 0 IDLE");
      ctr++;
      vTaskDelay(pdMS_TO_TICKS(10));
    }
  }
}

void telemetryCore1(void *pvParameters) {
  Serial.println("Core 1: Telemetry Setup");
  long lastRun = millis();
  int ctr = 0;
  while (1) {

    if (millis() - lastRun >= 1000) {
      core1Tel = ctr;
      ctr = 0;
      lastRun = millis();
    } else {
      Serial.println("CORE 1 IDLE");
      ctr++;
      vTaskDelay(pdMS_TO_TICKS(10));
    }
  }
}

void telPrint(void *pvParameters) {
  bool ledState = false;
  for (;;) {
    Serial.print("SYSTEMCORE: ");
    Serial.print(core0Tel);
    Serial.print("  APPCORE: ");
    Serial.print(core1Tel);
    Serial.print("  Free Memory: ");
    Serial.println(esp_get_free_heap_size());
    digitalWrite(bluetoothIndicator, ledState);
    ledState = !ledState;
    vTaskDelay(pdMS_TO_TICKS(500));
    // for (int index = 0; index < 255; index++) {
    //   analogWrite(bluetoothIndicator, index);
    //   vTaskDelay(pdMS_TO_TICKS(2));
    // }
    // for (int index = 255; index > 0; index--) {
    //   analogWrite(bluetoothIndicator, index);
    //   vTaskDelay(pdMS_TO_TICKS(2));
  }
}
