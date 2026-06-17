#pragma once
#include "gtypes.h"
#include "fonts.h"

// --- Graphics context drawing ---

void graphics_context_set_fill_color(GContext ctx, GColor color);
void graphics_context_set_stroke_color(GContext ctx, GColor color);
void graphics_context_set_text_color(GContext ctx, GColor color);
void graphics_context_set_stroke_width(GContext ctx, uint8_t stroke_width);

void graphics_fill_rect(GContext ctx, GRect rect, uint16_t corner_radius, GCornerMask corner_mask);
void graphics_draw_rect(GContext ctx, GRect rect);
void graphics_fill_circle(GContext ctx, GPoint p, uint16_t radius);
void graphics_draw_circle(GContext ctx, GPoint p, uint16_t radius);
void graphics_draw_line(GContext ctx, GPoint p0, GPoint p1);

void graphics_draw_text(GContext ctx,
                        const char *text,
                        GFont font,
                        GRect box,
                        GTextOverflowMode overflow_mode,
                        GTextAlignment alignment,
                        void *text_attributes);
