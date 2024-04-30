// #define USE_SPI // 2.8kb Smaller than I2C / 
// #define USE_ICM // 6.9kb bigger than MPU6050
// #define USE_LOGGING // 2.8kb bigger than with no logging
// #define USE_TFLITE
// #define USE_USBOTG
// #define USE_FAT
#define USE_TRAIN

#ifdef USE_TRAIN
#define TRAIN_QUEUE_LENGTH 100
#endif

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
#define SPI_SDI_PIN 46
#define SPI_SCK_PIN 3
#define SPI_CS_PIN 21
#define SPI_SDO_PIN 14
#else
#define I2C_SDA_PIN 46
#define I2C_SCL_PIN 3
#endif
#define IMU_INTERRUPT 8

// FINGER PINS
#define PINKY_PIN 9
#define RING_PIN 10
#define MIDDLE_PIN 11
#define INDEX_PIN 12
#define THUMB_PIN 13
#define HAND_PIN 7

#define BLUETOOTH_INDICATOR RGB_BUILTIN


//freeRTOS VARIABLES
#define FINGER_QUEUE_LENGTH 10
#define HAND_QUEUE_LENGTH 15
#define IMU_QUEUE_LENGTH 15
#define IMU_QUEUE_WAIT 1
#define FINGER_QUEUE_WAIT 1
#define FINGER_QUEUE_RECEIVE_WAIT 0

#define FINGER_STACK_SIZE 1280
#define MPU_STACK_SIZE 2560

#define FINGER_PRIORITY 1
#define ACCEL_PRIORITY 3
#define SYSTEM_PRIORITY 4

#define APPCORE 1
#define SYSTEMCORE 0

#define FINGER_SAMPLING_RATE 60  // hz, MAXIMUM ONLY, DOES NOT GUARRANTEE ACTUAL SAMPLING RATE DUE TO freeRTOS

#define CALIBRATION_TIME 15// time in seconds

// BLUETOOTH VARIABLES
constexpr char bluetoothName[] = "SignSaya";

// OTHER VARIABLES
#define MA_TIME_SPAN 1          // Time in seconds that spans the MA Filter
uint8_t maxFingerValue = 255;  //max value of finger output for dataset
