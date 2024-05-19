idf_component_register(SRCS "main.cpp"
                    INCLUDE_DIRS "."
                    REQUIRES ICM20948 esp_wifi nvs_flash MPU6050 I2Cdev esp-nn
                    )

                    # set(_DISABLE_WARNINGS
                    
                    # maybe-uninitialized -Wno-error=maybe-uninitialized Wmissing-field-initializers Warray-bounds)