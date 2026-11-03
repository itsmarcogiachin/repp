import SwiftUI
import SwiftData

/// Tab "Sessione": se c'è un allenamento in corso lo mostra, altrimenti fa scegliere la scheda da iniziare.
struct SessionTabView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt == nil }, sort: \WorkoutSession.startedAt, order: .reverse)
    private var activeSessions: [WorkoutSession]
    @Query(filter: #Predicate<WorkoutTemplate> { !$0.isArchived }, sort: \WorkoutTemplate.position)
    private var templates: [WorkoutTemplate]
    @State private var finishedSession: WorkoutSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSessions.first {
                    ActiveSessionView(session: session) { ended in
                        finishedSession = ended
                    }
                } else {
                    startScreen
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $finishedSession) { session in
            SessionSummaryView(session: session)
        }
    }

    private var startScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenTitle("Sessione")
                Text("Scegli la scheda da fare oggi.")
                    .foregroundStyle(Theme.textSecondary)

                if templates.isEmpty {
                    Text("Non hai ancora schede. Creane una nella tab Schede.")
                        .foregroundStyle(Theme.textSecondary)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                ForEach(templates) { template in
                    let items = template.orderedItems
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template.name)
                            .font(.display(22, weight: .bold))
                            .metallic()
                        Text(items.isEmpty ? "Nessun esercizio" : items.compactMap { $0.exercise?.name }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                        Button("Inizia") { start(template) }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(items.isEmpty)
                            .opacity(items.isEmpty ? 0.4 : 1)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(20)
        }
    }

    private func start(_ template: WorkoutTemplate) {
        RestNotifier.requestAuthorization()
        let session = WorkoutSession()
        context.insert(session)
        session.template = template
        for item in template.orderedItems {
            guard let exercise = item.exercise else { continue }
            let row = SessionExercise(position: item.position)
            context.insert(row)
            row.configure(session: session, plannedItem: item, exercise: exercise, machine: item.machine, equipment: item.equipment)
        }
        try? context.save()
    }
}
