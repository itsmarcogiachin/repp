import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TemplatesListView()
                .tabItem { Label("Schede", systemImage: "list.bullet.rectangle") }
            SessionTabView()
                .tabItem { Label("Sessione", systemImage: "timer") }
            PlaceholderScreen(title: "Storico", subtitle: "Le tue sessioni e i progressi")
                .tabItem { Label("Storico", systemImage: "chart.bar") }
        }
        .task {
            SeedData.insertIfNeeded(into: modelContext)
        }
    }
}

/// Schermata provvisoria: verrà sostituita dalle schermate del mockup.
private struct PlaceholderScreen: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                ScreenTitle(title)
                Text(subtitle)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
        .modelContainer(for: ReppSchema.models, inMemory: true)
}
