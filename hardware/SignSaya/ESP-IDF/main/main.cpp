//#include <Arduino.h>
#include <cstdint>
#include "config.h"
#include "types.h"
#include "bleSetup.h"

#ifdef USE_TFLITE
#include "aiTest.h"
AiModel aiInstance;
#else
#include "tensorflow/lite/micro/micro_log.h"
#endif

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
void trainPrintFunc(void *pvParameters);
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

uint8_t pinkyHZ = 0;
uint8_t ringHZ = 0;
uint8_t middleHZ = 0;
uint8_t indexHZ = 0;
uint8_t thumbHZ = 0;

uint8_t readHZ = 0;
uint8_t writeHZ = 0;

uint8_t core1Tel = 0;
uint8_t core0Tel = 0;


#ifndef USE_ICM
// Interrupt Service Routine (ISR)
void IRAM_ATTR sensorISR() {

  if (isRunning) {
    vTaskNotifyGiveFromISR(imuTask, NULL);
  }
  // Send notification to task (replace with specific notification value as needed)
}
#endif
void bleChecker(void *pvParameters);
#ifdef USE_IMU
void accelGyroSender(void *pvParameters) ;
void accelGyroFunc(void *pvParameters) ;
#endif
#ifdef USE_FINGERS
void fingerSender(void *pvParameters) ;
void pinkyFingerFunc(void *pvParameters);
void ringFingerFunc(void *pvParameters) ;
void middleFingerFunc(void *pvParameters);
void indexFingerFunc(void *pvParameters) ;
void thumbFingerFunc(void *pvParameters) ;
#endif

#ifdef USE_TFLITE
EXT_RAM_BSS_ATTR QueueHandle_t imuInferenceData;
EXT_RAM_BSS_ATTR QueueHandle_t fingerInferenceData;
EXT_RAM_BSS_ATTR QueueHandle_t inferenceDataQueue;
TaskHandle_t inferTask;
TaskHandle_t inferParser;
StaticTask_t inferTaskBuffer;
StaticTask_t parseTaskBuffer;
EXT_RAM_BSS_ATTR static StackType_t inferTaskStack[ INFERENCE_STACK_SIZE ];
EXT_RAM_BSS_ATTR static StackType_t parseTaskStack[ INFERENCE_PARSER_STACK_SIZE ];
void aiInferenceFunc(void *pvParameters);
void aiInferenceParser(void *pvParameters);
bool inferReady = true;
#endif
#ifdef USE_LOGGING
void telemetryCore0(void *pvParameters) ;
void telemetryCore1(void *pvParameters) ;
void telPrint(void *pvParameters) ;
#endif


void setup() {
  pinMode(IMU_INTERRUPT, INPUT);
  pinMode(HAND_PIN, INPUT);
  pinMode(BLUETOOTH_INDICATOR, OUTPUT);

#ifdef USE_FINGERS
  pinkyFinger.begin((digitalRead(HAND_PIN) ? INDEX_PIN : PINKY_PIN));
  ringFinger.begin((digitalRead(HAND_PIN) ? MIDDLE_PIN : RING_PIN));
  middleFinger.begin((digitalRead(HAND_PIN) ? RING_PIN : MIDDLE_PIN));
  indexFinger.begin((digitalRead(HAND_PIN) ? PINKY_PIN : INDEX_PIN));
  thumbFinger.begin((digitalRead(HAND_PIN) ? HAND_PIN : THUMB_PIN));
#endif

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
  int randNumber = random(100000);
  String UBluetoothName = bluetoothName;
  if (digitalRead(HAND_PIN)) {
    UBluetoothName += static_cast<String>("L") + randNumber;
  } else {
    UBluetoothName += static_cast<String>("R") + randNumber;
  }

  ble.begin(UBluetoothName);

#ifdef USE_TFLITE
  aiInstance.begin();
  imuInferenceData = xQueueCreate(INFERENCE_LENGTH, sizeof(quaternion_t));
  fingerInferenceData = xQueueCreate(INFERENCE_LENGTH, sizeof(handData_t));
  inferenceDataQueue = xQueueCreate(1, sizeof(uint8_t) * INFERENCE_LENGTH * INFERENCE_FEATURES);
#endif

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

  xTaskCreate(&bleChecker, "bleBoss", 3072, NULL, 1, NULL);
  #ifdef USE_LOGGING
    xTaskCreatePinnedToCore(&telPrint, "telPrint", 10240, NULL, 1, NULL, SYSTEMCORE);

    xTaskCreatePinnedToCore(&telemetryCore1, "telemetry1", 2048, NULL, tskIDLE_PRIORITY, NULL, 1);
    xTaskCreatePinnedToCore(&telemetryCore0, "telemetry0", 2048, NULL, tskIDLE_PRIORITY, NULL, 0);
  #endif
  #ifdef USE_TFLITE
  inferTask = xTaskCreateStaticPinnedToCore(aiInferenceFunc, "inferFunc", INFERENCE_STACK_SIZE, NULL, SYSTEM_PRIORITY, inferTaskStack, &inferTaskBuffer, SYSTEMCORE);
  inferParser = xTaskCreateStaticPinnedToCore(aiInferenceParser, "aiSupport", INFERENCE_PARSER_STACK_SIZE, NULL, SYSTEM_PRIORITY, parseTaskStack, &parseTaskBuffer, APPCORE);
  #endif
}

