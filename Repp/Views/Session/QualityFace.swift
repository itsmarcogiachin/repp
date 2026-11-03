import SwiftUI

/// Faccina disegnata (non emoji) per la qualità di una serie.
struct QualityFace: View {
    let quality: SetQuality
    var size: CGFloat = 28
    var color: Color = Theme.silver

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let line = max(1.5, s * 0.07)
            let style = StrokeStyle(lineWidth: line, lineCap: .round)
            let shading = GraphicsContext.Shading.color(color)

            let inset = line / 2
            context.stroke(Path(ellipseIn: CGRect(x: inset, y: inset, width: s - line, height: s - line)), with: shading, style: style)

            let eyeRadius = s * 0.055
            for x in [s * 0.36, s * 0.64] {
                context.fill(Path(ellipseIn: CGRect(x: x - eyeRadius, y: s * 0.38 - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2)), with: shading)
            }

            // Bocca: la curva va dal sorriso ampio (ottima) alla smorfia (bassa).
            let curve: CGFloat
            switch quality {
            case .ottima: curve = 0.18
            case .buona: curve = 0.09
            case .media: curve = 0
            case .bassa: curve = -0.10
            }
            let mouthY = s * (curve < 0 ? 0.70 : 0.62)
            var mouth = Path()
            mouth.move(to: CGPoint(x: s * 0.32, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: s * 0.68, y: mouthY), control: CGPoint(x: s * 0.5, y: mouthY + s * curve * 2))
            context.stroke(mouth, with: shading, style: style)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(quality.label)
    }
}

/// Scelta della qualità dopo una serie: quattro faccine con etichetta.
struct QualityPicker: View {
    let selected: SetQuality?
    let onSelect: (SetQuality) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SetQuality.allCases) { quality in
                let isSelected = selected == quality
                Button {
                    onSelect(quality)
                } label: {
                    VStack(spacing: 6) {
                        QualityFace(quality: quality, size: 34, color: isSelected ? Theme.background : Theme.silver)
                        Text(quality.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? Theme.background : Theme.text)
                    }
                    .frame(maxWidth: .infinity, minHeight: 74)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? AnyShapeStyle(Theme.metal) : AnyShapeStyle(Theme.surface2))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack { ForEach(SetQuality.allCases) { QualityFace(quality: $0, size: 44) } }
        QualityPicker(selected: .buona) { _ in }
    }
    .padding()
    .background(Theme.background)
}
