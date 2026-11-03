import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            PlaceholderScreen(title: "Schede", subtitle: "Le tue schede di allenamento")
                .tabItem { Label("Schede", systemImage: "list.bullet.rectangle") }
            PlaceholderScreen(title: "Sessione", subtitle: "L'allenamento in corso")
                .tabItem { Label("Sessione", systemImage: "timer") }
            HistoryPlaceholder()
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
                Text(title)
                    .font(.display(34))
                    .metallic()
                Text(subtitle)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}

/// Mostra che i dati di partenza sono stati caricati.
private struct HistoryPlaceholder: View {
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section("Macchine · \(machines.count)") {
                    ForEach(machines) { Text($0.name) }
                }
                Section("Attrezzi · \(equipment.count)") {
                    ForEach(equipment) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            if let kg = item.weightKg {
                                Text("\(kg, format: .number) kg")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
        .modelContainer(for: ReppSchema.models, inMemory: true)
}
