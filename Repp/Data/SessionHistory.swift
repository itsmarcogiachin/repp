import Foundation
import SwiftData

/// Letture dello storico usate durante la sessione. I dati sono pochi (un solo utente), quindi si filtra in memoria.
enum SessionHistory {
    /// Tutte le righe di sessioni concluse, dalla più recente.
    static func finishedRows(in context: ModelContext) -> [SessionExercise] {
        let rows = (try? context.fetch(FetchDescriptor<SessionExercise>())) ?? []
        return rows
            .filter { $0.session?.endedAt != nil && !$0.sets.isEmpty }
            .sorted { ($0.session?.startedAt ?? .distantPast) > ($1.session?.startedAt ?? .distantPast) }
    }

    /// Cosa è successo a questo esercizio della scheda l'ultima volta che la scheda è stata fatta.
    /// Può essere più di una riga se a metà esercizio era stato sostituito.
    static func lastTime(for item: TemplateExercise, excluding session: WorkoutSession) -> (date: Date, rows: [SessionExercise])? {
        let rows = item.sessionRows.filter { row in
            guard let rowSession = row.session else { return false }
            return rowSession.endedAt != nil && rowSession.id != session.id && !row.sets.isEmpty
        }
        guard let latest = rows.compactMap(\.session).max(by: { $0.startedAt < $1.startedAt }) else { return nil }
        let sameSession = rows
            .filter { $0.session?.id == latest.id }
            .sorted { $0.position < $1.position }
        return (latest.startedAt, sameSession)
    }

    /// L'ultima volta che questo esercizio è stato fatto su questa macchina (lo storico è separato per macchina).
    static func lastPerformance(of key: HistoryKey, in context: ModelContext, excluding session: WorkoutSession) -> SessionExercise? {
        finishedRows(in: context).first { $0.historyKey == key && $0.session?.id != session.id }
    }

    /// Carico massimo mai usato con questo esercizio su questa macchina, sessione in corso esclusa.
    static func bestWeight(of key: HistoryKey, in context: ModelContext, excluding session: WorkoutSession) -> Double? {
        finishedRows(in: context)
            .filter { $0.historyKey == key && $0.session?.id != session.id }
            .flatMap(\.sets)
            .map(\.weightKg)
            .max()
    }

    /// Esercizi già usati al posto di questo, il più recente per ogni esercizio + macchina.
    static func pastSubstitutes(for exercise: Exercise, in context: ModelContext) -> [SessionExercise] {
        var seen = Set<HistoryKey>()
        return finishedRows(in: context).filter { row in
            guard row.plannedItem?.exercise?.id == exercise.id,
                  row.isExerciseSubstitution,
                  let key = row.historyKey,
                  !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}

extension SessionExercise {
    /// "3 serie · 80 kg × 8" se le serie sono uguali, altrimenti "2 serie · 62,5 kg × 10, 65 kg × 9".
    var setsSummary: String {
        let ordered = orderedSets
        let label = ordered.count == 1 ? "1 serie" : "\(ordered.count) serie"
        guard let first = ordered.first else { return label }
        if ordered.allSatisfy({ $0.weightKg == first.weightKg && $0.reps == first.reps }) {
            return "\(label) · \(first.weightKg.kgString) kg × \(first.reps)"
        }
        let detail = ordered.prefix(5).map { "\($0.weightKg.kgString) kg × \($0.reps)" }.joined(separator: ", ")
        return "\(label) · \(detail)\(ordered.count > 5 ? "…" : "")"
    }

    /// "Panca · Bilanciere olimpico"
    var setupLabel: String? {
        let parts = [machine?.name, equipment?.name].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var targetSets: Int {
        plannedItem?.targetSets ?? 3
    }

    var restSeconds: Int {
        plannedItem?.restSeconds ?? RestSettings.defaultRest
    }
}

extension Date {
    /// "ven 30 ott"
    var shortDay: String {
        formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "it_IT")))
    }
}
