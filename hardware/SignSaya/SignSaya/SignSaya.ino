//#include <Arduino.h>
#include "config.h"
#include "types.h"
#include "bleSetup.h"

#ifdef USE_SPI
#include <SPI.h>
#else
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
#include "Wire.h"
#endif
#endif

#ifdef USE_ICM
#include "icmDMP.h"
#else
#include "mpuDMP.h"
#endif

#include "fingers.h"

accelSensor ACCEL;
bleInstance ble;

FingerInstance pinkyFinger;
FingerInstance ringFinger;
FingerInstance middleFinger;
FingerInstance indexFinger;
FingerInstance thumbFinger;

int packageSent = 0;

fingerError fingerErrorCheck = { 0, 0, 0, 0, 0 };

QueueHandle_t pinkyQueue;
QueueHandle_t ringQueue;
QueueHandle_t middleQueue;
QueueHandle_t indexQueue;
QueueHandle_t thumbQueue;
QueueHandle_t handQueue;
QueueHandle_t IMUQueue;

#ifdef USE_TRAIN
QueueHandle_t fingerTrainQueue;
QueueHandle_t imuTrainQueue;
TaskHandle_t trainPrinter;
#endif

TaskHandle_t imuTask;
TaskHandle_t imuChecker;
TaskHandle_t pinkyTask;
TaskHandle_t ringTask;
TaskHandle_t middleTask;
TaskHandle_t indexTask;
TaskHandle_t thumbTask;
TaskHandle_t imuSenderTask;
TaskHandle_t parserTask;
TaskHandle_t calibrateGlovesTask;

int missedIMUData = 0;

long lastCountdown = 0;
bool isRunning = false;

uint16_t pinkyHZ = 0;
uint16_t ringHZ = 0;
uint16_t middleHZ = 0;
uint16_t indexHZ = 0;
uint16_t thumbHZ = 0;

uint16_t readHZ = 0;
uint16_t writeHZ = 0;

uint8_t core1Tel = 0;
uint8_t core0Tel = 0;

volatile unsigned long lastIMUrun = millis();

#ifndef USE_ICM
// Interrupt Service Routine (ISR)
void IRAM_ATTR sensorISR() {
  BaseType_t xHigherPriorityTaskWoken = pdFALSE;

  if (isRunning) {
    // Serial.print(isRunning);
    // Serial.println("  Interrupt");
    vTaskNotifyGiveFromISR(imuTask, NULL);
  }
  // Send notification to task (replace with specific notification value as needed)
}
#endif

void setup() {
  pinMode(IMU_INTERRUPT, INPUT);
  pinMode(HAND_PIN, INPUT);
  pinMode(BLUETOOTH_INDICATOR, OUTPUT);

  pinkyFinger.begin((digitalRead(HAND_PIN) ? INDEX_PIN : PINKY_PIN));
  ringFinger.begin((digitalRead(HAND_PIN) ? MIDDLE_PIN : RING_PIN));
  middleFinger.begin((digitalRead(HAND_PIN) ? RING_PIN : MIDDLE_PIN));
  indexFinger.begin((digitalRead(HAND_PIN) ? PINKY_PIN : INDEX_PIN));
  thumbFinger.begin((digitalRead(HAND_PIN) ? HAND_PIN : THUMB_PIN));

#ifndef USE_ICM
  attachInterrupt(digitalPinToInterrupt(IMU_INTERRUPT), sensorISR, RISING);
#endif
#ifdef USE_LOGGING
  Serial.begin(115200);

  while (!Serial) {
    delay(10);
  };
  vTaskDelay(500 * portTICK_PERIOD_MS);
#endif
  String handSide;
  int randNumber = random(100000);
  String UBluetoothName = bluetoothName;
  if (digitalRead(HAND_PIN)) {
    handSide = "L";
  } else {
    handSide = "R";
  }

  UBluetoothName += handSide + randNumber;
  char uBlCharArray[UBluetoothName.length() + 1];
  UBluetoothName.toCharArray(uBlCharArray, UBluetoothName.length() + 1);
  ble.begin(uBlCharArray);

#ifdef USE_SPI
  ACCEL.begin(SPI_SDI_PIN, SPI_SCK_PIN, SPI_SDO_PIN, SPI_CS_PIN);
#else
  ACCEL.begin(I2C_SDA_PIN, I2C_SCL_PIN);
#endif

  pinkyQueue = xQueueCreate(FINGER_QUEUE_LENGTH, sizeof(uint8_t));
  ringQueue = xQueueCreate(FINGER_QUEUE_LENGTH, sizeof(uint8_t));
  middleQueue = xQueueCreate(FINGER_QUEUE_LENGTH, sizeof(uint8_t));
  indexQueue = xQueueCreate(FINGER_QUEUE_LENGTH, sizeof(uint8_t));
  thumbQueue = xQueueCreate(FINGER_QUEUE_LENGTH, sizeof(uint8_t));

  handQueue = xQueueCreate(HAND_QUEUE_LENGTH, sizeof(handData_t));
  IMUQueue = xQueueCreate(IMU_QUEUE_LENGTH, sizeof(quaternion_t));

#ifdef USE_TRAIN
  fingerTrainQueue = xQueueCreate(TRAIN_QUEUE_LENGTH, sizeof(handData_t));
  imuTrainQueue = xQueueCreate(TRAIN_QUEUE_LENGTH, sizeof(quaternion_t));
#endif

  xTaskCreate(&bleChecker, "bleBoss", 10240, NULL, 1, NULL);
#ifdef USE_LOGGING
  xTaskCreatePinnedToCore(&telPrint, "telPrint", 10240, NULL, 1, NULL, SYSTEMCORE);

  xTaskCreatePinnedToCore(&telemetryCore1, "telemetry1", 2048, NULL, tskIDLE_PRIORITY, NULL, 1);
  xTaskCreatePinnedToCore(&telemetryCore0, "telemetry0", 2048, NULL, tskIDLE_PRIORITY, NULL, 0);
#endif
}

