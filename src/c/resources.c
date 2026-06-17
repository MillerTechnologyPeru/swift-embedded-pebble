// resources.c
// Bridges Pebble build-generated resource ids to Swift.
//
// RESOURCE_ID_* macros are emitted by the Pebble build into the real SDK's
// resource_ids.auto.h (pulled in by <pebble.h> during the C build). The Swift
// module compiles against our trimmed headers in include/ and never sees those
// macros, so we expose the id through a plain function instead.

#include <pebble.h>
#include <stdint.h>

uint32_t swift_resource_id_swift_logo(void) {
    return RESOURCE_ID_IMAGE_SWIFT_LOGO;
}
