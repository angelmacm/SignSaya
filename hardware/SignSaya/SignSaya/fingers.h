class FingerInstance {
private:
  // For increased precision consider using uint16_t instead to fit entire ADC range
  uint16_t fingerArray[ARRAY_LENGTH];
  // constexpr uint8_t ARRAY_LENGTH = FINGER_SAMPLING_RATE * MA_TIME_SPAN;
  uint16_t minInputValue = 0;
  uint16_t maxInputValue = 4095;
  uint8_t pinNumber;
  bool calibrationStarted = false;
  uint16_t currentValue = 0;

  uint8_t mapData(uint16_t dataToBeMapped) {
    return static_cast<uint8_t>(max(static_cast<uint16_t>(dataToBeMapped - minInputValue), minInputValue) * 255 / (maxInputValue - minInputValue));
  }

  uint16_t rawRead() {
    return analogRead(pinNumber);
  }

  // Modified movingAverage, returns a value in 0 - 255 range
  uint16_t movingAverage() {
    // Variable to save the total value of the array
    uint32_t currentTotal = 0;

    // shift indexes 1 place to the left
    // Save the current index's value to the variable
    for (int arrayIndex = 0; arrayIndex < ARRAY_LENGTH - 1; arrayIndex++) {
      fingerArray[arrayIndex] = fingerArray[arrayIndex + 1];
      currentTotal += fingerArray[arrayIndex];
    }

    // Read new value and save into the array
    uint16_t newRead = rawRead();
    fingerArray[ARRAY_LENGTH - 1] = newRead;
    currentTotal += newRead;
    // Serial.println(ARRAY_LENGTH);
    return (currentTotal / ARRAY_LENGTH);
  }

public:
  FingerInstance() {
  }

  void begin(uint8_t fingerPin) {
    pinMode(fingerPin, INPUT);
    pinNumber = fingerPin;
    Serial.print("Min value: ");
    Serial.print(minInputValue);
    Serial.print("Max value: ");
    Serial.println(maxInputValue);
  }

  // Main read function - handles scaling of moving average result
  uint8_t read() {
    currentValue = movingAverage();
    return mapData(currentValue);
    // return movingAverage();
  }

  void calibrate() {
    if (!calibrationStarted) {
      // prevMaxInputValue = maxInputValue;
      // prevMinInputValue = minInputValue;
      minInputValue = 4095;  // Assuming 12-bit resolution
      maxInputValue = 0;
      calibrationStarted = true;
      // arrayCalibrated = false;
    }

    uint16_t currentSensorValue = analogRead(pinNumber);
    minInputValue = min(minInputValue, currentSensorValue);
    maxInputValue = max(maxInputValue, currentSensorValue);
  }

  void saveCalibration() {
    calibrationStarted = false;
    for (uint8_t arrayIndex = 0; arrayIndex < ARRAY_LENGTH - 1; arrayIndex++) {
      fingerArray[arrayIndex] = 0;
    }

    Serial.print("Min value: ");
    Serial.print(minInputValue);
    Serial.print("Max value: ");
    Serial.println(maxInputValue);
  }
};
