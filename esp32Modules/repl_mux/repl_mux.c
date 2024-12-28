#include <stdio.h>
#include <string.h>

#include "esp_system.h"
#include "esp_log.h"
#include "esp_vfs_dev.h"

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "linenoise/linenoise.h"
#include "driver/uart.h"

#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"
#include <lwip/netdb.h>

#include "repl_mux.h"

#define TTL CONFIG_REPL_MUX_WAIT_MS / portTICK_PERIOD_MS
#define UART_Q 0
#define NET_Q 1

struct repl_mux_message
{
    char log_msg[CONFIG_REPL_MUX_MAX_LOG_MSG];
} typedef repl_mux_message_t;

static const char* TAG = "REPL MUX";

static uint8_t queue_active[CONFIG_REPL_MUX_N_QUEUES] = {0};
static QueueHandle_t qs[CONFIG_REPL_MUX_N_QUEUES];
static QueueHandle_t client_connected_notifier;
static uint8_t client_discon = 1;

static uint8_t num_cmds = 0;
static cmd_t cmd_list[CONFIG_REPL_MUX_MAX_NUM_CMD];

//*****************************************************************************
// Private command table funcs
//*****************************************************************************

static int build_argv(char* input, char** argv)
{
    argv[0] = input;

    uint8_t i;
    int argc = 0;
    char* start = input;
    for(i = 0; i < CONFIG_REPL_MUX_MAX_LOG_MSG; ++i)
    {
        if(input[i] == 0)
        {
            argv[argc] = start;
            ++argc;
            return argc;
        }

        if(input[i] == ' ')
        {
            
            while(input[i] == ' ') 
            {
                input[i] = 0;
                ++i;
            }

            argv[argc] = start;
            ++argc;
            start = input+i;

            if(input[i] == 0)
            {
                return argc;
            }

            if(argc == CONFIG_REPL_MUX_MAX_CMD_ARG)
            {
                ESP_LOGE(TAG, "Input contained max argv, possibly cutting arg list short");
                return argc;
            }
        }

    }

    ESP_LOGE(TAG, "WARNING Input to buildargv contained no NULL char");
    return argc;
}

static int16_t lookup_cmd(char* name)
{
    uint8_t i;
    for(i = 0; i < num_cmds; ++i)
    {
        if(strcmp(name, cmd_list[i].name) == 0)
        {
            return i;
        }
    }

    return -1;
}

static int run_cmd(uint8_t index, int argc, char** argv)
{
    if(index >= num_cmds)
    {
        ESP_LOGE(TAG, "Tried to run command with outof bounds index");
        return -1;
    }

    return cmd_list[index].func(argc, argv);
}

static void run(char* input)
{
    char* argv[CONFIG_REPL_MUX_MAX_CMD_ARG];

    int argc = build_argv(input, argv);

    int16_t index = lookup_cmd(argv[0]);
    if(index < 0)
    {
        ESP_LOGE(TAG, "%s not found", argv[0]);
        return;
    }

    int ret = run_cmd(index, argc, argv);
    if(ret < 0)
    {
        ESP_LOGE(TAG, "%s returned non zero value", argv[0]);
    }

}

static int do_help(int argc, char** argv)
{
    uint8_t i;
    for(i = 0; i < num_cmds; ++i)
    {
        esp_log_write(ESP_LOG_INFO, "", "%s\n",cmd_list[i].name);
        esp_log_write(ESP_LOG_INFO, "", "   %s\n", cmd_list[i].desc);
        esp_log_write(ESP_LOG_INFO, "", "\n");
    }

    return 0;
}

//*****************************************************************************
// UART Q Consumer 
//*****************************************************************************

static void uart_consumer(void* args)
{
    repl_mux_message_t msg;

    queue_active[UART_Q] = 1;
    while(1)
    {
        while(xQueueReceive(qs[UART_Q], &msg, 100 / portTICK_PERIOD_MS))
        {
            printf(msg.log_msg);
        }

    }
}

