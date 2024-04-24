#ifdef USE_ICM

typedef struct {
  uint8_t q0;
  uint8_t q1;
  uint8_t q2;
  uint8_t q3;
} quaternion_t;

#else

typedef struct {
  uint8_t angleX;
  uint8_t angleY;
  uint8_t angleZ;
} angleData_t;

#endif

typedef struct {
  uint8_t pinky;
  uint8_t ring;
  uint8_t middle;
  uint8_t index;
  uint8_t thumb;
} handData_t;


struct fingerError {
  int pinky;
  int ring;
  int middle;
  int index;
  int thumb;
};
