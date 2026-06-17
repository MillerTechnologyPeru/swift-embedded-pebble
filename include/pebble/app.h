#pragma once
#include <time.h>
#include <stdint.h>
#include <stdbool.h>

// --- App event loop ---
void app_event_loop(void);

// --- Timers ---
typedef struct AppTimer AppTimer;
typedef void (*AppTimerCallback)(void *data);

AppTimer *app_timer_register(uint32_t timeout_ms, AppTimerCallback callback, void *callback_data);
void      app_timer_cancel(AppTimer *timer);
bool      app_timer_reschedule(AppTimer *timer, uint32_t new_timeout_ms);

// --- Tick timer service ---
typedef enum TimeUnits {
    SECOND_UNIT = 1 << 0,
    MINUTE_UNIT = 1 << 1,
    HOUR_UNIT   = 1 << 2,
    DAY_UNIT    = 1 << 3,
    MONTH_UNIT  = 1 << 4,
    YEAR_UNIT   = 1 << 5,
} TimeUnits;

typedef void (*TickHandler)(struct tm *tick_time, TimeUnits units_changed);
void tick_timer_service_subscribe(TimeUnits tick_units, TickHandler handler);
void tick_timer_service_unsubscribe(void);

// --- Logging ---
void app_log(uint8_t log_level, const char *src_filename, int src_line_number, const char *fmt, ...)
    __attribute__((format(printf, 4, 5)));

#define APP_LOG(level, fmt, ...) \
    app_log(level, __FILE__, __LINE__, fmt, ##__VA_ARGS__)

#define APP_LOG_LEVEL_ERROR   1
#define APP_LOG_LEVEL_WARNING 50
#define APP_LOG_LEVEL_INFO    100
#define APP_LOG_LEVEL_DEBUG   200