void loop() {
  ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
}

/*--------------------------------------------------*/
/*---------------------- Tasks ---------------------*/
/*--------------------------------------------------*/

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
    // MicroPrintf("Running, Lowest heap: %d", esp_get_minimum_free_heap_size());
    if (ble.isConnected() && !isRunning) {
      // start tasks
      if (!initializedTasks) {

        // if not yet intialized, create the tasks
        #ifdef USE_FINGERS
        xTaskCreatePinnedToCore(&pinkyFingerFunc, "pinkyFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &pinkyTask, APPCORE);
        vTaskDelay(5);
        xTaskCreatePinnedToCore(&ringFingerFunc, "ringFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &ringTask, APPCORE);
        vTaskDelay(5);
        xTaskCreatePinnedToCore(&middleFingerFunc, "middleFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &middleTask, APPCORE);
        vTaskDelay(5);
        xTaskCreatePinnedToCore(&indexFingerFunc, "indexFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &indexTask, APPCORE);
        vTaskDelay(5);
        xTaskCreatePinnedToCore(&thumbFingerFunc, "thumbFunc", FINGER_STACK_SIZE, NULL, FINGER_PRIORITY, &thumbTask, APPCORE);
        xTaskCreatePinnedToCore(&fingerSender, "fingerSender", 10240, NULL, SYSTEM_PRIORITY, &parserTask, SYSTEMCORE);
        #endif
        #ifndef USE_TFLITE
        xTaskCreatePinnedToCore(&accelGyroSender, "mpuSender", MPU_STACK_SIZE, NULL, SYSTEM_PRIORITY, &imuSenderTask, SYSTEMCORE);
        #endif
        xTaskCreatePinnedToCore(&accelGyroFunc, "mpuFunc", MPU_STACK_SIZE, NULL, ACCEL_PRIORITY, &imuTask, APPCORE);

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
#ifdef USE_TFLITE
        vTaskResume(inferTask);
#endif
        vTaskResume(pinkyTask);
        vTaskResume(ringTask);
        vTaskResume(middleTask);
        vTaskResume(indexTask);
        vTaskResume(thumbTask);
        vTaskResume(imuTask);
        vTaskResume(parserTask);
        isRunning = true;
#ifdef USE_LOGGING
        Serial.println("Tasks successfuly ran");
#endif
      }


    } else if (!ble.isConnected() && initializedTasks) {
#ifdef USE_TRAIN
      vTaskSuspend(trainPrinter);
#endif
#ifdef USE_TFLITE
      vTaskSuspend(inferTask);
#endif
      vTaskSuspend(pinkyTask);
      vTaskSuspend(ringTask);
      vTaskSuspend(middleTask);
      vTaskSuspend(indexTask);
      vTaskSuspend(thumbTask);
      vTaskSuspend(imuTask);
      vTaskSuspend(parserTask);
      isRunning = false;
      vTaskDelay(pdMS_TO_TICKS(500));
      ble.restartAdvertising();
    }
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
#ifdef USE_TFLITE

void aiInferenceFunc(void *pvParameters){
  uint8_t currentInferInput[INFERENCE_LENGTH*INFERENCE_FEATURES];
  Result_t aiResult;
  for(;;){
    ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
    if(xQueueReceive(inferenceDataQueue, &currentInferInput, portMAX_DELAY) == pdPASS){
      inferReady = false;
      // aiInstance.infer(&currentInferInput);
      aiResult = aiInstance.infer(currentInferInput);
      inferReady = true;
      uint8_t tfPackage[2] = {aiResult.result, aiResult.confidence};
      ble.tfWrite(tfPackage);
    }
    vTaskDelay(1);
  }
}

void aiInferenceParser(void *pvParameters){
  bool ledState = false;
  Inference_t currentEntry;
  currentEntry.pinky = 255;
  currentEntry.ring = 255;
  currentEntry.middle = 255;
  currentEntry.index = 255;
  currentEntry.thumb = 255;
  currentEntry.w = 255;
  currentEntry.x = 255;
  currentEntry.z = 255;
  currentEntry.y = 255;
  Inference_t inferenceArray[INFERENCE_LENGTH] = {currentEntry};
  uint8_t finalInferenceArray[INFERENCE_LENGTH*INFERENCE_FEATURES];
  handData_t inferHandReceive;
  quaternion_t inferIMUReceive;
  uint16_t currentEntryNum = 0;
  // long lastRun = millis();
  // uint16_t hzCheck = 0; 
  for(;;){
      if(xQueueReceive(imuInferenceData, &inferIMUReceive, 0) == pdPASS || xQueueReceive(fingerInferenceData, &inferHandReceive, 0) == pdPASS){

        // SHIFT ARRAY 1 POSITION TO THE LEFT
        for(uint16_t arrayIndex = 0; arrayIndex < INFERENCE_LENGTH - 1 ; arrayIndex++){
          inferenceArray[arrayIndex] = inferenceArray[arrayIndex + 1];
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 0] = inferenceArray[arrayIndex].thumb;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 1] = inferenceArray[arrayIndex].index;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 2] = inferenceArray[arrayIndex].middle;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 3] = inferenceArray[arrayIndex].ring;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 4] = inferenceArray[arrayIndex].pinky;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 5] = inferenceArray[arrayIndex].x;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 6] = inferenceArray[arrayIndex].y;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 7] = inferenceArray[arrayIndex].z;
          finalInferenceArray[arrayIndex * INFERENCE_FEATURES + 8] = inferenceArray[arrayIndex].w;
        }

        // // INSERT NEW ENTRY
        currentEntry.pinky = inferHandReceive.pinky;
        currentEntry.ring = inferHandReceive.ring;
        currentEntry.middle = inferHandReceive.middle;
        currentEntry.index = inferHandReceive.index;
        currentEntry.thumb = inferHandReceive.thumb;
        currentEntry.w = inferIMUReceive.w;
        currentEntry.x = inferIMUReceive.x;
        currentEntry.z = inferIMUReceive.z;
        currentEntry.y = inferIMUReceive.y;

        inferenceArray[INFERENCE_LENGTH-1] = currentEntry;
        
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 0] = currentEntry.thumb;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 1] = currentEntry.index;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 2] = currentEntry.middle;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 3] = currentEntry.ring;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 4] = currentEntry.pinky;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 5] = currentEntry.x;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 6] = currentEntry.y;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 7] = currentEntry.z;
        finalInferenceArray[(INFERENCE_LENGTH-1) * INFERENCE_FEATURES + 8] = currentEntry.w;

        // inferenceArray[INFERENCE_LENGTH-1][0] = inferHandReceive.thumb;
        // inferenceArray[INFERENCE_LENGTH-1][1] = inferHandReceive.index;
        // inferenceArray[INFERENCE_LENGTH-1][2] = inferHandReceive.middle;
        // inferenceArray[INFERENCE_LENGTH-1][3] = inferHandReceive.ring;
        // inferenceArray[INFERENCE_LENGTH-1][4] = inferHandReceive.pinky;
        // inferenceArray[INFERENCE_LENGTH-1][5] = inferIMUReceive.x;
        // inferenceArray[INFERENCE_LENGTH-1][6] = inferIMUReceive.y;
        // inferenceArray[INFERENCE_LENGTH-1][7] = inferIMUReceive.z;
        // inferenceArray[INFERENCE_LENGTH-1][8] = inferIMUReceive.w;
        // increment the window
        currentEntryNum++;
        // MicroPrintf("%d vs %d", currentEntryNum , INFERENCE_WINDOW);

        // hzCheck++;
        // if(millis() - lastRun >= 1000){
        //   MicroPrintf("%dhz", hzCheck);
        //   lastRun = millis();
        //   hzCheck = 0;
        // }

      }
      // Check for new Data
      // check if the entry is still within the window
      if(currentEntryNum >= INFERENCE_WINDOW){
        if(inferReady == true){
          currentEntryNum = 0;
          // MicroPrintf("[%d, %d, %d, %d]", finalInferenceArray[5],finalInferenceArray[6],finalInferenceArray[7],finalInferenceArray[8]);
          xQueueSend(inferenceDataQueue, &finalInferenceArray, 0);
          vTaskDelay(pdMS_TO_TICKS(1));
          xTaskNotifyGive(inferTask);
        }
      }
      vTaskDelay(1);
  }
}
#endif

