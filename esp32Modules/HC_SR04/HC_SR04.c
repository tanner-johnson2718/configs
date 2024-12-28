#include "HC_SR04.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_timer.h>
#include <esp32/rom/ets_sys.h>

#define TRIGGER_LOW_DELAY 4
#define TRIGGER_HIGH_DELAY 10
#define PING_TIMEOUT 6000
#define ROUNDTRIP_M 5800.0f
#define ROUNDTRIP_CM 58

#define TRIGGER_PIN CONFIG_TRIGGER_PIN
#define ECHO_PIN CONFIG_ECHO_PIN
#define MAX_DISTANCE CONFIG_MAX_DISTANCE

#define CHECK_ARG(VAL) do { if (!(VAL)) return ESP_ERR_INVALID_ARG; } while (0)
#define CHECK(x) do { esp_err_t __; if ((__ = x) != ESP_OK) return __; } while (0)
#define RETURN_CRITICAL(RES) do { taskEXIT_CRITICAL(&my_spinlock); return RES; } while(0)

static portMUX_TYPE my_spinlock = portMUX_INITIALIZER_UNLOCKED;

esp_err_t hc_sr04_init(void)
{
    CHECK(gpio_set_direction(TRIGGER_PIN, GPIO_MODE_OUTPUT));
    CHECK(gpio_set_direction(ECHO_PIN, GPIO_MODE_INPUT));

    return gpio_set_level(TRIGGER_PIN, 0);
}


esp_err_t ultrasonic_measure_raw(uint32_t max_time_us, uint32_t *time_us)
{
    CHECK_ARG(time_us);

    taskENTER_CRITICAL(&my_spinlock);

    // Ping: Low for 2..4 us, then high 10 us
    CHECK(gpio_set_level(TRIGGER_PIN, 0));
    ets_delay_us(TRIGGER_LOW_DELAY);
    CHECK(gpio_set_level(TRIGGER_PIN, 1));
    ets_delay_us(TRIGGER_HIGH_DELAY);
    CHECK(gpio_set_level(TRIGGER_PIN, 0));

    // Previous ping isn't ended
    if (gpio_get_level(ECHO_PIN))
        RETURN_CRITICAL(ESP_ERR_ULTRASONIC_PING);

    // Wait for echo
    int64_t start = esp_timer_get_time();
    while (!gpio_get_level(ECHO_PIN))
    {
	int64_t tick = esp_timer_get_time();
        if ((tick - start) > PING_TIMEOUT)
            RETURN_CRITICAL(ESP_ERR_ULTRASONIC_PING_TIMEOUT);
    }

    // got echo, measuring
    int64_t echo_start = esp_timer_get_time();
    int64_t time = echo_start;
    while (gpio_get_level(ECHO_PIN))
    {
        time = esp_timer_get_time();
        if ((time - echo_start) > max_time_us)
            RETURN_CRITICAL(ESP_ERR_ULTRASONIC_ECHO_TIMEOUT);
    }
    taskEXIT_CRITICAL(&my_spinlock);

    *time_us = time - echo_start;

    return ESP_OK;
}

esp_err_t hc_sr04_measure(uint32_t *distance)
{
    CHECK_ARG(distance);

    uint32_t time_us;
    CHECK(ultrasonic_measure_raw(MAX_DISTANCE * ROUNDTRIP_CM, &time_us));
    *distance = time_us / ROUNDTRIP_CM;

    return ESP_OK;
}
