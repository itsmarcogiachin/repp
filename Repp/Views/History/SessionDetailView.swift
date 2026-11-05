import SwiftUI
import SwiftData

/// Dettaglio di un allenamento concluso: esercizi, sostituzioni, macchine, serie con faccine e note del giorno.
struct SessionDetailView: View {
    let session: WorkoutSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false

    private var rows: [SessionExercise] {
        session.orderedExercises.filter { !$0.sets.isEmpty }
    }

    private var header: String {
        let italian = Locale(identifier: "it_IT")
        let day = session.startedAt.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(italian)).capitalizedFirst
        let start = session.startedAt.formatted(.dateTime.hour().minute().locale(italian))
        let end = session.endedAt.map { $0.formatted(.dateTime.hour().minute().locale(italian)) } ?? ""
        let sets = session.allSets.count
        return "\(day) · \(start) – \(end) · \(session.durationText) · \(sets) serie"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.template?.name ?? "Allenamento")
                        .font(.display(32))
                        .metallic()
                    Text(header)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                ForEach(rows) { row in
                    exerciseCard(row)
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Elimina allenamento", role: .destructive) { confirmingDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Altre azioni")
            }
        }
        .confirmationDialog("Eliminare questo allenamento?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Elimina", role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("Spariscono anche le serie e le note di quel giorno. Non si può annullare.")
        }
    }

    private func exerciseCard(_ row: SessionExercise) -> some View {
        let notes = session.notes.filter { $0.exercise?.id == row.exercise?.id }
        return VStack(alignment: .leading, spacing: 10) {
            if let key = row.historyKey {
                NavigationLink(value: key) {
                    HStack {
                        Text(row.exercise?.name ?? "Esercizio")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(Theme.silver)
                    }
                }
                .buttonStyle(.plain)
            }
            if row.isExerciseSubstitution, let planned = row.plannedItem?.exercise {
                Label("Al posto di \(planned.name)", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.pinkText)
            } else if row.isMachineChange {
                Label("Con un'altra macchina o attrezzo rispetto alla scheda", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.pinkText)
            } else if row.plannedItem == nil {
                Text("Aggiunto solo quel giorno")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.pinkText)
            }
            if let setup = row.setupLabel {
                Text(setup)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            if !row.warmupSets.isEmpty {
                Text("Riscaldamento: " + row.orderedWarmupSets.map { "\($0.weightKg.kgString) kg × \($0.reps)" }.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 6) {
                ForEach(row.orderedSets) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .frame(width: 28, alignment: .leading)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(set.weightKg.kgString) kg × \(set.reps)")
                            .font(.subheadline.weight(.semibold))
                            .metallic()
                        Spacer()
                        if let quality = set.quality {
                            QualityFace(quality: quality, size: 20)
                            Text(quality.label)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .monospacedDigit()
                }
            }

            ForEach(notes) { note in
                Text("“\(note.text)”")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
