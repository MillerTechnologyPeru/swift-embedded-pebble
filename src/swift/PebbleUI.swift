// PebbleUI.swift
// SwiftUI-style declarative UI framework for Pebble, built on top of PebbleSDK.swift.
//
// Design constraints (Embedded Swift):
//  - No heap-allocated existentials (no `any View` boxes)
//  - No closures that capture heap state
//  - No dynamic dispatch via protocol witness tables stored on the heap
//  - All view state lives in static storage at the call site
//  - Result-builder composes views at compile time into a concrete type tree
//
// Pattern: define your screen as a `PebbleApp` conformer, call `PebbleUI.run(app:)`.
// Each `View` is a value type; `body` is called once during `windowLoad` to mount
// all layers. State mutation goes through `@State` (a property wrapper backed by
// static storage) which calls `markDirty()` on the owning canvas layer.

import PebbleSDK

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Color convenience
// ─────────────────────────────────────────────────────────────────────────────

extension GColor8 {
    static let black      = GColorBlack
    static let white      = GColorWhite
    static let blue       = GColorBlue
    static let red        = GColorRed
    static let green      = GColorGreen
    static let clear      = GColorClear
    static let oxfordBlue = GColorOxfordBlue

    static func rgb(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> GColor8 {
        var c = GColor8()
        c.argb = 0xC0 | ((r & 0x3) << 4) | ((g & 0x3) << 2) | (b & 0x3)
        return c
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Frame helpers
// ─────────────────────────────────────────────────────────────────────────────

extension GRect {
    static let displayBounds = makeGRect(x: 0, y: 0, w: 200, h: 228)
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Font
// ─────────────────────────────────────────────────────────────────────────────

enum Font {
    case gothic14, gothic14Bold
    case gothic18, gothic18Bold
    case gothic24, gothic24Bold
    case gothic28, gothic28Bold
    case bitham30Black
    case bitham42Bold, bitham42Light
    case roboto49
    case leco42

    var key: UnsafePointer<CChar> {
        switch self {
        case .gothic14:      return FONT_KEY_GOTHIC_14
        case .gothic14Bold:  return FONT_KEY_GOTHIC_14_BOLD
        case .gothic18:      return FONT_KEY_GOTHIC_18
        case .gothic18Bold:  return FONT_KEY_GOTHIC_18_BOLD
        case .gothic24:      return FONT_KEY_GOTHIC_24
        case .gothic24Bold:  return FONT_KEY_GOTHIC_24_BOLD
        case .gothic28:      return FONT_KEY_GOTHIC_28
        case .gothic28Bold:  return FONT_KEY_GOTHIC_28_BOLD
        case .bitham30Black: return FONT_KEY_BITHAM_30_BLACK
        case .bitham42Bold:  return FONT_KEY_BITHAM_42_BOLD
        case .bitham42Light: return FONT_KEY_BITHAM_42_LIGHT
        case .roboto49:      return FONT_KEY_ROBOTO_BOLD_SUBSET_49
        case .leco42:        return FONT_KEY_LECO_42_NUMBERS
        }
    }

    func load() -> GFont? { fonts_get_system_font(key) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - TextAlignment
// ─────────────────────────────────────────────────────────────────────────────

enum TextAlignment {
    case leading, center, trailing

    var raw: GTextAlignment {
        switch self {
        case .leading:  return GTextAlignmentLeft
        case .center:   return GTextAlignmentCenter
        case .trailing: return GTextAlignmentRight
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Button
// ─────────────────────────────────────────────────────────────────────────────

enum Button {
    case up, select, down, back

    var raw: ButtonId {
        switch self {
        case .up:     return BUTTON_ID_UP
        case .select: return BUTTON_ID_SELECT
        case .down:   return BUTTON_ID_DOWN
        case .back:   return BUTTON_ID_BACK
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - @State property wrapper
//
// In Embedded Swift there is no heap-allocated storage so @State stores
// an initial value inline and lets the view hold it as a stored property.
// Calling `markNeedsRedraw()` flags the global canvas layer for redraw.
// ─────────────────────────────────────────────────────────────────────────────

@propertyWrapper
struct State<Value> {
    private var _value: Value

    init(wrappedValue: Value) { _value = wrappedValue }

    var wrappedValue: Value {
        get { _value }
        set {
            _value = newValue
            PebbleUI._markDirty()
        }
    }

    var projectedValue: Self { self }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - View protocol & result builder
// ─────────────────────────────────────────────────────────────────────────────

// Views mount Pebble layers into `parent` when `mount(in:bounds:)` is called.
// They are value types; the app stores them as static locals.
protocol View {
    func mount(in parent: PebbleLayer, bounds: GRect)
}

// `EmptyView` is the identity element for the builder.
struct EmptyView: View {
    func mount(in parent: PebbleLayer, bounds: GRect) {}
}

// Pair joins two views without heap allocation.
struct TupleView<A: View, B: View>: View {
    let a: A
    let b: B
    func mount(in parent: PebbleLayer, bounds: GRect) {
        a.mount(in: parent, bounds: bounds)
        b.mount(in: parent, bounds: bounds)
    }
}

@resultBuilder
enum ViewBuilder {
    static func buildBlock() -> EmptyView { EmptyView() }
    static func buildBlock<V: View>(_ v: V) -> V { v }
    static func buildBlock<A: View, B: View>(_ a: A, _ b: B) -> TupleView<A,B> {
        TupleView(a: a, b: b)
    }
    static func buildBlock<A: View, B: View, C: View>(
        _ a: A, _ b: B, _ c: C
    ) -> TupleView<TupleView<A,B>,C> {
        TupleView(a: TupleView(a: a, b: b), b: c)
    }
    static func buildBlock<A: View, B: View, C: View, D: View>(
        _ a: A, _ b: B, _ c: C, _ d: D
    ) -> TupleView<TupleView<TupleView<A,B>,C>,D> {
        TupleView(a: TupleView(a: TupleView(a: a, b: b), b: c), b: d)
    }
    static func buildBlock<A: View, B: View, C: View, D: View, E: View>(
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E
    ) -> TupleView<TupleView<TupleView<TupleView<A,B>,C>,D>,E> {
        TupleView(a: TupleView(a: TupleView(a: TupleView(a: a, b: b), b: c), b: d), b: e)
    }
    static func buildBlock<A: View, B: View, C: View, D: View, E: View, F: View>(
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F
    ) -> TupleView<TupleView<TupleView<TupleView<TupleView<A,B>,C>,D>,E>,F> {
        TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: a, b: b), b: c), b: d), b: e), b: f)
    }
    static func buildBlock<A: View, B: View, C: View, D: View, E: View, F: View, G: View>(
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G
    ) -> TupleView<TupleView<TupleView<TupleView<TupleView<TupleView<A,B>,C>,D>,E>,F>,G> {
        TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: a, b: b), b: c), b: d), b: e), b: f), b: g)
    }
    static func buildBlock<A: View, B: View, C: View, D: View, E: View, F: View, G: View, H: View>(
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H
    ) -> TupleView<TupleView<TupleView<TupleView<TupleView<TupleView<TupleView<A,B>,C>,D>,E>,F>,G>,H> {
        TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: a, b: b), b: c), b: d), b: e), b: f), b: g), b: h)
    }
    static func buildBlock<A: View, B: View, C: View, D: View, E: View, F: View, G: View, H: View, I: View>(
        _ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H, _ i: I
    ) -> TupleView<TupleView<TupleView<TupleView<TupleView<TupleView<TupleView<TupleView<A,B>,C>,D>,E>,F>,G>,H>,I> {
        TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: TupleView(a: a, b: b), b: c), b: d), b: e), b: f), b: g), b: h), b: i)
    }
    static func buildIf<V: View>(_ v: V?) -> V? { v }
    static func buildEither<T: View, F: View>(first: T) -> ConditionalView<T, F> {
        ConditionalView(showing: .first(first))
    }
    static func buildEither<T: View, F: View>(second: F) -> ConditionalView<T, F> {
        ConditionalView(showing: .second(second))
    }
}

