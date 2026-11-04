import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TemplatesListView()
                .tabItem { Label("Schede", systemImage: "list.bullet.rectangle") }
                .tag(0)
            SessionTabView()
                .tabItem { Label("Sessione", systemImage: "timer") }
                .tag(1)
            HistoryView()
                .tabItem { Label("Storico", systemImage: "chart.bar") }
                .tag(2)
        }
        .task {
            SeedData.insertIfNeeded(into: modelContext)
            SeedExercises.insertIfNeeded(into: modelContext)
            // Se l'app si riapre a metà allenamento, si torna dritti alla sessione.
            let active = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.endedAt == nil })
            if ((try? modelContext.fetchCount(active)) ?? 0) > 0 {
                tab = 1
            }
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
        .modelContainer(for: ReppSchema.models, inMemory: true)
}
