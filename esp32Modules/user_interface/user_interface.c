#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/time.h>

#include "esp_system.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"

#include "user_interface.h"
#include "HD44780.h"
#include "encoder.h"

#define CHECK(x) do { esp_err_t __; if ((__ = x) != ESP_OK) return __; } while (0)
#define CHECK_W_LOCK(x) do { esp_err_t __; if ((__ = x) != ESP_OK) { assert(xSemaphoreGive(lcd_lock)); return __;} } while (0)

#define MAX_NUM_UI_CMDS CONFIG_UI_NUM_CMDS
#define MAX_UI_LOG_LINES CONFIG_UI_NUM_LINE_BUFF
#define UI_EVENT_Q_SIZE CONFIG_UI_EVENT_Q_SIZE
#define UI_EVENT_HANDLER_PRIO CONFIG_UI_EVENT_HNDLR_PRIO

#define LCD_COLS CONFIG_LCD_COLS
#define LCD_ROWS CONFIG_LCD_ROWS

#define BUTTON_PIN 33
#define ROT_A_PIN 32
#define ROT_B_PIN 27

static const char* TAG = "UI";
static QueueHandle_t ui_event_q;
static rotary_encoder_t re = {0};
static SemaphoreHandle_t lcd_lock;

static char* cmd_list;
static command_cb_t* init_cb_list;
static command_cb_t* fini_cb_list;
static on_press_cb_t* on_press_cb_list;
static char* current_log;
static uint8_t num_cmds = 0;
static uint8_t in_menu = 1;
static uint8_t in_log_cmd_index = 0;
static uint8_t cursor_pos_on_screen = 0;
static uint8_t index_of_first_line = 0;
static uint8_t cursor_locked = 0;

static void button_short_press(void);
static void button_long_press(void);
static void rot_left(void);
static void rot_right(void);

// Main UI Event Loop. Waits for the timer going off in the rotary code to 
// poll and post events to the ui event Q. Based on the event we get notified 
// of, call the appropriate call back i.e. short_press(), long_press, etc
static void ui_event_handler(void* arg)
{
    rotary_encoder_event_t e;
    for(;;)
    {
        xQueueReceive(ui_event_q, &e, portMAX_DELAY);
        switch (e.type)
        {
            case RE_ET_BTN_PRESSED:
                ESP_LOGI(TAG, "Button pressed");
                break;
            case RE_ET_BTN_RELEASED:
                ESP_LOGI(TAG, "Button released");
                break;
            case RE_ET_BTN_CLICKED:
                ESP_LOGI(TAG, "Button clicked");
                button_short_press();
                break;
            case RE_ET_BTN_LONG_PRESSED:
                ESP_LOGI(TAG, "Looooong pressed button");
                button_long_press();
                break;
            case RE_ET_CHANGED:
                if(e.diff > 0)
                {
                    ESP_LOGI(TAG, "Rot Right");
                    rot_right();
                }
                else
                {
                    ESP_LOGI(TAG, "Rot Left");
                    rot_left();
                }
                break;
            default:
                break;
        }
        
    }
}

//*****************************************************************************
// BUTTON PRVATE
//*****************************************************************************

// On short press, if are at the main menu, reset our position on the screen
// and in the buffer and call the clicked commands init func
static void button_short_press(void)
{
    if(in_menu)
    {
        in_menu = 0;

        in_log_cmd_index = index_of_first_line + cursor_pos_on_screen;
        command_cb_t cb = init_cb_list[in_log_cmd_index];

        cursor_pos_on_screen = 0;
        index_of_first_line = 0;
        cb();
    }
    else
    {
        on_press_cb_t cb = on_press_cb_list[in_log_cmd_index];
        cb(index_of_first_line + cursor_pos_on_screen);
    }

    ui_update_display();
}

// On a long press we exit back out into the menu screen. Call the commands 
// fini and reset our pos on the screen.
static void button_long_press(void)
{
    if(!in_menu)
    {
        command_cb_t cb = fini_cb_list[in_log_cmd_index];
        cb();
    }

    in_menu = 1;
    cursor_pos_on_screen = 0;
    index_of_first_line = 0;
    in_log_cmd_index = 0;
    cursor_locked = 0;
    ui_update_display();
}

//*****************************************************************************
// ROT PRIVATE
//*****************************************************************************

// Scroll up
static void rot_left(void)
{
    if(cursor_locked)
    {
        return;
    }
    // left = up
    if(cursor_pos_on_screen == 0 && index_of_first_line == 0)
    {
        return;
    }

    if(cursor_pos_on_screen == 0 && index_of_first_line > 0)
    {
        index_of_first_line--;
        ui_update_display();
        return;
    }
    
    if(cursor_pos_on_screen > 0 && cursor_pos_on_screen < LCD_ROWS)
    {
        // no need to update whats on screen just move cursor
        cursor_pos_on_screen--;
        ui_update_display();
        return;
    }
}

