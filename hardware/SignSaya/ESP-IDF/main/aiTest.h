/* Copyright 2020 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/


#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/system_setup.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "tensorflow/lite/micro/micro_log.h"
#include "tensorflow/lite/c/common.h"
#include "esp_nn.h"
// #include "espnn"

// #include "main_functions.h"
#include "model.h"
// #include "constants.h"
// #include "output_handler.h"

// Globals, used for compatibility with Arduino-style sketches.
namespace {
const tflite::Model* model = nullptr;
tflite::MicroInterpreter* interpreter = nullptr;
TfLiteTensor* input = nullptr; 
TfLiteTensor* output = nullptr;
// int inference_count = 0;
// EXT_RAM_BSS_ATTR uint8_t[INFERENCE_LENGTH][INFERENCE_FEATURES] arrayWrapper[1];
constexpr int kTensorArenaSize =  478624;
EXT_RAM_BSS_ATTR uint8_t tensor_arena[kTensorArenaSize];
}  // namespace

Result_t inferResult;
class AiModel{
public:

  // The name of this function is important for Arduino compatibility.
  void begin() {
    // esp_nn_init();
    // Map the model into a usable data structure. This doesn't involve any
    // copying or parsing, it's a very lightweight operation.
    // MicroPrintf("ESP Free heap: %d", esp_get_free_heap_size());
    model = tflite::GetModel(signsaya_model);
    if (model->version() != TFLITE_SCHEMA_VERSION) {
      MicroPrintf("Model provided is schema version %d not equal to supported "
                  "version %d.", model->version(), TFLITE_SCHEMA_VERSION);
      return;
    }

    // Pull in only the operation implementations we need.
     EXT_RAM_BSS_ATTR static tflite::MicroMutableOpResolver<8> resolver;

    if (resolver.AddReduceMax() != kTfLiteOk) return;

    if (resolver.AddDequantize() != kTfLiteOk) return;

    if (resolver.AddQuantize() != kTfLiteOk) return;

    if (resolver.AddExpandDims() != kTfLiteOk) return;

    if (resolver.AddSoftmax() != kTfLiteOk) return;

    // if (resolver.AddMean() != kTfLiteOk) return;

    if (resolver.AddConv2D()  != kTfLiteOk) return; 

    if (resolver.AddReshape()  != kTfLiteOk) return;
 
    if (resolver.AddFullyConnected() != kTfLiteOk) return;

    // Build an interpreter to run the model with.
     EXT_RAM_BSS_ATTR static tflite::MicroInterpreter static_interpreter(
        model, resolver, tensor_arena, kTensorArenaSize);
    interpreter = &static_interpreter;

    // Allocate memory from the tensor_arena for the model's tensors.
    TfLiteStatus allocate_status = interpreter->AllocateTensors();
    if (allocate_status != kTfLiteOk) {
      MicroPrintf("AllocateTensors() failed");
      return;
    }

    // Obtain pointers to the model's input and output tensors.
    input = interpreter->input(0);
    output = interpreter->output(0);
  }

  // The name of this function is important for Arduino compatibility.
  Result_t infer(uint8_t inputArray[INFERENCE_LENGTH * INFERENCE_FEATURES]) {
    // arrayWrapper[0] = inputArray; 
    memcpy(input->data.uint8, inputArray, INFERENCE_LENGTH * INFERENCE_FEATURES * sizeof(uint8_t));
  // Copy data to the input tensor
    // input->data.uint8[0] = arrayWrapper;

    // unsigned long startTime = millis();

    // Run inference, and report any error
    TfLiteStatus invoke_status = interpreter->Invoke();
    if (invoke_status != kTfLiteOk) {
      MicroPrintf("Invoke failed on x: %f\n",
                          static_cast<double>(1));
      return inferResult;
    }
    // MicroPrintf("Inference Time: %d", millis() - startTime);

    int maxNumber = 0;
    int maxIndex = 0;
    for (int i = 0; i < output->bytes; ++i) {
      // int index = i;
      // int currentValue = tflite::GetTensorData<uint8_t>(output)[i];
      //   );
      int currentValue = output->data.uint8[i];
      // MicroPrintf("[%d]: %f", i, confidenceLevel);
        if(maxNumber < currentValue) {
          maxNumber = currentValue;
          maxIndex = i;
          }
        
    }

    inferResult.result = maxIndex;
    inferResult.confidence = maxNumber;
    return inferResult;

  }
};