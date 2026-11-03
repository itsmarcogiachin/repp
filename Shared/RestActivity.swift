import Foundation
import ActivityKit
import AppIntents

/// Dati della Live Activity del riposo (schermata di blocco e Dynamic Island).
/// Questo file è compilato sia nell'app sia nell'estensione dei widget.
struct RestActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Inizio e fine del riposo: `startedAt` non supera mai `endsAt`.
        var startedAt: Date
        var endsAt: Date
        /// "Poi serie 3 di Panca piana"
        var nextLabel: String
    }

    var templateName: String
}

/// Preferenze e stato del riposo, condivisi tra la schermata della sessione e i pulsanti della Live Activity.
enum RestSettings {
    static let endsAtKey = "repp.rest.endsAt"
    static let totalKey = "repp.rest.total"
    static let startedAtKey = "repp.rest.startedAt"
    static let nextLabelKey = "repp.rest.nextLabel"
    static let templateKey = "repp.rest.template"

    static let alertsKey = "repp.settings.restAlerts"
    static let liveActivityKey = "repp.settings.liveActivity"
    static let askQualityKey = "repp.settings.askQuality"
    static let defaultRestKey = "repp.settings.defaultRest"
    static let loadStepKey = "repp.settings.loadStep"

    static var defaults: UserDefaults { .standard }

    static var alertsEnabled: Bool { defaults.object(forKey: alertsKey) as? Bool ?? true }
    static var liveActivityEnabled: Bool { defaults.object(forKey: liveActivityKey) as? Bool ?? true }

    /// Riposo predefinito per i nuovi esercizi, in secondi.
    static var defaultRest: Int {
        let value = defaults.integer(forKey: defaultRestKey)
        return value > 0 ? value : 90
    }
}

/// Timer di riposo: salva lo stato, programma la notifica e aggiorna la Live Activity.
enum RestTimer {
    @MainActor
    static func start(seconds: Int, nextLabel: String, templateName: String) async {
        let now = Date.now
        let endsAt = now.addingTimeInterval(TimeInterval(seconds))
        let defaults = RestSettings.defaults
        defaults.set(seconds, forKey: RestSettings.totalKey)
        defaults.set(now.timeIntervalSince1970, forKey: RestSettings.startedAtKey)
        defaults.set(endsAt.timeIntervalSince1970, forKey: RestSettings.endsAtKey)
        defaults.set(nextLabel, forKey: RestSettings.nextLabelKey)
        defaults.set(templateName, forKey: RestSettings.templateKey)
        if RestSettings.alertsEnabled {
            RestNotifier.schedule(at: endsAt, nextSet: nextLabel)
        }
        await RestLiveActivity.show(startedAt: now, endsAt: endsAt, nextLabel: nextLabel, templateName: templateName)
    }

    @MainActor
    static func adjust(by delta: Int) async {
        let defaults = RestSettings.defaults
        let now = Date.now.timeIntervalSince1970
        let current = defaults.double(forKey: RestSettings.endsAtKey)
        guard current > now else { return }
        let endsAt = max(now, current + TimeInterval(delta))
        defaults.set(endsAt, forKey: RestSettings.endsAtKey)
        defaults.set(max(defaults.integer(forKey: RestSettings.totalKey) + delta, 1), forKey: RestSettings.totalKey)
        guard endsAt > now else {
            await skip()
            return
        }
        let nextLabel = defaults.string(forKey: RestSettings.nextLabelKey) ?? ""
        if RestSettings.alertsEnabled {
            RestNotifier.schedule(at: Date(timeIntervalSince1970: endsAt), nextSet: nextLabel)
        }
        let startedAt = min(defaults.double(forKey: RestSettings.startedAtKey), endsAt)
        await RestLiveActivity.update(
            startedAt: Date(timeIntervalSince1970: startedAt),
            endsAt: Date(timeIntervalSince1970: endsAt),
            nextLabel: nextLabel
        )
    }

    @MainActor
    static func skip() async {
        RestSettings.defaults.set(0, forKey: RestSettings.endsAtKey)
        RestNotifier.cancel()
        await RestLiveActivity.end()
    }
}

/// Gestione della Live Activity. L'avvio è possibile solo dall'app, non dall'estensione.
enum RestLiveActivity {
    static func show(startedAt: Date, endsAt: Date, nextLabel: String, templateName: String) async {
        guard RestSettings.liveActivityEnabled else { return }
        let state = RestActivityAttributes.ContentState(startedAt: startedAt, endsAt: endsAt, nextLabel: nextLabel)
        let content = ActivityContent(state: state, staleDate: endsAt)
        if let activity = Activity<RestActivityAttributes>.activities.first {
            await activity.update(content)
            return
        }
        #if !WIDGET_EXTENSION
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        _ = try? Activity.request(attributes: RestActivityAttributes(templateName: templateName), content: content, pushType: nil)
        #endif
    }

    static func update(startedAt: Date, endsAt: Date, nextLabel: String) async {
        let state = RestActivityAttributes.ContentState(startedAt: startedAt, endsAt: endsAt, nextLabel: nextLabel)
        for activity in Activity<RestActivityAttributes>.activities {
            await activity.update(ActivityContent(state: state, staleDate: endsAt))
        }
    }

    static func end() async {
        for activity in Activity<RestActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

/// Pulsante "+15 s" della Live Activity.
struct AddRestTimeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Aggiungi 15 secondi di riposo"

    func perform() async throws -> some IntentResult {
        await RestTimer.adjust(by: 15)
        return .result()
    }
}

/// Pulsante "Salta riposo" della Live Activity.
struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Salta il riposo"

    func perform() async throws -> some IntentResult {
        await RestTimer.skip()
        return .result()
    }
}
