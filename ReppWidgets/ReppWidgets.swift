import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

@main
struct ReppWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RestLiveActivityWidget()
    }
}

/// Timer di riposo sulla schermata di blocco e nella Dynamic Island.
struct RestLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            RestLockScreenView(context: context)
                .activityBackgroundTint(WidgetTheme.background)
                .activitySystemActionForegroundColor(WidgetTheme.silver)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Riposo", systemImage: "timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetTheme.silver)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RestCountdown(state: context.state, isStale: context.isStale)
                        .font(.system(size: 28, weight: .heavy).monospacedDigit())
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.nextLabel)
                            .font(.caption)
                            .foregroundStyle(WidgetTheme.secondary)
                            .lineLimit(1)
                        RestButtons()
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(WidgetTheme.pink)
            } compactTrailing: {
                RestCountdown(state: context.state, isStale: context.isStale)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(WidgetTheme.pink)
            }
            .keylineTint(WidgetTheme.pink)
        }
    }
}

private struct RestLockScreenView: View {
    let context: ActivityViewContext<RestActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Repp · Riposo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetTheme.metal)
                Spacer()
                Text(context.attributes.templateName)
                    .font(.caption)
                    .foregroundStyle(WidgetTheme.secondary)
            }
            HStack(alignment: .center) {
                RestCountdown(state: context.state, isStale: context.isStale)
                    .font(.system(size: 44, weight: .heavy).monospacedDigit())
                Spacer()
                RestButtons()
                    .frame(maxWidth: 190)
            }
            Text(context.state.nextLabel)
                .font(.subheadline)
                .foregroundStyle(WidgetTheme.text)
                .lineLimit(1)
        }
        .padding(16)
    }
}

/// Conto alla rovescia aggiornato dal sistema, anche con l'app chiusa.
private struct RestCountdown: View {
    let state: RestActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if isStale || state.endsAt <= .now {
            Text("Via!")
                .foregroundStyle(WidgetTheme.pink)
        } else {
            Text(timerInterval: min(state.startedAt, state.endsAt)...state.endsAt, countsDown: true)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(WidgetTheme.metal)
        }
    }
}

private struct RestButtons: View {
    var body: some View {
        HStack(spacing: 8) {
            Button(intent: AddRestTimeIntent()) {
                Text("+15 s")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .tint(WidgetTheme.surface)
            Button(intent: SkipRestIntent()) {
                Text("Salta riposo")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .tint(WidgetTheme.pink)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
    }
}

/// Colori del brand per l'estensione (l'estensione non vede Theme dell'app).
enum WidgetTheme {
    static let background = Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0B / 255)
    static let surface = Color(red: 0x23 / 255, green: 0x23 / 255, blue: 0x27 / 255)
    static let text = Color(red: 0xF5 / 255, green: 0xF3 / 255, blue: 0xF4 / 255)
    static let secondary = Color(red: 0xA8 / 255, green: 0xA8 / 255, blue: 0xB0 / 255)
    static let pink = Color(red: 0xFF / 255, green: 0x4F / 255, blue: 0x9A / 255)
    static let silver = Color(red: 0xC9 / 255, green: 0xCC / 255, blue: 0xD3 / 255)
    static let metal = LinearGradient(
        colors: [
            Color(red: 0xF4 / 255, green: 0xF5 / 255, blue: 0xF7 / 255),
            Color(red: 0xA9 / 255, green: 0xAD / 255, blue: 0xB5 / 255),
            Color(red: 0xE6 / 255, green: 0xE8 / 255, blue: 0xEC / 255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
