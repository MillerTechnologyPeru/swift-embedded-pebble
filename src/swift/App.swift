// App.swift
// Counter app rewritten with PebbleUI — SwiftUI-style declarative API.
import PebbleSDK

// MARK: - App state (static storage, Embedded Swift constraint)

private var sCounter:    Int32 = 0
private var sCounterBuf = InlineArray<8, CChar>(repeating: 0)
private var sCountLayer: UnsafeMutablePointer<TextLayer>? = nil

private func updateDisplay() {
    formatCounter(sCounter, into: &sCounterBuf)
    withUnsafeBytes(of: &sCounterBuf) { raw in
        if let layer = sCountLayer {
            text_layer_set_text(layer, raw.baseAddress?.assumingMemoryBound(to: CChar.self))
            layer_mark_dirty(text_layer_get_layer(layer))
        }
    }
}

// @convention(c) callbacks — capturing only static globals is legal in Embedded Swift.
private let onUp:     @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in sCounter &+= 1; updateDisplay() }
private let onSelect: @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in sCounter  = 0;  updateDisplay() }
private let onDown:   @convention(c) (UnsafeMutableRawPointer?) -> Void = { _ in sCounter &-= 1; updateDisplay() }
private let onMount:  @convention(c) (UnsafeMutablePointer<TextLayer>?) -> Void = { sCountLayer = $0; updateDisplay() }

// MARK: - Counter screen

struct CounterApp: PebbleApp {
    var backgroundColor: GColor8 { .oxfordBlue }

    var body: some View {
        Text("Hello from", frame: makeGRect(x: 0, y: 20, w: 200, h: 50))
            .font(.gothic28Bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        // Swift logo (bundled transparent PNG) — replaces the old "Swift!" text.
        // The white-wordmark variant reads against the dark background, so the
        // image is drawn with transparency (GCompOpSet) and no backing card.
        Image(resourceID: swift_resource_id_swift_logo(),
              frame: makeGRect(x: 6, y: 52, w: 188, h: 64))

        Divider(frame: makeGRect(x: 10, y: 110, w: 180, h: 2))

        Text("Counter", frame: makeGRect(x: 0, y: 122, w: 200, h: 28))
            .font(.gothic24)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        DynamicText(buf: nil, frame: makeGRect(x: 0, y: 150, w: 200, h: 56), onMount: onMount)
            .font(.bitham42Bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        Text("UP +1  |  SEL 0  |  DN -1", frame: makeGRect(x: 0, y: 210, w: 200, h: 18))
            .font(.gothic14)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

        ButtonHandler(.up,     action: onUp)
        ButtonHandler(.select, action: onSelect)
        ButtonHandler(.down,   action: onDown)
    }
}

// MARK: - Entry point

@_silgen_name("swift_app_init")
public func swiftAppInit() {
    formatCounter(sCounter, into: &sCounterBuf)
    PebbleUI.run(app: CounterApp())
}
