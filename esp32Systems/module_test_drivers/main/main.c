#include <stdio.h>
#include "HC_SR04.h"
#include "http_server.h"
#include "freertos/FreeRTOS.h"
#include "nvs_flash.h"

void hc_sr04_driver();
void http_server_driver();

void app_main(void)
{
  nvs_flash_init();
  http_server_driver();
}

//*****************************************************************************
// Individual Module Drivers
//*****************************************************************************

void hc_sr04_driver()
{
  hc_sr04_init();

  while(1)
  {
    uint32_t d;
    esp_err_t e = hc_sr04_measure(&d);
    if(e)
	d = (uint32_t) -1;
    printf("Measured = %lu\n", d);
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

void http_server_driver()
{
  http_server_init();
  while(1)
  {
    printf("Cool...\n");
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}
