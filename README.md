# swift-embedded-pebble

A **Hello World** Pebble app for the **Pebble Time 2** (`emery` platform),
written in **Embedded Swift**, updated for **Swift 6.2 / 6.3 / 6.4**.

<img width="199" height="227" alt="Screenshot 2026-06-16 at 10 26 09 PM" src="https://github.com/user-attachments/assets/a9eabd77-2e96-4aaf-8c26-c3f54647683e" />

The app shows a title, a live counter, and wires up the three right-side
buttons (↑ increment, ● reset, ↓ decrement).

## Hardware target

| Watch         | Platform | MCU              | Display          |
|---------------|----------|------------------|------------------|
| Pebble Time 2 | `emery`  | SiFli SF32LB52J  | 200×228          |
|               |          | Cortex-M33 @ 240 MHz | 64-color e-paper |

Swift target triple: `armv8m.main-none-none-eabi`

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
