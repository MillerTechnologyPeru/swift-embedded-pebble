# pebble-swift-hello

A **Hello World** Pebble app for the **Pebble Time 2** (`emery` platform),
written in **Embedded Swift**, updated for **Swift 6.2 / 6.3 / 6.4**.

The app shows a title, a live counter, and wires up the three right-side
buttons (↑ increment, ● reset, ↓ decrement).

## Hardware target

| Watch         | Platform | MCU              | Display          |
|---------------|----------|------------------|------------------|
| Pebble Time 2 | `emery`  | SiFli SF32LB52J  | 200×228          |
|               |          | Cortex-M33 @ 240 MHz | 64-color e-paper |

Swift target triple: `armv8m.main-none-none-eabi`

## Swift 6.2 / 6.3 / 6.4 changes applied

### Swift 6.2 (released Sept 2025)
- **Full `String` APIs in Embedded** — `String` now works in Embedded Swift.
  For Pebble we still pass C strings to `text_layer_set_text`, but `String`
  can now be used for intermediate formatting without a heap allocator if
  you use stack-allocated storage.
- **`InlineArray<N, T>`** — new fixed-size stack array type. Replaces the
  old `(CChar, CChar, CChar, ...)` tuple hack for the counter string buffer:
  ```swift
  // Before (Swift 6.0/6.1):
  private var sCounterBuf: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) = (0x30, 0, ...)

  // After (Swift 6.2+):
  private var sCounterBuf = InlineArray<8, CChar>(repeating: 0)
  ```
- **`any` types for class-constrained protocols** — available in Embedded.
  Not used here (no class types on bare-metal), but unlocks richer abstraction
  patterns for the future SwiftUI-style library.

### Swift 6.3 (released March 2026)
- **`@c` attribute (SE-0495)** — replaces `@_silgen_name` for C-exported functions.
  `@c("swift_app_init")` gives the function a predictable C symbol name AND
  emits a validated declaration in the generated C header:
  ```swift
  // Before (Swift 6.0–6.2):
  @_silgen_name("swift_app_init")
  public func swiftAppInit() { ... }

  // After (Swift 6.3+):
  @c("swift_app_init")
  public func swiftAppInit() { ... }
  ```
  `main.c` can now `#include "build/PebbleApp-Swift.h"` and get a
  compiler-validated signature instead of a hand-written `extern void` decl.
- **`@c @implementation`** — implement a C-declared function in Swift with
  compiler signature validation. Use once `swift_app_init` is in a C header.
- **`EmbeddedRestrictions` diagnostic group** — on by default in Swift 6.3.
  Warns about language constructs unavailable in Embedded (untyped throws,
  generic calls on existentials, etc.). This codebase is fully compliant;
  run `make diagnostics` to confirm.
- **Improved C pointer nullability tolerance** — no more cryptic
  "deserialization failure" when nullability annotations differ between
  a Swift declaration and a C header.
- **Float/Double `description` in Embedded** — floating-point printing now
  works in Embedded Swift. Useful for debugging sensor values.

### Swift 6.4 (WWDC26, June 2026)
- **`borrow`/`mutate` accessors** — `PebbleSDK.swift` uses `borrow` for
  computed properties like `rootLayer` and `bounds`, avoiding a copy of the
  `GRect` / `PebbleLayer` value:
  ```swift
  var bounds: GRect {
      borrow { layer_get_bounds(rawValue) }
  }
  ```
- **Wrapping arithmetic operators (`&+`, `&-`)** — used for the counter
  to avoid a runtime trap on overflow (Embedded has no overflow handler).
- **`anyAppleOS` / `@diagnose`** — host-side tooling improvements; no
  impact on bare-metal Embedded code.

## Project layout

```
pebble-swift-hello/
├── package.json               # Pebble app metadata
├── wscript                    # WAF build (Swift 6.3+ aware)
├── Makefile                   # Standalone make
├── include/
│   ├── pebble.h               # Master SDK header
│   ├── module.modulemap       # Exposes pebble.h to Swift's C importer
│   └── pebble/                # gtypes, fonts, graphics, layers, app
└── src/
    ├── swift/
    │   ├── PebbleSDK.swift    # Zero-cost Swift wrappers (InlineArray, borrow accessors)
    │   └── App.swift          # App logic (@c, InlineArray counter buf, &+/&-)
    └── c/
        └── main.c             # C entry: app_main() → swift_app_init()
```

## Building

### Prerequisites

1. **Swift 6.3+** (6.4 recommended for borrow accessors)
   ```bash
   # macOS
   brew install swift      # or install Xcode 27+
   # Linux — download from https://swift.org/download/
   ```
   Verify target support:
   ```bash
   swiftc -enable-experimental-feature Embedded \
     -target armv8m.main-none-none-eabi \
     -Xcc -mcpu=cortex-m33 -Xcc -mthumb \
     /dev/null -o /dev/null 2>&1 | head -3
   ```

2. **`arm-none-eabi-gcc`**
   ```bash
   brew install --cask gcc-arm-embedded   # macOS
   apt install gcc-arm-none-eabi          # Ubuntu/Debian
   ```

3. **Pebble SDK** (for `.pbw` packaging)
   ```bash
   pip install pebble-tool
   pebble sdk install latest
   ```

### Standalone compile (no SDK needed)

```bash
# Compile Swift → ARM object + emit generated C header
make

# View the @c-generated C header (swift_app_init declaration)
make header

# Type-check with EmbeddedRestrictions warnings surfaced
make diagnostics

# Inspect ARM symbols (verify swift_app_init is exported)
make symbols
```

### Full build via pebble-tool

```bash
pebble build --platform emery
pebble install --emulator emery
pebble logs --emulator emery
```

## Entry point chain

```
PebbleOS
  └─► app_main()                      [src/c/main.c]
        └─► swift_app_init()           [src/swift/App.swift]
              │  @c("swift_app_init")  ← SE-0495, Swift 6.3
              │  emits build/PebbleApp-Swift.h for C to #include
              ├─ window_create()
              ├─ window_stack_push()
              ├─ windowLoad()
              │    ├─ PebbleTextLayer / PebbleLayer wrappers
              │    ├─ InlineArray<8,CChar> counter buffer (Swift 6.2)
              │    └─ borrow accessors on rootLayer/bounds (Swift 6.4)
              └─ app_event_loop()
```
