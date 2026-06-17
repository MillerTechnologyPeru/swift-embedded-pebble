// main.c
// Pebble's OS calls app_main() as the app entry point.
// We forward to swift_app_init(), which is defined in App.swift.
//
// Swift 6.3+: App.swift uses @c("swift_app_init") (SE-0495), which causes swiftc
// to emit a generated C header (PebbleApp-Swift.h) containing:
//
//   void swift_app_init(void);
//
// Include that header here instead of a hand-written extern declaration,
// so the compiler can validate the signature matches what Swift exported.
//
// During build: swiftc -emit-objc-header-path build/PebbleApp-Swift.h ...
// Then: arm-none-eabi-gcc -include build/PebbleApp-Swift.h ...
//
// For the initial bring-up without the generated header, the fallback
// extern declaration below is equivalent and always safe.

#include "pebble.h"

// Option A: use the swiftc-generated header (preferred with Swift 6.3+)
// #include "../../build/PebbleApp-Swift.h"

// Option B: manual forward declaration (fallback / initial bring-up)
extern void swift_app_init(void);

int main(void) {
    swift_app_init();
    return 0;
}