void loop() {
  ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
}

/*--------------------------------------------------*/
/*---------------------- Tasks ---------------------*/
/*--------------------------------------------------*/

void calibrateGloves(void *pvParameters) {
  for (;;) {
    ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
#ifdef USE_LOGGING
    Serial.println("Gloves calibration started...");
#endif

    unsigned long lastRun = millis();
    while (millis() - lastRun <= CALIBRATION_TIME * 1000) {
      pinkyFinger.calibrate();
      ringFinger.calibrate();
      middleFinger.calibrate();
      indexFinger.calibrate();
      thumbFinger.calibrate();
      #ifdef USE_LOGGING
      Serial.print("Calibrating... ");
      Serial.print(millis() - lastRun);
      Serial.print("/");
      Serial.println(CALIBRATION_TIME * 1000);
      #endif
      vTaskDelay(pdMS_TO_TICKS(16));
    }
    ACCEL.init();
    isRunning = false;
    pinkyFinger.saveCalibration();
    ringFinger.saveCalibration();
    middleFinger.saveCalibration();
    indexFinger.saveCalibration();
    thumbFinger.saveCalibration();
    vTaskDelay(pdMS_TO_TICKS(16));
#ifdef USE_LOGGING
    Serial.println("Gloves calibration done.");
#endif
  }
}

#ifdef USE_TRAIN
void trainPrintFunc(void *pvParameters) {
  Serial.begin(115200);
  handData_t fingerData;
  quaternion_t imuData;
  char str[37];
  for (;;) {
    int fingerReady = xQueueReceive(fingerTrainQueue, &fingerData, 0);
    int imuReady = xQueueReceive(imuTrainQueue, &imuData, 0);
    if (fingerReady == pdPASS || imuReady == pdPASS) {
      #ifdef USE_LOGGING
      sprintf(
        str,
        "%d,%d,%d,%d,%d,%d,%d,%d,%d",
        fingerData.thumb,
        fingerData.index,
        fingerData.middle,
        fingerData.ring,
        fingerData.pinky,
        imuData.x,
        imuData.y,
        imuData.z,
        imuData.w);
      Serial.println(str);
      #endif
    }
    vTaskDelay(pdMS_TO_TICKS(1));
  }
}
#endif

