// #define USE_SPI // 11.9kb Smaller than I2C
// #define USE_ICM // 6.9kb bigger than MPU6050
// #define USE_LOGGING // 2.8kb bigger than with no logging

/*
    DO NOT USE PINS IN THIS LIST
    0 = STRAPPING PIN FOR BOOT BUTTON
    3 = STRAPPING PIN FOR JTAG
    15 = Crystal Oscillator
    16 = Crystal Oscillator
    19 = USB_D- ON USB PORT
    20 = USB_D+ ON USB PORT
    43 = TX COM0
    44 = RX COM0
    46 = STRAPPING PIN FOR LOG
    45 = STRAPPING PIN FOR VSPI
*/

// GYRO SETUP
#ifdef USE_SPI
constexpr uint8_t SPI_SDI_PIN = 46;
constexpr uint8_t SPI_SCK_PIN = 3;
constexpr uint8_t SPI_CS_PIN = 21;
constexpr uint8_t SPI_SDO_PIN = 14;
#else
constexpr uint8_t I2C_SDA_PIN = 46;
constexpr uint8_t I2C_SCL_PIN = 3;
#endif
constexpr uint8_t IMU_INTERRUPT = 8;

// FINGER PINS
constexpr uint8_t PINKYPIN = 9;    //9
constexpr uint8_t RINGPIN = 10;    //10
constexpr uint8_t MIDDLEPIN = 11;  //11
constexpr uint8_t INDEXPIN = 12;   //12
constexpr uint8_t THUMBPIN = 13;   //13

constexpr uint8_t HANDPIN = 7;  //14
constexpr uint8_t bluetoothIndicator = 38;


//freeRTOS VARIABLES
constexpr uint8_t fingerQueueLength = 10;
constexpr uint8_t handQueueLength = 15;
constexpr uint8_t IMUQueueLength = 15;
constexpr uint8_t IMUQueueWait = 1;
constexpr uint8_t fingerQueueWait = 1;

constexpr uint16_t fingerStackSize = 1280;
constexpr uint16_t mpuStackSize = 2560;

constexpr uint8_t fingerPriority = 1;
constexpr uint8_t accelPriority = 3;
constexpr uint8_t blePriority = 4;

constexpr uint8_t APPCORE = 1;
constexpr uint8_t SYSTEMCORE = 0;

constexpr uint8_t fingerSamplingRate = 60;  // hz, MAXIMUM ONLY, DOES NOT GUARRANTEE ACTUAL SAMPLING RATE DUE TO freeRTOS
constexpr uint8_t IMUSamplingRate = 200;    // hz, MAXIMUM ONLY, DOES NOT GUARRANTEE ACTUAL SAMPLING RATE DUE TO freeRTOS

// BLUETOOTH VARIABLES
constexpr char bluetoothName[] = "SignSaya";

// OTHER VARIABLES
bool isWireBegun = false;
constexpr int arrayLength = fingerSamplingRate * 1;  //Length of array to be  averaged
uint8_t maxFingerValue = 255;                        //max value of finger output for dataset