enum Either<T, F> { case first(T); case second(F) }

struct ConditionalView<T: View, F: View>: View {
    let showing: Either<T, F>
    func mount(in parent: PebbleLayer, bounds: GRect) {
        switch showing {
        case .first(let v):  v.mount(in: parent, bounds: bounds)
        case .second(let v): v.mount(in: parent, bounds: bounds)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PebbleApp protocol
// ─────────────────────────────────────────────────────────────────────────────

protocol PebbleApp {
    associatedtype Body: View
    var backgroundColor: GColor8 { get }
    @ViewBuilder var body: Body { get }
}

extension PebbleApp {
    var backgroundColor: GColor8 { .oxfordBlue }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PebbleUI runner
// ─────────────────────────────────────────────────────────────────────────────

// All mutable runner state is stored in static globals so Embedded Swift's
// lack of heap-allocated existentials is never a problem.

enum PebbleUI {
    static func _markDirty() {
        // Redraws are driven by layer_mark_dirty on specific TextLayer/Layer pointers
        // held by DynamicText.onMount or Canvas views. This hook is available for
        // future @State integration.
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Built-in Views
// ─────────────────────────────────────────────────────────────────────────────

// MARK: Text

struct Text: View {
    // StaticString avoids heap allocation; pass string literals directly.
    // For dynamic content use `DynamicText` below.
    let staticText: UnsafePointer<CChar>?
    var frame:      GRect
    var font:       Font          = .gothic24
    var color:      GColor8       = .white
    var background: GColor8       = .clear
    var alignment:  TextAlignment = .center

    init(_ text: UnsafePointer<CChar>?, frame: GRect) {
        self.staticText = text
        self.frame      = frame
    }

    func font(_ f: Font)              -> Text { var s = self; s.font = f;       return s }
    func foregroundColor(_ c: GColor8) -> Text { var s = self; s.color = c;      return s }
    func multilineTextAlignment(_ a: TextAlignment) -> Text { var s = self; s.alignment = a; return s }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        let layer = text_layer_create(frame)
        text_layer_set_text(layer, staticText)
        text_layer_set_font(layer, font.load())
        text_layer_set_text_color(layer, color)
        text_layer_set_background_color(layer, background)
        text_layer_set_text_alignment(layer, alignment.raw)
        parent.addChild(text_layer_get_layer(layer))
    }
}

// MARK: DynamicText
// For content driven by a mutable CChar buffer (e.g. formatted numbers).
// `bufPtr` must point to static storage that outlives the layer.

struct DynamicText: View {
    let bufPtr:     UnsafePointer<CChar>?
    var frame:      GRect
    var font:       Font          = .gothic24
    var color:      GColor8       = .white
    var background: GColor8       = .clear
    var alignment:  TextAlignment = .center
    // Out-param: caller can receive the created TextLayer pointer to update text later.
    let onMount: (@convention(c) (UnsafeMutablePointer<TextLayer>?) -> Void)?

    init(
        buf: UnsafePointer<CChar>?,
        frame: GRect,
        onMount: (@convention(c) (UnsafeMutablePointer<TextLayer>?) -> Void)? = nil
    ) {
        self.bufPtr   = buf
        self.frame    = frame
        self.onMount  = onMount
    }

    func font(_ f: Font)              -> DynamicText { var s = self; s.font = f;  return s }
    func foregroundColor(_ c: GColor8) -> DynamicText { var s = self; s.color = c; return s }
    func multilineTextAlignment(_ a: TextAlignment) -> DynamicText { var s = self; s.alignment = a; return s }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        let layer = text_layer_create(frame)
        text_layer_set_text(layer, bufPtr)
        text_layer_set_font(layer, font.load())
        text_layer_set_text_color(layer, color)
        text_layer_set_background_color(layer, background)
        text_layer_set_text_alignment(layer, alignment.raw)
        parent.addChild(text_layer_get_layer(layer))
        onMount?(layer)
    }
}

// MARK: Rectangle

struct Rectangle: View {
    var frame:        GRect
    var color:        GColor8    = .white
    var cornerRadius: UInt16     = 0
    var corners:      GCornerMask = GCornerNone

    // Static slots: in Embedded Swift, @convention(c) closures can't capture context,
    // so draw params are written to statics at mount time and read back in the proc.
    private static var _color:        GColor8     = GColorWhite
    private static var _cornerRadius: UInt16      = 0
    private static var _corners:      GCornerMask = GCornerNone

    init(frame: GRect) { self.frame = frame }

    func fill(_ c: GColor8)           -> Rectangle { var s = self; s.color = c;        return s }
    func cornerRadius(_ r: UInt16)    -> Rectangle { var s = self; s.cornerRadius = r;  return s }
    func cornerMask(_ m: GCornerMask) -> Rectangle { var s = self; s.corners = m;       return s }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        Rectangle._color = color; Rectangle._cornerRadius = cornerRadius; Rectangle._corners = corners
        let layer = PebbleLayer(frame: frame)
        layer.setUpdateProc { layerPtr, ctx in
            guard let ctx, let layerPtr else { return }
            let b = layer_get_bounds(layerPtr)
            graphics_context_set_fill_color(ctx, Rectangle._color)
            graphics_fill_rect(ctx, b, Rectangle._cornerRadius, Rectangle._corners)
        }
        parent.addChild(layer)
    }
}

// MARK: Circle

struct Circle: View {
    var center: GPoint
    var radius: UInt16
    var color:  GColor8 = .white

    private static var _radius: UInt16  = 0
    private static var _color:  GColor8 = GColorWhite

    init(center: GPoint, radius: UInt16) {
        self.center = center
        self.radius = radius
    }

    func fill(_ c: GColor8) -> Circle { var s = self; s.color = c; return s }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        Circle._radius = radius; Circle._color = color
        let r = radius
        let frameSize = Int16(r) &* 2
        let frame = makeGRect(
            x: center.x - Int16(r), y: center.y - Int16(r),
            w: frameSize, h: frameSize
        )
        let layer = PebbleLayer(frame: frame)
        layer.setUpdateProc { layerPtr, ctx in
            guard let ctx, let layerPtr else { return }
            let b = layer_get_bounds(layerPtr)
            let localCenter = makeGPoint(x: b.size.w / 2, y: b.size.h / 2)
            graphics_context_set_fill_color(ctx, Circle._color)
            graphics_fill_circle(ctx, localCenter, Circle._radius)
        }
        parent.addChild(layer)
    }
}

// MARK: Divider

struct Divider: View {
    var frame: GRect
    var color: GColor8 = .white

    private static var _color: GColor8 = GColorWhite

    init(frame: GRect) { self.frame = frame }
    func foregroundColor(_ c: GColor8) -> Divider { var s = self; s.color = c; return s }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        Divider._color = color
        let layer = PebbleLayer(frame: frame)
        layer.setUpdateProc { layerPtr, ctx in
            guard let ctx, let layerPtr else { return }
            let b = layer_get_bounds(layerPtr)
            graphics_context_set_fill_color(ctx, Divider._color)
            graphics_fill_rect(ctx, b, 0, GCornerNone)
        }
        parent.addChild(layer)
    }
}

// MARK: Canvas (custom draw)
// Gives you a raw GraphicsContext for fully custom drawing.

struct Canvas: View {
    var frame: GRect
    let draw:  @convention(c) (UnsafeMutablePointer<Layer>?, GContext?) -> Void