void bleChecker(void *pvParameters) {

  bool initializedTasks = false;
#ifdef USE_LOGGING
  Serial.println("No devices connected... waiting to connect to run tasks");
#endif
  for (;;) {
    if (ble.isConnected() && !isRunning) {
      // start tasks
      if (!initializedTasks) {

        // if not yet intialized, create the tasks

        xTaskCreatePinnedToCore(&pinkyFingerFunc, "pinkyFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &pinkyTask, APPCORE);
        xTaskCreatePinnedToCore(&ringFingerFunc, "ringFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &ringTask, APPCORE);
        xTaskCreatePinnedToCore(&middleFingerFunc, "middleFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &middleTask, APPCORE);
        xTaskCreatePinnedToCore(&indexFingerFunc, "indexFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &indexTask, APPCORE);
        xTaskCreatePinnedToCore(&thumbFingerFunc, "thumbFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &thumbTask, APPCORE);
        xTaskCreatePinnedToCore(&accelGyroFunc, "mpuFunc", MPU_STACK_SIZE, NULL, ACCEL_PRIORITY, &imuTask, APPCORE);

        xTaskCreatePinnedToCore(&accelGyroSender, "mpuSender", MPU_STACK_SIZE, NULL, SYSTEM_PRIORITY, &imuSenderTask, SYSTEMCORE);
        xTaskCreatePinnedToCore(&fingerSender, "fingerSender", 10240, NULL, SYSTEM_PRIORITY, &parserTask, SYSTEMCORE);
        xTaskCreatePinnedToCore(&calibrateGloves, "calibrateGlove", 10240, NULL, SYSTEM_PRIORITY, &calibrateGlovesTask, SYSTEMCORE);

#ifdef USE_TRAIN
        xTaskCreatePinnedToCore(&trainPrintFunc, "trainPrinterTaskk", 10240, NULL, SYSTEM_PRIORITY, &trainPrinter, SYSTEMCORE);
#endif

        initializedTasks = true;
        isRunning = true;
#ifdef USE_LOGGING
        Serial.println("Tasks successfuly ran");
#endif

      } else {
// if it is already intialized, resume the tasks from suspension
#ifdef USE_ICM
        ACCEL.resetFIFO();
#endif
#ifdef USE_TRAIN
        vTaskResume(trainPrinter);
#endif
        vTaskResume(pinkyTask);
        vTaskResume(ringTask);
        vTaskResume(middleTask);
        vTaskResume(indexTask);
        vTaskResume(thumbTask);
        vTaskResume(imuTask);
        vTaskResume(parserTask);
        // vTaskResume(senderTask);
        isRunning = true;
#ifdef USE_LOGGING
        Serial.println("Tasks successfuly ran");
#endif
      }


    } else if (!ble.isConnected() && initializedTasks) {
#ifdef USE_TRAIN
      vTaskSuspend(trainPrinter);
#endif
      vTaskSuspend(pinkyTask);
      vTaskSuspend(ringTask);
      vTaskSuspend(middleTask);
      vTaskSuspend(indexTask);
      vTaskSuspend(thumbTask);
      vTaskSuspend(imuTask);
      vTaskSuspend(parserTask);
      // vTaskSuspend(senderTask);
      isRunning = false;
      ble.restartAdvertising();
    }
    if (ble.isCalibrateRequest()) {
#ifdef USE_LOGGING
      Serial.println("Calibration request detected...");
#endif
#ifdef USE_TRAIN
      vTaskSuspend(trainPrinter);
#endif
      ble.doneCalibrate();
      xTaskNotifyGive(calibrateGlovesTask);
      vTaskSuspend(pinkyTask);
      vTaskSuspend(ringTask);
      vTaskSuspend(middleTask);
      vTaskSuspend(indexTask);
      vTaskSuspend(thumbTask);
      vTaskSuspend(imuTask);
      vTaskSuspend(parserTask);
    }
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

void fingerSender(void *pvParameters) {
  handData_t fingers;
  Serial.begin(115200);
  for (;;) {
    // unsigned long start = micros();
    //Receive data from gloves queue
    int pinkyStatus = xQueueReceive(pinkyQueue, &fingers.pinky, FINGER_QUEUE_RECEIVE_WAIT);
    int ringStatus = xQueueReceive(ringQueue, &fingers.ring, FINGER_QUEUE_RECEIVE_WAIT);
    int middleStatus = xQueueReceive(middleQueue, &fingers.middle, FINGER_QUEUE_RECEIVE_WAIT);
    int indexStatus = xQueueReceive(indexQueue, &fingers.index, FINGER_QUEUE_RECEIVE_WAIT);
    int thumbStatus = xQueueReceive(thumbQueue, &fingers.thumb, FINGER_QUEUE_RECEIVE_WAIT);
    if ((pinkyStatus == pdTRUE) || (ringStatus == pdTRUE) || (middleStatus == pdTRUE) || (indexStatus == pdTRUE) || (thumbStatus == pdTRUE)) {
      uint8_t sendData[] = { fingers.pinky,
                             fingers.ring,
                             fingers.middle,
                             fingers.index,
                             fingers.thumb };
      // Serial.println(sizeof(sendData));
      ble.fingerWrite(sendData);
#ifdef USE_TRAIN
      xQueueSend(fingerTrainQueue, &fingers, pdMS_TO_TICKS(FINGER_QUEUE_WAIT));
#endif
    } else {
      // Serial.println("No Data to be saved");
    }
    // Serial.println(micros() - start);
    vTaskDelay(pdMS_TO_TICKS(1));
  }
}

void accelGyroSender(void *pvParameters) {
  quaternion_t imuData;
  uint32_t notificationValue;

  for (;;) {
    ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
    // Serial.println("Sending IMU Data...");
    if (xQueueReceive(IMUQueue, &imuData, FINGER_QUEUE_WAIT) == pdPASS) {
      uint8_t data[4] = { imuData.x, imuData.y, imuData.z, imuData.w };
      // Serial.println(sizeof(data));
      writeHZ++;
      ble.imuWrite(data);
    }
  }
}

void accelGyroFunc(void *pvParameters) {

  uint32_t notificationValue;
  quaternion_t imuData;

  bool ledState = false;
  lastIMUrun = millis();
  for (;;) {
    // Serial.println("MPU SENDER");
#ifdef USE_ICM

    if (millis() - lastIMUrun >= 200) {
#ifdef USE_LOGGING
      Serial.println("Resetting FIFO");
#endif
      ACCEL.resetFIFO();
      lastIMUrun = millis();
    } else {
      while (ACCEL.checkDataReady()) {
      }
      imuData = ACCEL.getData();
      xQueueSend(IMUQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));

      lastIMUrun = millis();
    }

    vTaskDelay(pdMS_TO_TICKS(10));

#else
    ulTaskGenericNotifyTake(0, pdTRUE, portMAX_DELAY);
    imuData = ACCEL.getData();
    xQueueSend(IMUQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));

#endif
    readHZ++;
#ifdef USE_TRAIN
    xQueueSend(imuTrainQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));
#endif
    xTaskNotifyGive(imuSenderTask);
  }
}

void pinkyFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = pinkyFinger.read();  // Assuming read() returns uint16_t
    if (xQueueSend(pinkyQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
      fingerErrorCheck.pinky++;
    }
    pinkyHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void ringFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = ringFinger.read();
    if (xQueueSend(ringQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
      fingerErrorCheck.ring++;
    }
    ringHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void middleFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = middleFinger.read();
    if (xQueueSend(middleQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
      fingerErrorCheck.middle++;
    }
    middleHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void indexFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = indexFinger.read();
    if (xQueueSend(indexQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
      fingerErrorCheck.index++;
    }
    indexHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void thumbFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = thumbFinger.read();
    if (xQueueSend(thumbQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
      fingerErrorCheck.thumb++;
    }
    thumbHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}
#ifdef USE_LOGGING
void telemetryCore0(void *pvParameters) {
  Serial.println("Core 0: Telemetry Setup");
  while (1) {
    //  Serial.println("CORE 0 IDLE");
    core0Tel++;
    vTaskDelay(pdMS_TO_TICKS(10));
  }
}


void telemetryCore1(void *pvParameters) {
  Serial.println("Core 1: Telemetry Setup");
  while (1) {
    // Serial.println("CORE 1 IDLE");
    core1Tel++;
    vTaskDelay(pdMS_TO_TICKS(10));
  }
}


void telPrint(void *pvParameters) {
  bool ledState = false;
  int lastRun = millis();
  for (;;) {
    Serial.print(core0Tel);
    Serial.print(",");
    Serial.print(core1Tel);
    Serial.print(",");
    Serial.print(esp_get_free_heap_size());
    Serial.print(",");
    Serial.print(pinkyHZ);
    Serial.print(",");
    Serial.print(ringHZ);
    Serial.print(",");
    Serial.print(middleHZ);
    Serial.print(",");
    Serial.print(indexHZ);
    Serial.print(",");
    Serial.print(thumbHZ);
    Serial.print(",");
    Serial.print(readHZ);
    Serial.print(",");
    Serial.println(writeHZ);
    // digitalWrite(BLUETOOTH_INDICATOR, ledState);

    ledState = !ledState;
    core0Tel = 0;
    core1Tel = 0;
    pinkyHZ = 0;
    ringHZ = 0;
    middleHZ = 0;
    indexHZ = 0;
    thumbHZ = 0;
    readHZ = 0;
    writeHZ = 0;

    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
#endif  // USE_LOGGING