#ifdef USE_IMU
#ifndef USE_TFLITE
void accelGyroSender(void *pvParameters) {
  quaternion_t imuData;

  for (;;) {
    ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
    if (xQueueReceive(IMUQueue, &imuData, FINGER_QUEUE_WAIT) == pdPASS) {
      uint8_t data[4] = { imuData.x, imuData.y, imuData.z, imuData.w };
      writeHZ++;
      ble.imuWrite(data);
    }
  }
}
#endif
void accelGyroFunc(void *pvParameters) {
  quaternion_t imuData;
  
  for (;;) {
#ifdef USE_ICM

    while (ACCEL.checkDataReady()) {
      imuData = ACCEL.getData();
      #ifndef USE_TFLITE
      xQueueSend(IMUQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));
      xTaskNotifyGive(imuSenderTask);
      #else
      xQueueSend(imuInferenceData, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));
      #endif

#ifdef USE_TRAIN
      xQueueSend(imuTrainQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));
#endif
    }
    vTaskDelay(pdMS_TO_TICKS(1));
#else
    ulTaskGenericNotifyTake(0, pdTRUE, portMAX_DELAY);
    imuData = ACCEL.getData();
    xQueueSend(IMUQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));
    xTaskNotifyGive(imuSenderTask);


#ifdef USE_TRAIN
    xQueueSend(imuTrainQueue, &imuData, pdMS_TO_TICKS(IMU_QUEUE_WAIT));
