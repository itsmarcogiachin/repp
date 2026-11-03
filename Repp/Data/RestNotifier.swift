import Foundation
import UserNotifications

/// Notifica locale di fine riposo, utile con il telefono bloccato o l'app in background.
enum RestNotifier {
    private static let identifier = "repp.rest.finished"

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(at date: Date, nextSet: String) {
        cancel()
        let interval = date.timeIntervalSinceNow
        guard interval > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Riposo finito"
        content.body = nextSet
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
