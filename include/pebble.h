#pragma once

// Platform: emery = Pebble Time 2 (SF32LB52J, Cortex-M33)
// Display: 200 x 228, 64-color e-paper
#define PBL_PLATFORM_EMERY
#define PBL_COLOR
#define PBL_MICROPHONE
#define PBL_TOUCHSCREEN  // Time 2 has touch
#define PBL_DISPLAY_WIDTH  200
#define PBL_DISPLAY_HEIGHT 228

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

#include "pebble/gtypes.h"
#include "pebble/fonts.h"
#include "pebble/graphics.h"
#include "pebble/layers.h"
#include "pebble/app.h"
