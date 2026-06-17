#pragma once
#include <stdint.h>
#include <stdbool.h>

// --- Geometry ---

typedef struct GPoint {
    int16_t x;
    int16_t y;
} GPoint;

typedef struct GSize {
    int16_t w;
    int16_t h;
} GSize;

typedef struct GRect {
    GPoint origin;
    GSize  size;
} GRect;

// Constructor macros — match real Pebble SDK style
#define GPoint(x, y)       ((GPoint){(x), (y)})
#define GSize(w, h)        ((GSize){(w), (h)})
#define GRect(x, y, w, h)  ((GRect){{(x), (y)}, {(w), (h)}})

// --- Color ---

typedef union GColor8 {
    uint8_t argb;
    struct { uint8_t b:2, g:2, r:2, a:2; };
} GColor8;
typedef GColor8 GColor;

static const GColor8 GColorBlack      = { .argb = 0xC0 };
static const GColor8 GColorWhite      = { .argb = 0xFF };
static const GColor8 GColorBlue       = { .argb = 0xC3 };
static const GColor8 GColorRed        = { .argb = 0xF0 };
static const GColor8 GColorGreen      = { .argb = 0xCC };
static const GColor8 GColorClear      = { .argb = 0x00 };
static const GColor8 GColorOxfordBlue = { .argb = 0xC1 };

// --- Text ---

typedef enum GTextAlignment {
    GTextAlignmentLeft   = 0,
    GTextAlignmentCenter = 1,
    GTextAlignmentRight  = 2,
} GTextAlignment;

typedef enum GTextOverflowMode {
    GTextOverflowModeWordWrap  = 0,
    GTextOverflowModeFill      = 1,
    GTextOverflowModeTrailingEllipsis = 2,
} GTextOverflowMode;

typedef void *GFont;
typedef void *GContext;

// --- Corner mask ---
typedef enum GCornerMask {
    GCornerNone        = 0,
    GCornerTopLeft     = 1 << 0,
    GCornerTopRight    = 1 << 1,
    GCornerBottomLeft  = 1 << 2,
    GCornerBottomRight = 1 << 3,
    GCornersAll        = 0xF,
    GCornersTop        = (1<<0)|(1<<1),
    GCornersBottom     = (1<<2)|(1<<3),
    GCornersLeft       = (1<<0)|(1<<2),
    GCornersRight      = (1<<1)|(1<<3),
} GCornerMask;
