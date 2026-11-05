import SwiftUI

/// Titolo grande in argento metallico.
struct ScreenTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.display(34))
            .metallic()
    }
}

/// Etichetta di sezione in maiuscoletto grigio.
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1)
            .foregroundStyle(Theme.textSecondary)
    }
}

/// Pulsante principale rosa, alto 56 pt.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.display(18))
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                Theme.pink.opacity(configuration.isPressed ? 0.8 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }
}

/// Pulsante a pillola rosa, per azioni in alto ("Nuova").
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.background)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Theme.pink.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
    }
}

/// Chip selezionabile: argento quando attivo.
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .foregroundStyle(isSelected ? Theme.background : Theme.text)
                .background {
                    if isSelected {
                        Capsule().fill(Theme.metal)
                    } else {
                        Capsule().fill(Theme.surface)
                            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension View {
    /// Sfondo standard delle liste: nero con righe grafite.
    func reppListStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}

extension Double {
    /// 80 → "80", 77.5 → "77,5", 1.25 → "1,25" (dischi da 1,25 kg)
    var kgString: String {
        formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
}

extension Int {
    /// 90 → "1:30"
    var restString: String {
        String(format: "%d:%02d", self / 60, self % 60)
    }
}

/// Gruppi muscolari: ogni esercizio ne ha uno solo.
enum MuscleGroup {
    static let all = ["Petto", "Schiena", "Spalle", "Bicipiti", "Tricipiti", "Gambe"]
}

/// Piccolo badge con il gruppo muscolare dell'esercizio.
struct GroupBadge: View {
    let group: String?

    init(_ group: String?) {
        self.group = group
    }

    var body: some View {
        if let group, !group.isEmpty {
            Text(group)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.silver)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.surface2, in: Capsule())
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                .fixedSize()
        }
    }
}

extension Equipment {
    /// "Bilanciere olimpico · 20 kg"
    var label: String {
        if let weightKg {
            return "\(name) · \(weightKg.kgString) kg"
        }
        return name
    }
}

extension TemplateExercise {
    /// "4 × 8 · 80 kg · riposo 1:30 · Panca · Bilanciere olimpico"
    var summary: String {
        var parts: [String] = []
        if let targetReps {
            parts.append("\(targetSets) × \(targetReps)")
        } else {
            parts.append("\(targetSets) serie")
        }
        if let targetWeightKg {
            parts.append("\(targetWeightKg.kgString) kg")
        }
        parts.append("riposo \(restSeconds.restString)")
        if let machine {
            parts.append(machine.name)
        }
        if let equipment {
            parts.append(equipment.name)
        }
        return parts.joined(separator: " · ")
    }
}
