#ifndef __HC_SR04_H__
#define __HC_SR04_H__

#include <driver/gpio.h>
#include <esp_err.h>

#define ESP_ERR_ULTRASONIC_PING         0x200
#define ESP_ERR_ULTRASONIC_PING_TIMEOUT 0x201
#define ESP_ERR_ULTRASONIC_ECHO_TIMEOUT 0x202

//*****************************************************************************
// hc_sr04_init) Init ranging module
//
// Returns) ESP_OK on success
//*****************************************************************************
esp_err_t hc_sr04_init(void);

//*****************************************************************************
// hr_sr04_measure) Measure distance in centimeters
//
// distance) Out - Distance in centimeters
// //
// Returns ESP_OK on success, otherwise:
//         ESP_ERR_ULTRASONIC_PING         - Previous ping did not complete
//         ESP_ERR_ULTRASONIC_PING_TIMEOUT - Device is not responding
//         ESP_ERR_ULTRASONIC_ECHO_TIMEOUT - Distance too large
//*****************************************************************************
esp_err_t hc_sr04_measure(uint32_t *distance);

#endif
