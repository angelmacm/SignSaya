#include <Arduino.h>
#include <nvs_flash.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>


BLEServer* pServer = NULL;
BLECharacteristic* fingerLane;
BLECharacteristic* imuLane;
BLECharacteristic* requestLane;
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool calibrationRequest = false;

// UUID of Nordic UART Service (NUS)
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"  // UART service UUID
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define FINGER_LANE "806E5CE2-866C-41C6-8C40-F4D5739A6616"
#define IMU_LANE "58C7A24D-738A-426D-A849-D3EFDF4C16BB"
#define REQUEST_LANE "29EBE3AC-9A42-486F-BA0B-AD59FE1B5722"


class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();

    if (value.length() > 0) {
      // if (value == "calibrate") {
        calibrationRequest = true;
      // }
    }
  }
};

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    digitalWrite(BLUETOOTH_INDICATOR, HIGH);
  };

  void onDisconnect(BLEServer* pServer) {
    digitalWrite(BLUETOOTH_INDICATOR, LOW);
    deviceConnected = false;
  }
};

class bleInstance {
private:

public:
  bleInstance() {
  }

  void begin(std::string bleName) {
    pinMode(BLUETOOTH_INDICATOR, OUTPUT);
#ifdef USE_LOGGING
    Serial.println("Starting Bluetooth Low Energy");
#endif
    // Initialize NVS
    esp_err_t ret = nvs_flash_init();
    if ((ret == ESP_ERR_NVS_NO_FREE_PAGES) || (ret == ESP_ERR_NVS_NEW_VERSION_FOUND)) {
      ESP_ERROR_CHECK(nvs_flash_erase());
      ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    //BLEDevice::setMTU(64);
    BLEDevice::init(bleName);

    // Create the BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // Create the BLE Service
    BLEService* pService = pServer->createService(SERVICE_UUID);

    // Create a BLE Characteristic
    fingerLane = pService->createCharacteristic(
      FINGER_LANE,
      BLECharacteristic::PROPERTY_NOTIFY);

    imuLane = pService->createCharacteristic(
      IMU_LANE,
      BLECharacteristic::PROPERTY_NOTIFY);

    requestLane = pService->createCharacteristic(
      REQUEST_LANE,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);

    fingerLane->addDescriptor(new BLE2902());
    imuLane->addDescriptor(new BLE2902());
    // requestLane->addDescriptor(new BLE2902());

    // BLECharacteristic* pRxCharacteristic = pService->createCharacteristic(
    //   CHARACTERISTIC_UUID_RX,
    //   BLECharacteristic::PROPERTY_READ |
    //   BLECharacteristic::PROPERTY_WRITE
    //   BLECharacteristic::PROPERTY_NOTIFY |
    //   //BLECharacteristic::PROPERTY_INDICATE
    // );

    requestLane->setCallbacks(new MyCallbacks());

    // Start the service
    // fingerLane->setValue("Fingers");
    // imuLane->setValue("IMU");
    pService->start();

    // Start advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    //pAdvertising->setScanResponse(false);
    pAdvertising->setScanResponse(true);
    //pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
    pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
    pAdvertising->setMinPreferred(0x12);
#ifdef USE_LOGGING
    Serial.println("Starting Bluetooth Advertising");
#endif
    BLEDevice::startAdvertising();
  }

  void fingerWrite(uint8_t* message) {
    // long startTime = micros();

    fingerLane->setValue(message, 5);
    fingerLane->notify();
  }

  void imuWrite(uint8_t* imuData) {
    imuLane->setValue(imuData, sizeof(imuData));
    imuLane->notify();
  }

  bool isConnected() {
    return deviceConnected;
  }

  void restartAdvertising() {
    pServer->startAdvertising();  // restart advertising
  }

  bool isCalibrateRequest() {
    return calibrationRequest;
  }
  void doneCalibrate() {
    calibrationRequest = false;
  }
};
