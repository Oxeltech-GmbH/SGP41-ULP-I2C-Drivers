/* ULP I2C bit bang BMP-180 Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include <stdio.h>
#include <time.h>
#include <math.h>
#include "esp_sleep.h"
#include "nvs.h"
#include "nvs_flash.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/sens_reg.h"
#include "soc/soc.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp32/ulp.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "sdkconfig.h"
#include "sensirion_gas_index_algorithm.h"

#include "ulp_main.h"


uint16_t DEFAULT_COMPENSATION_RH = 0x8000;  // in ticks as defined by SGP41
uint16_t DEFAULT_COMPENSATION_T = 0x6666;   // in ticks as defined by SGP41

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");


const gpio_num_t gpio_led = GPIO_NUM_2;
const gpio_num_t gpio_scl = GPIO_NUM_32;
const gpio_num_t gpio_sda = GPIO_NUM_33;
//const gpio_num_t gpio_builtin = GPIO_NUM_22;




static void init_ulp_program()
{
    rtc_gpio_init(gpio_led);
    rtc_gpio_set_direction(gpio_led, RTC_GPIO_MODE_OUTPUT_ONLY);

    rtc_gpio_init(gpio_scl);
    rtc_gpio_set_direction(gpio_scl, RTC_GPIO_MODE_INPUT_ONLY);
    rtc_gpio_init(gpio_sda);
    rtc_gpio_set_direction(gpio_sda, RTC_GPIO_MODE_INPUT_ONLY);

    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    /* Set ULP wake up period to T = 1000ms
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    REG_SET_FIELD(SENS_ULP_CP_SLEEP_CYC0_REG, SENS_SLEEP_CYCLES_S0, 150000);

}


// Calculate CRC for 2 bytes of data using the CRC-8 algorithm from the datasheet
uint8_t calculate_crc(uint8_t data[2]) {
    uint8_t crc = 0xFF;
    for (int i = 0; i < 2; i++) {
        crc ^= data[i];
        for (uint8_t bit = 8; bit > 0; --bit) {
            if (crc & 0x80) {
                crc = (crc << 1) ^ 0x31u;
            } else {
                crc = (crc << 1);
            }
        }
    }
    return crc;
}

static void print_status()
{   

    uint16_t compensation_rh = DEFAULT_COMPENSATION_RH;
    uint16_t compensation_t = DEFAULT_COMPENSATION_T;
    int32_t voc_index_value = 0;
    int32_t nox_index_value = 0;
    float sampling_interval = 1.f;

    // initialize gas index parameters
    GasIndexAlgorithmParams voc_params;
    GasIndexAlgorithm_init_with_sampling_interval(&voc_params, GasIndexAlgorithm_ALGORITHM_TYPE_VOC, sampling_interval);
    GasIndexAlgorithmParams nox_params;
    GasIndexAlgorithm_init_with_sampling_interval(&nox_params, GasIndexAlgorithm_ALGORITHM_TYPE_NOX, sampling_interval);


    uint32_t* VOC_array = (uint32_t*)&ulp_VOC_array;
    uint32_t* NOX_array = (uint32_t*)&ulp_NOX_array;
    uint32_t* VCRC_array = (uint32_t*)&ulp_VCRC_array;
    uint32_t* NCRC_array = (uint32_t*)&ulp_NCRC_array;

  //  printf("counter value: %ld\n", ulp_counter & UINT16_MAX);

    for (int i = 0; i < 150; ++i) {
        printf("\nReading number: %.2d\n", i+1);
        //vTaskDelay(1000 / 10);
        vTaskDelay(pdMS_TO_TICKS(1000));
        // Read VOC and its CRC
        uint16_t voc_value = VOC_array[i] & UINT16_MAX;
        uint16_t voc_crc = VCRC_array[i] & UINT16_MAX;

        // Read NOx and its CRC
        uint16_t nox_value = NOX_array[i] & UINT16_MAX;
        uint16_t nox_crc = NCRC_array[i] & UINT16_MAX;

            GasIndexAlgorithm_process(&voc_params, voc_value, &voc_index_value);
            GasIndexAlgorithm_process(&nox_params, nox_value, &nox_index_value);
            printf("VOC Raw: %i\tVOC Index: %i\n", voc_value, voc_index_value);
            printf("NOx Raw: %i\tNOx Index: %i\n", nox_value, nox_index_value);
    }
}

void app_main()
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        printf("Not ULP wakeup, initializing ULP\n");
        init_ulp_program();
    } else {

    	printf("ULP wakeup, printing status\n");
        print_status();
    }

    printf("Entering deep sleep\n\n");

    ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );

    /* Start the program */
    esp_err_t err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);

    esp_deep_sleep_start();
}
