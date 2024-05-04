idf_component_register(SRCS "main.cpp"
                    INCLUDE_DIRS "."
                    REQUIRES ICM20948 esp_wifi nvs_flash
                    )
