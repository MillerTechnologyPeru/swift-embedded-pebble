// PebbleSDK.swift
// Thin Swift wrappers over the Pebble C SDK.
import PebbleSDK

// MARK: - Geometry helpers
// Swift can't call C compound-literal macros (GPoint, GSize, GRect) as functions.
// We build the structs via member assignment — same codegen, zero overhead.

@inline(__always)
func makeGPoint(x: Int16, y: Int16) -> GPoint {
    var p = GPoint()
    p.x = x
    p.y = y
    return p
}

@inline(__always)
func makeGSize(w: Int16, h: Int16) -> GSize {
    var s = GSize()
    s.w = w
    s.h = h
    return s
}

@inline(__always)
func makeGRect(x: Int16, y: Int16, w: Int16, h: Int16) -> GRect {
    var r = GRect()
    r.origin = makeGPoint(x: x, y: y)
    r.size   = makeGSize(w: w, h: h)
    return r
}

// Display dimensions for Pebble Time 2 (emery platform)
let kDisplayWidth:  Int16 = 200
let kDisplayHeight: Int16 = 228
let kDisplayBounds        = makeGRect(x: 0, y: 0, w: 200, h: 228)

// MARK: - Counter buffer
// Swift 6.2 Embedded now supports full String APIs, but formatting to a C string
// for text_layer_set_text() still needs a fixed-size buffer.
// Swift 6.2 InlineArray<N, T> is the idiomatic Embedded replacement for tuple hacks.
// InlineArray<8, CChar> is a stack-allocated, non-heap fixed-size array.
typealias CounterBuf = InlineArray<8, CChar>

func formatCounter(_ value: Int32, into buf: inout CounterBuf) {
    var v = value < 0 ? (value == Int32.min ? Int32.max : -value) : value
    var tmp: InlineArray<8, CChar> = InlineArray(repeating: 0)
    var i = 7
    if v == 0 {
        i -= 1; tmp[i] = CChar(UInt8(ascii: "0"))
    } else {
        while v > 0 && i > 0 {
            i -= 1
            tmp[i] = CChar(UInt8(ascii: "0")) &+ CChar(v % 10)
            v /= 10
        }
    }
    if value < 0 && i > 0 { i -= 1; tmp[i] = CChar(UInt8(ascii: "-")) }
    var dst = 0
    while i < 8 { buf[dst] = tmp[i]; dst += 1; i += 1 }
}

// MARK: - Graphics Context

struct GraphicsContext {
    let rawValue: GContext

    @inline(__always)
    func setFillColor(_ color: GColor8) {
        graphics_context_set_fill_color(rawValue, color)
    }

    @inline(__always)
    func setStrokeColor(_ color: GColor8) {
        graphics_context_set_stroke_color(rawValue, color)
    }

    @inline(__always)
    func setTextColor(_ color: GColor8) {
        graphics_context_set_text_color(rawValue, color)
    }

    @inline(__always)
    func fillRect(_ rect: GRect, cornerRadius: UInt16 = 0, corners: GCornerMask = GCornerNone) {
        graphics_fill_rect(rawValue, rect, cornerRadius, corners)
    }

    @inline(__always)
    func fillCircle(center: GPoint, radius: UInt16) {
        graphics_fill_circle(rawValue, center, radius)
    }

    @inline(__always)
    func drawLine(from p0: GPoint, to p1: GPoint) {
        graphics_draw_line(rawValue, p0, p1)
    }

    @inline(__always)
    func drawText(
        _ text: UnsafePointer<CChar>?,
        font: GFont?,
        in box: GRect,
        overflow: GTextOverflowMode = GTextOverflowModeWordWrap,
        alignment: GTextAlignment = GTextAlignmentLeft
    ) {
        graphics_draw_text(rawValue, text, font, box, overflow, alignment, nil)
    }
}

// MARK: - Layer
// Swift 6.4: borrow accessor on computed properties avoids copying
// the UnsafeMutablePointer when we only need to read it.

struct PebbleLayer {
    let rawValue: UnsafeMutablePointer<Layer>

    init(frame: GRect) {
        rawValue = layer_create(frame)
    }

    init(rawValue: UnsafeMutablePointer<Layer>) {
        self.rawValue = rawValue
    }

    @inline(__always)
    func markDirty() {
        layer_mark_dirty(rawValue)
    }

    @inline(__always)
    func addChild(_ child: PebbleLayer) {
        layer_add_child(rawValue, child.rawValue)
    }

    @inline(__always)
    func addChild(_ child: UnsafeMutablePointer<Layer>?) {
        guard let child else { return }
        layer_add_child(rawValue, child)
    }

    @inline(__always)
    func setUpdateProc(_ proc: @convention(c) (UnsafeMutablePointer<Layer>?, GContext?) -> Void) {
        layer_set_update_proc(rawValue, proc)
    }

    var bounds: GRect {
        layer_get_bounds(rawValue)
    }
}

// MARK: - Window

struct PebbleWindow {
    let rawValue: UnsafeMutablePointer<Window>

    init(rawValue: UnsafeMutablePointer<Window>) {
        self.rawValue = rawValue
    }

    @inline(__always)
    func setBackgroundColor(_ color: GColor8) {
        window_set_background_color(rawValue, color)
    }

    @inline(__always)
    func push(animated: Bool = true) {
        window_stack_push(rawValue, animated)
    }

    var rootLayer: PebbleLayer {
        PebbleLayer(rawValue: window_get_root_layer(rawValue))
    }

    @inline(__always)
    func setClickConfigProvider(_ provider: @convention(c) (UnsafeMutableRawPointer?) -> Void) {
        window_set_click_config_provider(rawValue, provider)
    }
}

// MARK: - Text Layer

struct PebbleTextLayer {
    let rawValue: UnsafeMutablePointer<TextLayer>

    init(frame: GRect) {
        rawValue = text_layer_create(frame)
    }

    @inline(__always)
    func destroy() {
        text_layer_destroy(rawValue)
    }

    @inline(__always)
    func setText(_ text: UnsafePointer<CChar>?) {
        text_layer_set_text(rawValue, text)
    }

    @inline(__always)
    func setFont(_ font: GFont?) {
        text_layer_set_font(rawValue, font)
    }

    @inline(__always)
    func setTextColor(_ color: GColor8) {
        text_layer_set_text_color(rawValue, color)
    }

    @inline(__always)
    func setBackgroundColor(_ color: GColor8) {
        text_layer_set_background_color(rawValue, color)
    }

    @inline(__always)
    func setAlignment(_ alignment: GTextAlignment) {
        text_layer_set_text_alignment(rawValue, alignment)
    }

    var layer: UnsafeMutablePointer<Layer>? {
        text_layer_get_layer(rawValue)
    }
}