    init(frame: GRect, draw: @convention(c) (UnsafeMutablePointer<Layer>?, GContext?) -> Void) {
        self.frame = frame
        self.draw  = draw
    }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        let d = draw
        let layer = PebbleLayer(frame: frame)
        layer.setUpdateProc(d)
        parent.addChild(layer)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Button subscriptions (declarative)
// ─────────────────────────────────────────────────────────────────────────────

// `ButtonHandler` is a pseudo-view that registers click handlers rather
// than mounting a layer. This keeps button wiring inside the `body` block.

struct ButtonHandler: View {
    let button:  Button
    let handler: @convention(c) (UnsafeMutableRawPointer?) -> Void

    init(_ button: Button, action: @convention(c) (UnsafeMutableRawPointer?) -> Void) {
        self.button  = button
        self.handler = action
    }

    func mount(in parent: PebbleLayer, bounds: GRect) {
        // window_single_click_subscribe must be called from within a
        // ClickConfigProvider. PebbleUI defers these until the provider fires.
        PebbleUI._registerButton(button.raw, handler: handler)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Button registration infrastructure
// ─────────────────────────────────────────────────────────────────────────────

// Static table of (ButtonId, ClickHandler) pairs collected during mount.
// The C click-config provider drains this table when the OS calls it.

extension PebbleUI {
    // Up to 4 buttons × 1 handler each.
    private static var _buttonHandlers: (
        (ButtonId, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?),
        (ButtonId, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?),
        (ButtonId, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?),
        (ButtonId, (@convention(c) (UnsafeMutableRawPointer?) -> Void)?)
    ) = (
        (BUTTON_ID_UP,     nil),
        (BUTTON_ID_SELECT, nil),
        (BUTTON_ID_DOWN,   nil),
        (BUTTON_ID_BACK,   nil)
    )

    static func _registerButton(
        _ id: ButtonId,
        handler: @convention(c) (UnsafeMutableRawPointer?) -> Void
    ) {
        if id == BUTTON_ID_UP     { _buttonHandlers.0.1 = handler }
        if id == BUTTON_ID_SELECT { _buttonHandlers.1.1 = handler }
        if id == BUTTON_ID_DOWN   { _buttonHandlers.2.1 = handler }
        if id == BUTTON_ID_BACK   { _buttonHandlers.3.1 = handler }
    }

    // Called from the C-compatible click-config provider below.
    static func _applyButtonHandlers() {
        if let h = _buttonHandlers.0.1 { window_single_click_subscribe(_buttonHandlers.0.0, h) }
        if let h = _buttonHandlers.1.1 { window_single_click_subscribe(_buttonHandlers.1.0, h) }
        if let h = _buttonHandlers.2.1 { window_single_click_subscribe(_buttonHandlers.2.0, h) }
        if let h = _buttonHandlers.3.1 { window_single_click_subscribe(_buttonHandlers.3.0, h) }
    }
}

// The global click-config provider wired up by `PebbleUI.run`.
private let _pebbleUIClickConfigProvider: @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in
    PebbleUI._applyButtonHandlers()
}

// Re-open PebbleUI to expose the full `run` implementation with button wiring.
extension PebbleUI {
    static func run<App: PebbleApp>(app: App) {
        let window = window_create()
        window_set_background_color(window, app.backgroundColor)
        window_set_click_config_provider(window, _pebbleUIClickConfigProvider)

        let rootLayer = PebbleLayer(rawValue: window_get_root_layer(window)!)
        let bounds    = rootLayer.bounds

        // Mount all views — ButtonHandler entries populate _buttonHandlers.
        app.body.mount(in: rootLayer, bounds: bounds)

        window_stack_push(window, true)
        app_event_loop()
        window_destroy(window)
    }
}