// Scroll down. When in menu use the list of commands to scroll through. When
// not in menu use the line buffer provided that the command is pushing to.
static void rot_right(void)
{
    if(cursor_locked)
    {
        return;
    }

    uint8_t max = 0;
    if(in_menu){ max = num_cmds; }
    else       { max = MAX_UI_LOG_LINES; }

    // right = down
    if((cursor_pos_on_screen == (LCD_ROWS-1)) && ((index_of_first_line + LCD_ROWS) == (max-1)) )
    {
        return;
    }

    if((cursor_pos_on_screen == (LCD_ROWS-1)) && ((index_of_first_line + LCD_ROWS) < (max-1)))
    {
        ++index_of_first_line;
        ui_update_display();
        return;
    }

    if((cursor_pos_on_screen < (LCD_ROWS-1)))
    {
        if(index_of_first_line + cursor_pos_on_screen == max - 1)
        {
            return;
        }

        ++cursor_pos_on_screen;
        ui_update_display();
        return;
    }
}

//*****************************************************************************
// Test Functions to export to a repl interface
//*****************************************************************************

static char* get_cmd_str(uint8_t n)
{
    if(n < num_cmds)
    {
        return &cmd_list[n*LCD_COLS];
    }

    ESP_LOGE(TAG, "ERROR, tried to access cmd str that dont exist");
    return NULL;
}

int do_rot_l(int argc, char** argv)
{
    rot_left();
    return 0;
}

int do_rot_r(int argc, char** argv)
{
    rot_right();
    return 0;
}

int do_press(int argc, char** argv)
{
    button_short_press();
    return 0;
}

int do_long_press(int argc, char** argv)
{
    button_long_press();
    return 0;
}

//*****************************************************************************
// PUBLIC API
//*****************************************************************************

esp_err_t ui_init()
{    
    
    ui_event_q = xQueueCreate(UI_EVENT_Q_SIZE, sizeof(rotary_encoder_event_t));
    xTaskCreate(ui_event_handler, "ui event handler", 4096, NULL, UI_EVENT_HANDLER_PRIO, NULL);
    assert(ui_event_q);
    ESP_LOGI(TAG, "UI Event Handler Launched");

    // If we fail to add the rot encoder. That shouldn't be an issue for the
    // rest  of the module as the only result of failure is that the UI event
    // loop will get nothing posted to it
    esp_err_t e;
    e = rotary_encoder_init(ui_event_q);
    ESP_ERROR_CHECK_WITHOUT_ABORT(e);

    if(e == ESP_OK)
    {
        ESP_ERROR_CHECK_WITHOUT_ABORT(rotary_encoder_add(&re));
    }
    
    // If lcd init fails we should get a descriptive output of the nature of 
    // the failure to the log. Moreover, the LCD component guards against 
    // failure to init thus we are good to continue. Maybe in future have some
    // recovery code
    ESP_ERROR_CHECK_WITHOUT_ABORT(LCD_init());

    cmd_list = malloc(MAX_NUM_UI_CMDS * LCD_COLS);
    current_log = malloc(MAX_UI_LOG_LINES * LCD_COLS);
    init_cb_list = malloc(MAX_NUM_UI_CMDS * sizeof(command_cb_t));
    on_press_cb_list = malloc(MAX_NUM_UI_CMDS * sizeof(on_press_cb_t));
    fini_cb_list = malloc(MAX_NUM_UI_CMDS * sizeof(command_cb_t));

    assert(cmd_list);
    assert(current_log);
    assert(init_cb_list);
    assert(on_press_cb_list);
    assert(fini_cb_list);

    memset(cmd_list, 0, MAX_NUM_UI_CMDS * LCD_COLS);
    memset(current_log, 0, MAX_UI_LOG_LINES * LCD_COLS);

    in_menu = 1;
    in_log_cmd_index = 0;
    cursor_pos_on_screen = 0;
    index_of_first_line = 0;
    cursor_locked = 0;

    lcd_lock = xSemaphoreCreateBinary();
    assert(xSemaphoreGive(lcd_lock) == pdTRUE);

    return ESP_OK;
}

