import SwiftUI
import SwiftData

/// Riepilogo a fine allenamento: durata, serie, volume, qualità, cambi rispetto alla scheda e nuovi record.
struct SessionSummaryView: View {
    let session: WorkoutSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var records: [String] = []

    private var rows: [SessionExercise] { session.orderedExercises.filter { !$0.sets.isEmpty } }
    private var allSets: [SessionSet] { rows.flatMap(\.sets) }

    private var durationText: String {
        let minutes = Int((session.endedAt ?? .now).timeIntervalSince(session.startedAt) / 60)
        if minutes >= 60 {
            return "\(minutes / 60) h \(minutes % 60) min"
        }
        return "\(minutes) min"
    }

    private var volumeText: String {
        let volume = allSets.reduce(0) { $0 + $1.weightKg * Double($1.reps) }
        return "\(volume.formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "it_IT")))) kg"
    }

    private var changes: [SessionExercise] {
        rows.filter { $0.isExerciseSubstitution || $0.isMachineChange || $0.plannedItem == nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(session.template?.name ?? "Allenamento") · \(session.startedAt.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "it_IT"))))")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Allenamento completato")
                        .font(.display(32))
                        .metallic()
                }

                HStack(spacing: 10) {
                    stat("Durata", durationText)
                    stat("Serie", "\(allSets.count)")
                    stat("Volume", volumeText)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel("Qualità delle serie")
                    HStack(spacing: 8) {
                        ForEach(SetQuality.allCases) { quality in
                            VStack(spacing: 6) {
                                QualityFace(quality: quality, size: 30)
                                Text("\(allSets.filter { $0.quality == quality }.count)")
                                    .font(.display(20, weight: .bold))
                                    .metallic()
                                Text(quality.label)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }

                if !changes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel("Cambi rispetto alla scheda")
                        ForEach(changes) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.exercise?.name ?? "")
                                    .font(.headline)
                                    .foregroundStyle(Theme.text)
                                Text(changeDetail(row))
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }

                ForEach(records, id: \.self) { record in
                    Label {
                        Text("Nuovo record: ").bold() + Text(record)
                    } icon: {
                        Image(systemName: "trophy.fill").foregroundStyle(Theme.metal)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.pink.opacity(0.6), lineWidth: 1))
                }

                Button("Salva allenamento") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear(perform: findRecords)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.display(20, weight: .bold))
                .metallic()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func changeDetail(_ row: SessionExercise) -> String {
        var parts: [String] = []
        if row.isExerciseSubstitution {
            parts.append("al posto di \(row.plannedItem?.exercise?.name ?? "")")
            if let setup = row.setupLabel { parts.append(setup) }
        } else if row.isMachineChange {
            parts.append("su \(row.machine?.name ?? "nessuna macchina") invece che \(row.plannedItem?.machine?.name ?? "senza macchina")")
        } else {
            parts.append("aggiunto solo per oggi")
        }
        parts.append(row.setsSummary)
        return parts.joined(separator: " · ")
    }

    /// Record: carico più alto di sempre per esercizio + macchina, solo se c'era già uno storico.
    private func findRecords() {
        var result: [String] = []
        for row in rows {
            guard let key = row.historyKey,
                  let previousBest = SessionHistory.bestWeight(of: key, in: context, excluding: session),
                  let top = row.sets.max(by: { $0.weightKg < $1.weightKg }),
                  top.weightKg > previousBest else { continue }
            result.append("\(row.exercise?.name ?? "") \(top.weightKg.kgString) kg × \(top.reps)")
        }
        records = result
    }
}
