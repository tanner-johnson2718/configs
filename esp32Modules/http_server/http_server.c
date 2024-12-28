// TODO Max Number or retries? Or just keep trying??

#include "http_server.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_http_server.h"

#define SSID CONFIG_WIFI_SSID
#define PASSWORD CONFIG_WIFI_PASSWORD
#define PORT CONFIG_HTTP_SERVER_PORT

#define CHECK(x) do { esp_err_t __; if ((__ = x) != ESP_OK) return __; } while (0)

static const char *TAG = "HTTP";
static const char resp[] = "<!DOCTYPE html><html><head><title>Example</title></head><body><p>This is an example of a simple HTML page with one paragraph.</p></body></html>";

// Not to concerned about race conditions here, no need to guard w/ mutex
static uint8_t connected = 0;

static void handler(void* arg, esp_event_base_t base, int32_t id, void* data)
{
  if(base == WIFI_EVENT && 
    ((id == WIFI_EVENT_STA_START) || (id == WIFI_EVENT_STA_DISCONNECTED)))
  {
    ESP_LOGI(TAG, "Attempting to connect to AP = %s", SSID);
    esp_wifi_connect();
  }
  else if(base == IP_EVENT && id == IP_EVENT_STA_GOT_IP)
  {
    ip_event_got_ip_t* event = (ip_event_got_ip_t*) data;
    ESP_LOGI(TAG, "IP Optained = " IPSTR, IP2STR(&event->ip_info.ip));
    connected = 1;
  }
}

static esp_err_t root_get_handler(httpd_req_t *req)
{
  return httpd_resp_send(req, resp, HTTPD_RESP_USE_STRLEN); 
}

httpd_uri_t uri_get = {
  .uri = "/",
  .method = HTTP_GET,
  .handler = root_get_handler,
  .user_ctx = NULL
};

esp_err_t http_server_init(void)
{
  //***************************************************************************
  // Basic WIFI init)
  //   - Init the network interface system and create a wifi sta interface
  //   - Create default event loop for wifi events
  //   - Init and config wifi interface
  //***************************************************************************
  CHECK(esp_netif_init());
  CHECK(esp_event_loop_create_default());

  esp_netif_create_default_wifi_sta();
  wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
  ESP_ERROR_CHECK(esp_wifi_init(&cfg));

  wifi_config_t wifi_config = {
    .sta = {
      .ssid = SSID,
      .password = PASSWORD,
    },
  };
    
  CHECK(esp_wifi_set_mode(WIFI_MODE_STA) );
  CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config) );
  ESP_LOGI(TAG, "Wifi System Inited");

  //***************************************************************************
  // Connect to AP. The wifi subsystem uses events to handle the connection
  // process. Register our event handler above which should handle 3 events:
  //   - WIFI STA start i.e. when we call esp_wifi_start()
  //   - WIFI Disconnect
  //   - IP Optained from DHCP
  //***************************************************************************
  
  // Note we need to register "two" event handlers as we need to handle WIFI
  // and IP events
  CHECK(esp_event_handler_instance_register(
    WIFI_EVENT,
    ESP_EVENT_ANY_ID,
    &handler,
    NULL,
    NULL
  ));
  CHECK(esp_event_handler_instance_register(
    IP_EVENT,
    IP_EVENT_STA_GOT_IP,
    &handler,
    NULL,
    NULL
  ));

  CHECK(esp_wifi_start() );

  // If was going to put in MAX tries mechanism would go here
  while(1)
  {
    if(connected) { break; }
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }

  //***************************************************************************
  // Start the http server
  //***************************************************************************
  httpd_handle_t server = NULL;
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = PORT;
  config.lru_purge_enable = true;
  CHECK(httpd_start(&server, &config));
  CHECK(httpd_register_uri_handler(server, &uri_get));
  ESP_LOGI(TAG, "HTTP Server started");

  return ESP_OK;
}

esp_err_t http_register_cb(char* uri, http_cb_t cb)
{
  return ESP_OK;
}