esp_err_t ui_add_cmd(char* name, command_cb_t cmd_init, on_press_cb_t on_press_cb, command_cb_t cmd_fini)
{
    // Check len of name if its more than 19 char kick that shit back
    if(strnlen(name, LCD_COLS - 1) > LCD_COLS - 1)
    {
        ESP_LOGE(TAG, "UI add of cmd %s failed, too long", name);
        return ESP_ERR_INVALID_ARG;
    }

    // Check to see if we are registering too many cmds
    if(num_cmds == MAX_NUM_UI_CMDS)
    {
        ESP_LOGE(TAG, "UI add of cmd %s failed, too many cmds", name);
        return ESP_ERR_INVALID_STATE;
    }

    strcpy(cmd_list + (num_cmds * LCD_COLS), name);
    init_cb_list[num_cmds] = cmd_init;
    on_press_cb_list[num_cmds] = on_press_cb;
    fini_cb_list[num_cmds] = cmd_fini;
    num_cmds++;

    ESP_LOGI(TAG, "UI Command %s registered", name);

    if(in_menu)
    {
        CHECK(ui_home_screen_pos()); // always succeeds anyways
        CHECK(ui_update_display()); // may fail
    }
    else
    {
        ESP_LOGE(TAG, "IN add ui cmd - weird that ui cmd added when not in menu");
    }

    return ESP_OK;
}

esp_err_t ui_push_to_line_buffer(uint8_t line_num, char* line)
{
    if(line_num >= MAX_UI_LOG_LINES)
    {
        ESP_LOGE(TAG, "Tried to put line outside of line buffer range");
        return ESP_ERR_INVALID_ARG;
    }

    if(strnlen(line, LCD_COLS - 1) > LCD_COLS - 1)
    {
        ESP_LOGE(TAG, "Log line %s too long", line);
        return ESP_ERR_INVALID_ARG;
    }

    strncpy(current_log + (line_num*LCD_COLS), line, LCD_COLS - 1);

    return ESP_OK;
}

esp_err_t ui_home_screen_pos(void)
{
    cursor_pos_on_screen = 0;
    index_of_first_line = 0;

    return ESP_OK;
}

char* _get_from_line_buffer(uint8_t line_num)
{
    if(line_num >= MAX_UI_LOG_LINES)
    {
        ESP_LOGE(TAG, "Tried to get line outside of line buffer range");
        return NULL;
    }
    return current_log + (line_num*LCD_COLS);
}

static esp_err_t _update_line(uint8_t row, uint8_t i, uint8_t max)
{
    char* line;

    if(!xSemaphoreTake(lcd_lock, 0))
    {
        ESP_LOGE(TAG, "in update line failed to get lcd lock");
        return ESP_ERR_INVALID_STATE;
    }

    CHECK_W_LOCK(LCD_setCursor(0, row));
    if(i == cursor_pos_on_screen + index_of_first_line)
    {
        CHECK_W_LOCK(LCD_writeChar('>'));
    }
    else
    {
        CHECK_W_LOCK(LCD_writeChar(' '));
    }

    CHECK_W_LOCK(LCD_setCursor(1, row));
    if(i < max)
    {
        if(in_menu) { line = get_cmd_str(i); }
        else        { line = _get_from_line_buffer(i); }

        CHECK_W_LOCK(LCD_writeStr(line));
    }

    assert(xSemaphoreGive(lcd_lock));
    return ESP_OK;
}

esp_err_t ui_update_display(void)
{
    if(!xSemaphoreTake(lcd_lock, 0))
    {
        ESP_LOGE(TAG, "in update display failed to get lcd lock");
        return ESP_ERR_INVALID_STATE;
    }

    CHECK_W_LOCK(LCD_home());
    CHECK_W_LOCK(LCD_clearScreen());

    assert(xSemaphoreGive(lcd_lock));

    uint8_t max = 0;
    if(in_menu){ max = num_cmds; }
    else { max = MAX_UI_LOG_LINES; }

    // display cmds, all are gareneteed to fit on screen
    uint8_t i = index_of_first_line;
    uint8_t row = 0;
    
    for(; i < index_of_first_line + LCD_ROWS; ++i)
    {
        CHECK(_update_line(row, i, max));
        ++row;
    }

    return ESP_OK;
}

esp_err_t ui_update_line(uint8_t i)
{
    if(in_menu)
    {
        ESP_LOGE(TAG, "Called update_line from menu context");
        return ESP_ERR_INVALID_STATE;
    }

    if(i >= MAX_UI_LOG_LINES)
    {
        ESP_LOGE(TAG, "Called update line with out of bounds index");
        return ESP_ERR_INVALID_ARG;
    }

    if(i < index_of_first_line || i >= index_of_first_line + 4)
    {
        ESP_LOGE(TAG, "Called update line on line not on screen");
        return ESP_ERR_INVALID_ARG;
    }

    return _update_line(i - index_of_first_line, i, MAX_UI_LOG_LINES);
}

esp_err_t ui_lock_cursor(void)
{
    cursor_locked = 1;
    return ESP_OK;
}

esp_err_t ui_unlock_cursor(void)
{
    cursor_locked = 0;
    return ESP_OK;
}