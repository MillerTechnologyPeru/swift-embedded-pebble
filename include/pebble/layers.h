#pragma once
#include "gtypes.h"
#include "graphics.h"

typedef struct Layer      { uint8_t _opaque[1]; } Layer;
typedef struct Window     { uint8_t _opaque[1]; } Window;
typedef struct TextLayer  { uint8_t _opaque[1]; } TextLayer;
typedef struct BitmapLayer { uint8_t _opaque[1]; } BitmapLayer;

// LayerUpdateProc — called by OS when layer needs redrawing
typedef void (*LayerUpdateProc)(Layer *layer, GContext ctx);

// --- Layer ---
Layer   *layer_create(GRect frame);
Layer   *layer_create_with_data(GRect frame, size_t data_size);
void     layer_destroy(Layer *layer);
void     layer_mark_dirty(Layer *layer);
void     layer_add_child(Layer *parent, Layer *child);
void     layer_remove_from_parent(Layer *layer);
void     layer_set_frame(Layer *layer, GRect frame);
void     layer_set_bounds(Layer *layer, GRect bounds);
GRect    layer_get_frame(const Layer *layer);
GRect    layer_get_bounds(const Layer *layer);
void     layer_set_update_proc(Layer *layer, LayerUpdateProc update_proc);
void    *layer_get_data(const Layer *layer);

// --- Window ---
Window  *window_create(void);
void     window_destroy(Window *window);
void     window_stack_push(Window *window, bool animated);
void     window_stack_pop(bool animated);
Layer   *window_get_root_layer(const Window *window);
void     window_set_background_color(Window *window, GColor background_color);

// Click handlers
typedef void (*ClickHandler)(void *context);
typedef void (*ClickConfigProvider)(void *context);
void window_set_click_config_provider(Window *window, ClickConfigProvider click_config_provider);
void window_set_click_config_provider_with_context(Window *window,
    ClickConfigProvider click_config_provider, void *context);

typedef enum ButtonId {
    BUTTON_ID_BACK   = 0,
    BUTTON_ID_UP     = 1,
    BUTTON_ID_SELECT = 2,
    BUTTON_ID_DOWN   = 3,
    NUM_BUTTONS      = 4,
} ButtonId;

void window_single_click_subscribe(ButtonId button_id, ClickHandler handler);

// --- TextLayer (convenience wrapper around Layer) ---
TextLayer *text_layer_create(GRect frame);
void       text_layer_destroy(TextLayer *text_layer);
void       text_layer_set_text(TextLayer *text_layer, const char *text);
void       text_layer_set_font(TextLayer *text_layer, GFont font);
void       text_layer_set_text_color(TextLayer *text_layer, GColor color);
void       text_layer_set_background_color(TextLayer *text_layer, GColor color);
void       text_layer_set_text_alignment(TextLayer *text_layer, GTextAlignment text_alignment);
Layer     *text_layer_get_layer(TextLayer *text_layer);
