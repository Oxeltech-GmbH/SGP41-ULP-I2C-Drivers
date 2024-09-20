| Supported Targets | ESP32 WROVER | ESP32 WROOM |
| ----------------- | ------------ | ----------- |

# SGP41 I2C ULP Drivers

## Overview
This repository contains I2C drivers for the SGP41 sensor to communicate with the ultra-low power (ULP) co-processor of the ESP32, designed for low-power applications

## Key Components

### I2C Drivers
- Assisting subroutines for SGP41-specific I2C commands.
- Subroutines include write and read operations, handling 16-bit commands and addresses.
- Implements key SGP41 commands, including:
    - `sgp41_execute_conditioning`: Sends conditioning parameters and waits for response.
    - `sgp41_measure_raw_signals`: Initiates raw signal measurement with default parameters (humidity compensation disabled).
    - `sgp41_turn_heater_off`: Powers down the sensor's heater and enters idle mode.


### Low Power Algorithm For Measurements
- Optimizes power consumption by turning off the heater after each measurement.
- Measurements are stored in RTC memory.
The sequence of the measurements includes:
    -	Call `sgp41_measure_raw_signals` to initiate the first measurement and to turn on the heater.
    -	Wait for 170 milliseconds to ensure the heater reaches the desired temperature.
    -	Call `sgp41_measure_raw_signals` to obtain the actual measurement values and store the obtained data in the designated storage.
    -	Call `sgp41_turn_heater_off` to turn off the heater.
    -	Wait for an additional 730 milliseconds to complete the duty cycle and achieve a 1-second total cycle time.
    -	Repeat the entire sequence and once the specified number of measurements is completed, the main processor wakes up 

### Store Data Algorithm
- Subroutine for storing SRAW (Sensor Raw) values and CRC (Cyclic Redundancy Check) results.
- Efficient data organization with dynamic memory location adjustment.

# Credits
This project leveraged the BMP-180 I2C example as a foundation. https://github.com/tomtor/ulp-i2c

