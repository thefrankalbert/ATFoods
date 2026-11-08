import SwiftUI
import DesignSystem

/// Rule-of-thirds grid, plate circle, level bar and a single hint banner.
struct GuidanceOverlay: View {
    let engine: GuidanceEngine

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.72
            ZStack {
                grid
                Circle()
                    .stroke(engine.isReady ? Color.atfSuccess : .white.opacity(0.7),
                            style: StrokeStyle(lineWidth: 2, dash: engine.isReady ? [] : [8, 6]))
                    .frame(width: side, height: side)
                levelBar
                    .offset(y: side / 2 + 28)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.2), value: engine.isReady)
    }

    private var grid: some View {
        GeometryReader { geo in
            Path { p in
                for i in 1...2 {
                    let x = geo.size.width * CGFloat(i) / 3
                    let y = geo.size.height * CGFloat(i) / 3
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: geo.size.height))
                    p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(.white.opacity(0.25), lineWidth: 0.5)
        }
    }

    private var levelBar: some View {
        let level = abs(engine.roll) <= 5
        return Capsule()
            .fill(level ? Color.atfSuccess : .white)
            .frame(width: 90, height: 3)
            .rotationEffect(.degrees(-engine.roll))
    }
}

/// Top banner: one instruction at a time, green "Parfait" when everything is aligned.
struct GuidanceBanner: View {
    let engine: GuidanceEngine

    var body: some View {
        let ready = engine.isReady
        HStack(spacing: 8) {
            Image(systemName: ready ? "checkmark.circle.fill" : "hand.point.up.left.fill")
            Text(engine.hint?.message ?? "Parfait ! Prends la photo")
                .font(.atfCaption)
            Spacer(minLength: 0)
            Text("\(Int(engine.pitch.rounded()))°")
                .font(.atfMono)
                .opacity(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ready ? Color.atfSuccess : Color.black.opacity(0.55), in: Capsule())
        .animation(.easeOut(duration: 0.2), value: engine.hint)
        .accessibilityElement(children: .combine)
    }
}

/// Mode switch: top-down (flat lay) vs 45°.
struct CaptureModePicker: View {
    @Bindable var engine: GuidanceEngine

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CaptureMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) { engine.mode = mode }
                    .font(.atfCaption)
                    .foregroundStyle(engine.mode == mode ? Color.black : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(engine.mode == mode ? Color.white : Color.black.opacity(0.4), in: Capsule())
            }
        }
    }
}
