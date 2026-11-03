import SwiftUI
import SwiftData
import Charts

/// Progressi di un esercizio su una macchina: ogni macchina ha il suo storico, come un esercizio a sé.
struct ExerciseProgressView: View {
    let key: HistoryKey

    @Environment(\.modelContext) private var context
    @State private var machineID: UUID?
    @State private var allRows: [SessionExercise] = []
    @State private var substitutedCount = 0
    @State private var loaded = false

    /// Righe di questo esercizio su questa macchina, dalla più recente.
    private var rows: [SessionExercise] {
        allRows.filter { $0.machine?.id == machineID }
    }

    private var exercise: Exercise? {
        allRows.first?.exercise
    }

    /// Macchine usate con questo esercizio (nil = senza macchina).
    private var machineOptions: [(id: UUID?, name: String)] {
        var seen = Set<UUID?>()
        var result: [(id: UUID?, name: String)] = []
        for row in allRows where !seen.contains(row.machine?.id) {
            seen.insert(row.machine?.id)
            result.append((id: row.machine?.id, name: row.machine?.name ?? "Senza macchina"))
        }
        return result
    }

    private var sets: [SessionSet] { rows.flatMap(\.sets) }

    private var bestSet: SessionSet? {
        sets.max { ($0.weightKg, $0.reps) < ($1.weightKg, $1.reps) }
    }

    /// 1RM stimato con la formula di Epley.
    private var estimatedOneRepMax: Double? {
        sets.map { $0.reps <= 1 ? $0.weightKg : $0.weightKg * (1 + Double($0.reps) / 30) }.max()
    }

    private var points: [(date: Date, kg: Double)] {
        rows.compactMap { row in
            guard let date = row.session?.startedAt, let top = row.sets.map(\.weightKg).max() else { return nil }
            return (date: date, kg: top)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise?.name ?? "Esercizio")
                        .font(.display(30))
                        .metallic()
                    if let group = exercise?.muscleGroup {
                        Text(group)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if machineOptions.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(machineOptions, id: \.id) { option in
                                FilterChip(title: option.name, isSelected: option.id == machineID) {
                                    machineID = option.id
                                }
                            }
                        }
                    }
                    Text("Ogni macchina ha il suo storico, come un esercizio a sé.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 10) {
                    stat("Massimo", bestSet.map { "\($0.weightKg.kgString) kg" } ?? "—", bestSet.map { "× \($0.reps)" })
                    stat("1RM stimato", estimatedOneRepMax.map { "\(Int($0.rounded())) kg" } ?? "—", "formula Epley")
                    stat("Sessioni", "\(rows.count)", points.first.map { "da \($0.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "it_IT"))))" })
                }

                if points.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Carico migliore per sessione")
                        Chart {
                            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                                LineMark(x: .value("Data", point.date), y: .value("Kg", point.kg))
                                    .foregroundStyle(Theme.silver)
                                    .interpolationMethod(.monotone)
                                PointMark(x: .value("Data", point.date), y: .value("Kg", point.kg))
                                    .foregroundStyle(index == points.count - 1 ? Theme.pink : Theme.silver)
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisGridLine().foregroundStyle(Theme.line)
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine().foregroundStyle(Theme.line)
                                AxisValueLabel().foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .frame(height: 180)
                        .environment(\.locale, Locale(identifier: "it_IT"))
                    }
                    .padding(16)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if substitutedCount > 0 {
                    Label(substitutedCount == 1 ? "Sostituito 1 volta negli ultimi 30 giorni" : "Sostituito \(substitutedCount) volte negli ultimi 30 giorni",
                          systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.pinkText)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("Ultime sessioni")
                    ForEach(rows.prefix(10)) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(row.session?.startedAt.shortDay.capitalizedFirst ?? "")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.text)
                                if row.isExerciseSubstitution, let planned = row.plannedItem?.exercise {
                                    Text("al posto di \(planned.name)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.pinkText)
                                }
                                Spacer()
                                Text(row.session?.template?.name ?? "")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Text(row.setsSummary)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func stat(_ title: String, _ value: String, _ detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.display(20, weight: .bold))
                .metallic()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        machineID = key.machineID
        let finished = SessionHistory.finishedRows(in: context)
        allRows = finished.filter { $0.exercise?.id == key.exerciseID }
        let monthAgo = Date.now.addingTimeInterval(-30 * 24 * 3600)
        let substitutedSessions = finished.filter {
            $0.plannedItem?.exercise?.id == key.exerciseID
                && $0.isExerciseSubstitution
                && ($0.session?.startedAt ?? .distantPast) > monthAgo
        }
        substitutedCount = Set(substitutedSessions.compactMap { $0.session?.id }).count
    }
}
