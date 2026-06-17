// App.swift
// Hello World for Pebble Time 2, written in Embedded Swift (Swift 6.4)
import PebbleSDK

// MARK: - Static app state
// Embedded Swift: all persistent state lives in static storage (.data / .bss ELF sections).

private var sWindow:     UnsafeMutablePointer<Window>?    = nil
private var sTitleLayer: UnsafeMutablePointer<TextLayer>? = nil
private var sSubLayer:   UnsafeMutablePointer<TextLayer>? = nil
private var sCountLayer: UnsafeMutablePointer<TextLayer>? = nil
private var sHintLayer:  UnsafeMutablePointer<TextLayer>? = nil
private var sCounter:    Int32 = 0

// Swift 6.2: InlineArray<8, CChar> is the proper Embedded fixed-size stack buffer.
// Replaces the old (CChar, CChar, ...) tuple hack.
private var sCounterBuf = InlineArray<8, CChar>(repeating: 0)

// MARK: - Counter display

private func updateCounterDisplay() {
    formatCounter(sCounter, into: &sCounterBuf)
    withUnsafeBytes(of: &sCounterBuf) { raw in
        if let layer = sCountLayer {
            text_layer_set_text(layer, raw.baseAddress?.assumingMemoryBound(to: CChar.self))
            layer_mark_dirty(text_layer_get_layer(layer))
        }
    }
}

// MARK: - Button handlers
// @convention(c) closures stored in static lets — zero heap allocation,
// compatible with Pebble's C callback ABI.

private let onUpClick: @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in
    sCounter &+= 1   // wrapping add — no trap on overflow in Embedded
    updateCounterDisplay()
}

private let onDownClick: @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in
    sCounter &-= 1
    updateCounterDisplay()
}

private let onSelectClick: @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in
    sCounter = 0
    updateCounterDisplay()
}

private let clickConfigProvider: @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in
    window_single_click_subscribe(BUTTON_ID_UP,     onUpClick)
    window_single_click_subscribe(BUTTON_ID_DOWN,   onDownClick)
    window_single_click_subscribe(BUTTON_ID_SELECT, onSelectClick)
}

// MARK: - Window load

private func windowLoad(window: UnsafeMutablePointer<Window>) {
    let win = PebbleWindow(rawValue: window)
    win.setBackgroundColor(GColorOxfordBlue)

    let rootLayer = win.rootLayer          // Swift 6.4: borrow accessor
    let bounds    = rootLayer.bounds       // Swift 6.4: borrow accessor — no copy

    // ── "Hello from" ──────────────────────────────────────────
    let title = PebbleTextLayer(frame: makeGRect(x: 0, y: 20, w: bounds.size.w, h: 50))
    title.setText("Hello from")
    title.setFont(fonts_get_system_font(FONT_KEY_GOTHIC_28_BOLD))
    title.setTextColor(GColorWhite)
    title.setBackgroundColor(GColorClear)
    title.setAlignment(GTextAlignmentCenter)
    rootLayer.addChild(title.layer)
    sTitleLayer = title.rawValue

    // ── "Embedded Swift!" ──────────────────────────────────────
    let sub = PebbleTextLayer(frame: makeGRect(x: 0, y: 56, w: bounds.size.w, h: 44))
    sub.setText("Swift!")
    sub.setFont(fonts_get_system_font(FONT_KEY_BITHAM_30_BLACK))
    sub.setTextColor(GColorWhite)
    sub.setBackgroundColor(GColorClear)
    sub.setAlignment(GTextAlignmentCenter)
    rootLayer.addChild(sub.layer)
    sSubLayer = sub.rawValue

    // ── Divider via canvas layer ───────────────────────────────
    let divFrame  = makeGRect(x: 10, y: 110, w: kDisplayWidth - 20, h: 2)
    let divLayer  = PebbleLayer(frame: divFrame)
    divLayer.setUpdateProc { _, ctx in
        guard let ctx else { return }
        let r = makeGRect(x: 0, y: 0, w: kDisplayWidth - 20, h: 2)
        graphics_context_set_fill_color(ctx, GColorWhite)
        graphics_fill_rect(ctx, r, 0, GCornerNone)
    }
    rootLayer.addChild(divLayer)

    // ── "Counter" label ────────────────────────────────────────
    let label = PebbleTextLayer(frame: makeGRect(x: 0, y: 122, w: bounds.size.w, h: 28))
    label.setText("Counter")
    label.setFont(fonts_get_system_font(FONT_KEY_GOTHIC_24))
    label.setTextColor(GColorWhite)
    label.setBackgroundColor(GColorClear)
    label.setAlignment(GTextAlignmentCenter)
    rootLayer.addChild(label.layer)

    // ── Counter value (large) ──────────────────────────────────
    let count = PebbleTextLayer(frame: makeGRect(x: 0, y: 150, w: bounds.size.w, h: 56))
    count.setFont(fonts_get_system_font(FONT_KEY_BITHAM_42_BOLD))
    count.setTextColor(GColorWhite)
    count.setBackgroundColor(GColorClear)
    count.setAlignment(GTextAlignmentCenter)
    rootLayer.addChild(count.layer)
    sCountLayer = count.rawValue
    updateCounterDisplay()

    // ── Button hint ────────────────────────────────────────────
    let hint = PebbleTextLayer(frame: makeGRect(x: 0, y: 210, w: bounds.size.w, h: 18))
    hint.setText("UP +1  |  SEL 0  |  DN -1")
    hint.setFont(fonts_get_system_font(FONT_KEY_GOTHIC_14))
    hint.setTextColor(GColorWhite)
    hint.setBackgroundColor(GColorClear)
    hint.setAlignment(GTextAlignmentCenter)
    rootLayer.addChild(hint.layer)
    sHintLayer = hint.rawValue
}

// MARK: - Window unload

private func windowUnload() {
    if let l = sTitleLayer { text_layer_destroy(l) }
    if let l = sSubLayer   { text_layer_destroy(l) }
    if let l = sCountLayer { text_layer_destroy(l) }
    if let l = sHintLayer  { text_layer_destroy(l) }
    sTitleLayer = nil
    sSubLayer   = nil
    sCountLayer = nil
    sHintLayer  = nil
}

// MARK: - App entry point

@_silgen_name("swift_app_init")
public func swiftAppInit() {
    let window = window_create()
    sWindow = window

    window_set_click_config_provider(window, clickConfigProvider)
    window_stack_push(window, true)
    windowLoad(window: window!)

    app_event_loop()   // blocks; OS dispatches ticks, clicks, draw calls

    windowUnload()
    window_destroy(window)
}
