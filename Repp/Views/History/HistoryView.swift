import SwiftUI
import SwiftData

/// Tab "Storico": settimana, esercizi con i progressi e tutte le sessioni concluse.
struct HistoryView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenTitle("Storico")

                    if sessions.isEmpty {
                        Text("Qui trovi gli allenamenti conclusi, con i carichi e i progressi di ogni esercizio. Inizia una sessione dalla tab Sessione.")
                            .foregroundStyle(Theme.textSecondary)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        WeekCard(sessions: sessions)
                        exercisesSection
                        sessionsSection
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session)
            }
            .navigationDestination(for: HistoryKey.self) { key in
                ExerciseProgressView(key: key)
            }
        }
    }

    /// Un elemento per esercizio + macchina, dal più recente.
    private var exerciseEntries: [(key: HistoryKey, title: String, detail: String)] {
        var seen = Set<HistoryKey>()
        var result: [(HistoryKey, String, String)] = []
        for session in sessions {
            for row in session.orderedExercises where !row.sets.isEmpty {
                guard let key = row.historyKey, !seen.contains(key) else { continue }
                seen.insert(key)
                let best = allRows(for: key).flatMap(\.sets).map(\.weightKg).max() ?? 0
                let machine = row.machine?.name ?? "senza macchina"
                result.append((key, row.exercise?.name ?? "Esercizio", "\(machine) · migliore \(best.kgString) kg"))
            }
        }
        return result.map { (key: $0.0, title: $0.1, detail: $0.2) }
    }

    private func allRows(for key: HistoryKey) -> [SessionExercise] {
        sessions.flatMap(\.exercises).filter { $0.historyKey == key }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Esercizi")
            VStack(spacing: 0) {
                ForEach(Array(exerciseEntries.enumerated()), id: \.element.key) { index, entry in
                    NavigationLink(value: entry.key) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .foregroundStyle(Theme.text)
                                Text(entry.detail)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(Theme.silver)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < exerciseEntries.count - 1 {
                        Divider().overlay(Theme.line).padding(.leading, 16)
                    }
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Sessioni")
            ForEach(sessions) { session in
                NavigationLink(value: session) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.template?.name ?? "Allenamento")
                                .font(.display(20, weight: .bold))
                                .metallic()
                            Text(session.meta)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Text(session.durationText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.silver)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// La settimana in corso, da lunedì a domenica, con i giorni di allenamento in argento.
private struct WeekCard: View {
    let sessions: [WorkoutSession]

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.locale = Locale(identifier: "it_IT")
        return calendar
    }

    private var days: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    private func trained(on day: Date) -> Bool {
        sessions.contains { calendar.isDate($0.startedAt, inSameDayAs: day) }
    }

    var body: some View {
        let count = days.filter(trained(on:)).count
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionLabel("Questa settimana")
                Spacer()
                Text(count == 1 ? "1 allenamento" : "\(count) allenamenti")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
            }
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let isTrained = trained(on: day)
                    let isToday = calendar.isDateInToday(day)
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.narrow).locale(Locale(identifier: "it_IT"))))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(calendar.component(.day, from: day))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isTrained ? Theme.background : Theme.text)
                            .frame(width: 36, height: 36)
                            .background {
                                if isTrained {
                                    Circle().fill(Theme.metal)
                                } else {
                                    Circle().fill(Theme.surface2)
                                }
                            }
                            .overlay {
                                if isToday {
                                    Circle().stroke(Theme.pink, lineWidth: 2)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension WorkoutSession {
    var allSets: [SessionSet] {
        exercises.flatMap(\.sets)
    }

    var durationText: String {
        let minutes = Int(((endedAt ?? .now).timeIntervalSince(startedAt) / 60).rounded())
        if minutes >= 60 {
            return "\(minutes / 60) h \(minutes % 60) min"
        }
        return "\(minutes) min"
    }

    /// "Lun 2 nov · 5 esercizi · 16 serie · 1 sostituzione"
    var meta: String {
        let rows = exercises.filter { !$0.sets.isEmpty }
        let setCount = rows.reduce(0) { $0 + $1.sets.count }
        let changes = rows.filter { $0.isExerciseSubstitution || $0.isMachineChange }.count
        var parts = [
            startedAt.shortDay.capitalizedFirst,
            rows.count == 1 ? "1 esercizio" : "\(rows.count) esercizi",
            setCount == 1 ? "1 serie" : "\(setCount) serie"
        ]
        if changes > 0 {
            parts.append(changes == 1 ? "1 sostituzione" : "\(changes) sostituzioni")
        }
        return parts.joined(separator: " · ")
    }
}
