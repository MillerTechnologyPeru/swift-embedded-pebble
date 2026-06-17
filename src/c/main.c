// main.c
// Pebble's OS calls app_main() as the app entry point.
// We forward to swift_app_init(), which is defined in App.swift.

#include "pebble.h"

extern void swift_app_init(void);

int main(void) {
    swift_app_init();
    return 0;
}
