class FingerInstance {
private:
  // For increased precision consider using uint16_t instead to fit entire ADC range
  uint16_t fingerArray[fingerSamplingRate * arrayLength];
  uint16_t minInputValue = 0;
  uint16_t maxInputValue = 4095;
  uint8_t pinNumber;
  bool calibrationStarted = false;
  uint16_t prevMinInputValue = minInputValue;
  uint16_t prevMaxInputValue = maxInputValue;
  bool arrayCalibrated = true;
  uint16_t currentValue = 0;

  // Optimized mapRead - scaling and rounding done later in `read()`
  uint8_t mapRead() {
    return static_cast<uint8_t>((analogRead(pinNumber) - prevMinInputValue) * 255 / (prevMaxInputValue - prevMinInputValue));
  }

  // Modified movingAverage, returns a value in 0 - 255 range
  uint8_t movingAverage(uint8_t newEntry) {
    if (!arrayCalibrated) {
      // Remap array values based on new calibration
      for (int index = arrayLength - 1; index > 0; index--) {
        fingerArray[index] = static_cast<uint16_t>(fingerArray[index] * (maxInputValue - minInputValue)) / (prevMaxInputValue - prevMinInputValue) + minInputValue;
      }
      arrayCalibrated = true;
    }

    uint32_t total = newEntry;  // Use uint32_t to avoid overflow during sum
    for (int index = arrayLength - 1; index > 0; index--) {
      fingerArray[index] = fingerArray[index - 1];
      total += fingerArray[index];
    }
    fingerArray[arrayLength - 1] = newEntry;

    // Divide total *after* adding all values for more precision
    return static_cast<uint8_t>(total / arrayLength);
  }

public:
  FingerInstance(uint8_t fingerPin)
    : pinNumber(fingerPin) {
    pinMode(pinNumber, INPUT);
  }

  // Main read function - handles scaling of moving average result
  uint8_t read() {
    currentValue = mapRead();
    return static_cast<uint8_t>(movingAverage(currentValue) * (maxInputValue - minInputValue) / 255 + minInputValue);
  }


  uint16_t rawRead() {
    return analogRead(pinNumber);
  }

  void calibrate() {
    if (!calibrationStarted) {
      prevMaxInputValue = maxInputValue;
      prevMinInputValue = minInputValue;
      minInputValue = 4095;  // Assuming 12-bit resolution
      maxInputValue = 0;
      calibrationStarted = true;
      arrayCalibrated = false;
    }

    uint16_t currentSensorValue = analogRead(pinNumber);
    minInputValue = min(minInputValue, currentSensorValue);
    maxInputValue = max(maxInputValue, currentSensorValue);
  }
};
