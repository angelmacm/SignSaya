#pragma once

typedef struct {
  uint8_t w;
  uint8_t x;
  uint8_t y;
  uint8_t z;
} quaternion_t;

typedef struct {
  uint8_t pinky;
  uint8_t ring;
  uint8_t middle;
  uint8_t index;
  uint8_t thumb;
} handData_t;


typedef struct{ 
  uint8_t pinky;
  uint8_t ring;
  uint8_t middle;
  uint8_t index;
  uint8_t thumb;
  uint8_t w;
  uint8_t x;
  uint8_t y;
  uint8_t z;
} Inference_t;

typedef struct{
  uint8_t result;
  uint8_t confidence;
} Result_t;