#endif
#endif
    readHZ++;
  }
}
#endif
#ifdef USE_FINGERS

void fingerSender(void *pvParameters) {
  handData_t fingers;
  // Serial.begin(115200);
  for (;;) {
    // unsigned long start = micros();
    //Receive data from gloves queue
    int pinkyStatus = xQueueReceive(pinkyQueue, &fingers.pinky, FINGER_QUEUE_RECEIVE_WAIT);
    int ringStatus = xQueueReceive(ringQueue, &fingers.ring, FINGER_QUEUE_RECEIVE_WAIT);
    int middleStatus = xQueueReceive(middleQueue, &fingers.middle, FINGER_QUEUE_RECEIVE_WAIT);
    int indexStatus = xQueueReceive(indexQueue, &fingers.index, FINGER_QUEUE_RECEIVE_WAIT);
    int thumbStatus = xQueueReceive(thumbQueue, &fingers.thumb, FINGER_QUEUE_RECEIVE_WAIT);
    if ((pinkyStatus == pdTRUE) || (ringStatus == pdTRUE) || (middleStatus == pdTRUE) || (indexStatus == pdTRUE) || (thumbStatus == pdTRUE)) {
      // Serial.println(sizeof(sendData));
      #ifdef USE_TFLITE
      xQueueSend(fingerInferenceData, &fingers, pdMS_TO_TICKS(FINGER_QUEUE_WAIT));
      #else
      uint8_t sendData[] = { fingers.thumb,
                             fingers.index,
                             fingers.middle,
                             fingers.ring,
                             fingers.pinky };
      ble.fingerWrite(sendData);
      #endif
#ifdef USE_TRAIN
      xQueueSend(fingerTrainQueue, &fingers, pdMS_TO_TICKS(FINGER_QUEUE_WAIT));
#endif
    } else {
    }
    vTaskDelay(pdMS_TO_TICKS(1));
  }
}

void pinkyFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = pinkyFinger.read(); 
    if (xQueueSend(pinkyQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
    }
    pinkyHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void ringFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = ringFinger.read();
    if (xQueueSend(ringQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
    }
    ringHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void middleFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = middleFinger.read();
    if (xQueueSend(middleQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
    }
    middleHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void indexFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = indexFinger.read();
    if (xQueueSend(indexQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
    }
    indexHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}

void thumbFingerFunc(void *pvParameters) {
  for (;;) {
    uint8_t fingerData = thumbFinger.read();
    if (xQueueSend(thumbQueue, &fingerData, pdMS_TO_TICKS(FINGER_QUEUE_WAIT)) != pdPASS) {
    }
    thumbHZ++;
    vTaskDelay(pdMS_TO_TICKS(1000 / FINGER_SAMPLING_RATE));
  }
}
#endif
#ifdef USE_LOGGING
void telemetryCore0(void *pvParameters) {
  while (1) {
    core0Tel++;
    vTaskDelay(pdMS_TO_TICKS(10));
  }
}


void telemetryCore1(void *pvParameters) {
  while (1) {
    core1Tel++;
    vTaskDelay(pdMS_TO_TICKS(10));
  }
}


void telPrint(void *pvParameters) {
  bool ledState = false;
  int lastRun = millis();
  for (;;) {
    MicroPrintf("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", core0Tel, core1Tel, esp_get_free_heap_size(), pinkyHZ,ringHZ,middleHZ,indexHZ,thumbHZ,readHZ,writeHZ);
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
