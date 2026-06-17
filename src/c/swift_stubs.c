// Swift Embedded runtime stubs.
// Embedded Swift emits dead-code heap-allocation functions (swift_allocBox etc.)
// that reference posix_memalign. They are never reachable from our code, but the
// linker needs the symbol present. This stub traps if ever invoked.
#include <stddef.h>

int posix_memalign(void **memptr, size_t alignment, size_t size) {
    (void)memptr; (void)alignment; (void)size;
    while (1) {}   // unreachable in correct Embedded Swift programs
}
