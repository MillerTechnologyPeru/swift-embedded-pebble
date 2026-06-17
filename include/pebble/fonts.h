#pragma once
#include "gtypes.h"

// System font keys — typed as const char * so Swift imports them as UnsafePointer<CChar>
static const char * const FONT_KEY_GOTHIC_14             = "RESOURCE_ID_GOTHIC_14";
static const char * const FONT_KEY_GOTHIC_14_BOLD        = "RESOURCE_ID_GOTHIC_14_BOLD";
static const char * const FONT_KEY_GOTHIC_18             = "RESOURCE_ID_GOTHIC_18";
static const char * const FONT_KEY_GOTHIC_18_BOLD        = "RESOURCE_ID_GOTHIC_18_BOLD";
static const char * const FONT_KEY_GOTHIC_24             = "RESOURCE_ID_GOTHIC_24";
static const char * const FONT_KEY_GOTHIC_24_BOLD        = "RESOURCE_ID_GOTHIC_24_BOLD";
static const char * const FONT_KEY_GOTHIC_28             = "RESOURCE_ID_GOTHIC_28";
static const char * const FONT_KEY_GOTHIC_28_BOLD        = "RESOURCE_ID_GOTHIC_28_BOLD";
static const char * const FONT_KEY_BITHAM_30_BLACK       = "RESOURCE_ID_BITHAM_30_BLACK";
static const char * const FONT_KEY_BITHAM_42_BOLD        = "RESOURCE_ID_BITHAM_42_BOLD";
static const char * const FONT_KEY_BITHAM_42_LIGHT       = "RESOURCE_ID_BITHAM_42_LIGHT";
static const char * const FONT_KEY_ROBOTO_BOLD_SUBSET_49 = "RESOURCE_ID_ROBOTO_BOLD_SUBSET_49";
static const char * const FONT_KEY_LECO_42_NUMBERS       = "RESOURCE_ID_LECO_42_NUMBERS";

GFont fonts_get_system_font(const char *font_key);