static void uart_producer(void* args)
{
    const uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .source_clk = UART_SCLK_REF_TICK,
    };

    int channel = 0;

    uart_param_config(channel, &uart_config);
    uart_driver_install(channel, 256, 0, 0, NULL, 0);
    esp_vfs_dev_uart_use_driver(channel);

    linenoiseSetMaxLineLen(CONFIG_REPL_MUX_MAX_LOG_MSG);
    linenoiseSetDumbMode(1);
    setvbuf(stdin, NULL, _IONBF, 0);

    ESP_LOGI(TAG, "UART Input handelr thread launched");

    while(1)
    {
        char* line = linenoise("> ");
        if(line != NULL && strlen(line) > 0)
        {
            run(line);
            free(line);
        }
        vTaskDelay(10 / portTICK_PERIOD_MS);
    }
}


//*****************************************************************************
// Net Q Consumer
//*****************************************************************************

// Returns listneing soket
static int create_listening_socket()
{
    int listen_sock = -1;
    struct sockaddr_storage dest_addr;
    struct sockaddr_in *dest_addr_ip4;

    listen_sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    if(listen_sock < 0)
    {
        ESP_LOGE(TAG, "Failed to open listening socket");
        return -1;
    }

    dest_addr_ip4 = (struct sockaddr_in *)&dest_addr;
    dest_addr_ip4->sin_addr.s_addr = inet_addr(CONFIG_REPL_MUX_IP);
    dest_addr_ip4->sin_family = AF_INET;
    dest_addr_ip4->sin_port = htons(CONFIG_REPL_MUX_PORT);
    int err = bind(listen_sock, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
    err |= listen(listen_sock, 1);
    
    if(err)
    {
        ESP_LOGE(TAG, "Failed to bind listening socket");
        return -1;;
    }

    ESP_LOGI(TAG, "Listening socket bound to %s:%d", CONFIG_REPL_MUX_IP, CONFIG_REPL_MUX_PORT);
    return listen_sock;
}

static int accept_client(int listen_sock)
{
    int client_socket;
    struct sockaddr_in source_addr;
    socklen_t addr_len = sizeof(source_addr);
    char ip_addr[16];

    client_socket = accept(listen_sock, (struct sockaddr *)&source_addr, &addr_len);
    if (client_socket < 0)
    {
        ESP_LOGE(TAG, "Unable to accept connection: %s", strerror(errno));
        return -1;
    }
    inet_ntoa_r(((struct sockaddr_in *)&source_addr)->sin_addr, ip_addr, 16);
    ESP_LOGI(TAG, "Client Connected %s - Starting Session", ip_addr);

    return client_socket;
}

static void net_consumer(void* args)
{
    repl_mux_message_t msg;
    int listen_sock = -1;
    int client_socket = -1;

    // This is considered early init task. If it fails blow everything up
    listen_sock = create_listening_socket();
    assert(listen_sock > -1);
    
    while(1)
    {
        client_socket = accept_client(listen_sock);
        if(client_socket == -1)
        {
            vTaskDelay(1000 / portTICK_PERIOD_MS);
            continue;
        }

        queue_active[NET_Q] = 1;
        
        client_discon = 0;
        if(!xQueueSend(client_connected_notifier, &client_socket, 0))
        {   
            ESP_LOGE(TAG, "Failed to push on client_connected_notifier");
        }

        while(!client_discon)
        {
            while(xQueueReceive(qs[NET_Q], &msg, 100 / portTICK_PERIOD_MS))
            {
                if(send(client_socket, msg.log_msg, strlen(msg.log_msg), 0) <= 0)
                {
                    ESP_LOGI(TAG, "client disonnected");
                    client_discon = 1;
                    break;
                }
            }
        }

        shutdown(client_socket, 0);
        close(client_socket);
        queue_active[NET_Q] = 0;
    }
}

static void net_producer(void* args)
{
    int client_socket = -1;
    repl_mux_message_t msg;

    while(1)
    {
        client_socket = -1;
        xQueueReceive(client_connected_notifier, &client_socket, portMAX_DELAY);
        if(client_socket == -1)
        {
            continue;
        }

        while(!client_discon)
        {
            ssize_t recv_len = recv(client_socket, &msg, CONFIG_REPL_MUX_MAX_LOG_MSG, 0);
            if(recv_len > 0)
            {
                msg.log_msg[recv_len-1] = 0;
                run(msg.log_msg);
            }
            else if(recv_len <= 0)
            {
                ESP_LOGI(TAG, "client disconnected");
                client_discon = 1;
                break;
            }
        }
    }
}

//*****************************************************************************
// REPL MUX Q Publisher
//*****************************************************************************

static int log_publisher(const char* string, va_list arg_list)
{
    uint8_t i;
    repl_mux_message_t msg;
    for(i = 0; i < CONFIG_REPL_MUX_N_QUEUES; ++i)
    {
        if(queue_active[i])
        {
            vsnprintf(msg.log_msg, CONFIG_REPL_MUX_MAX_LOG_MSG, string, arg_list);
            if(!xQueueSend(qs[i], (void*) &msg, TTL))
            {
                printf("REPL MUX QUEUE FULL!!\n");
            }
        }
    }

    return 0;
}

//*****************************************************************************
// API Funcs
//*****************************************************************************

esp_err_t repl_mux_register(char* name, char* desc, cmd_func_t func)
{
    if(num_cmds == CONFIG_REPL_MUX_MAX_NUM_CMD)
    {
        ESP_LOGE(TAG, "Command Table Full");
        return ESP_ERR_INVALID_STATE;
    }

    strncpy(cmd_list[num_cmds].name, name, CONFIG_REPL_MUX_NAME_LEN-1);
    strncpy(cmd_list[num_cmds].desc, desc, CONFIG_REPL_MUX_DESC_LEN-1 );
    cmd_list[num_cmds].func = func;
    num_cmds++;

    ESP_LOGI(TAG, "Command Added %s (%d/%d)", name, num_cmds, CONFIG_REPL_MUX_MAX_NUM_CMD);

    return ESP_OK;
}

esp_err_t repl_mux_init(void)
{
    uint8_t i;
    for(i = 0; i < CONFIG_REPL_MUX_N_QUEUES; ++i)
    {
        qs[i] = xQueueCreate(CONFIG_REPL_MUX_Q_SIZE, sizeof(repl_mux_message_t));
        if(qs[i] == 0)
        {
            return ESP_ERR_NO_MEM;
        }
    }

    client_connected_notifier = xQueueCreate(1, sizeof(int));
    if(client_connected_notifier == 0)
    {
        return ESP_ERR_NO_MEM;
    }

    TaskHandle_t h;
    xTaskCreate(uart_producer,
            "UART In",
            CONFIG_REPL_MUX_STACK_SIZE,
            NULL,
            CONFIG_REPL_MUX_CONSUMER_PRIO - 1,
            &h);
    assert(h);

    xTaskCreate(net_producer,
                "NET in",
                CONFIG_REPL_MUX_STACK_SIZE,
                NULL,
                CONFIG_REPL_MUX_CONSUMER_PRIO - 1,
                &h);
    assert(&h);

    xTaskCreate(uart_consumer,
                "UART Out", 
                CONFIG_REPL_MUX_STACK_SIZE, 
                NULL, 
                CONFIG_REPL_MUX_CONSUMER_PRIO,
                &h);
    assert(h);

    xTaskCreate(net_consumer,
                "NET Out",
                CONFIG_REPL_MUX_STACK_SIZE, 
                NULL, 
                CONFIG_REPL_MUX_CONSUMER_PRIO,
                &h);
    assert(h);


    
    esp_log_set_vprintf(log_publisher);

    ESP_ERROR_CHECK(repl_mux_register("help", "print desc of each cmd", &do_help));

    return ESP_OK;
}