#include <Arduino.h>
#include <nvs_flash.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>


BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// UUID of Nordic UART Service (NUS)
#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"  // UART service UUID
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"


class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    digitalWrite(bluetoothIndicator, HIGH);
  };

  void onDisconnect(BLEServer* pServer) {
    digitalWrite(bluetoothIndicator, LOW);
    deviceConnected = false;
  }
};

class bleInstance {
private:

public:
  bleInstance() {
  }

  void begin(std::string bleName) {
    pinMode(bluetoothIndicator, OUTPUT);
    Serial.println("Starting Bluetooth Low Energy");
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
    pTxCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID_TX,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);

    pTxCharacteristic->addDescriptor(new BLE2902());

    // BLECharacteristic* pRxCharacteristic = pService->createCharacteristic(
    //   CHARACTERISTIC_UUID_RX,
    //   BLECharacteristic::PROPERTY_READ |
    //   BLECharacteristic::PROPERTY_WRITE
    //   BLECharacteristic::PROPERTY_NOTIFY |
    //   //BLECharacteristic::PROPERTY_INDICATE
    // );

    // pRxCharacteristic->setCallbacks(new MyCallbacks());

    // Start the service
    pTxCharacteristic->setValue("Gloves");
    pService->start();

    // Start advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    //pAdvertising->setScanResponse(false);
    pAdvertising->setScanResponse(true);
    //pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
    pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
    pAdvertising->setMinPreferred(0x12);

    Serial.println("Starting Bluetooth Advertising");

    BLEDevice::startAdvertising();
  }

  void write(uint8_t* message) {
    long startTime = micros();
    // uint8_t data[sizeof(float) * length];
    // memcpy(data, message, sizeof(data));

    pTxCharacteristic->setValue(message, sizeof(uint8_t)*8);
    pTxCharacteristic->notify();
    ESP_LOGV("BLE WRITE TIME", "%d micros", (micros() - startTime));
  }

  bool isConnected() {
    return deviceConnected;
  }
};
