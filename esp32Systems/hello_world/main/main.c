#include <stdio.h>
#include "freertos/FreeRTOS.h"

void app_main(void)
{
  while(1)
  {
    printf("Yo Dawg wat up\n");
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }

}
