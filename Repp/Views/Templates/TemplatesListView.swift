import SwiftUI
import SwiftData

/// Tab "Schede": elenco delle schede, creazione e accesso alle impostazioni.
struct TemplatesListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WorkoutTemplate> { !$0.isArchived }, sort: \WorkoutTemplate.position)
    private var templates: [WorkoutTemplate]
    @State private var path: [WorkoutTemplate] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if templates.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(templates) { template in
                                NavigationLink(value: template) {
                                    TemplateCard(template: template)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: WorkoutTemplate.self) { template in
                TemplateEditorView(template: template)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            ScreenTitle("Schede")
            Spacer()
            NavigationLink {
                MachinesEquipmentView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(Theme.silver)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Theme.line, lineWidth: 1))
            }
            .accessibilityLabel("Impostazioni")
            Button(action: addTemplate) {
                Label("Nuova", systemImage: "plus")
            }
            .buttonStyle(PillButtonStyle())
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nessuna scheda")
                .font(.display(22, weight: .bold))
                .metallic()
            Text("Crea la tua prima scheda: dalle un nome e aggiungi gli esercizi con serie, ripetizioni, carico e riposo.")
                .foregroundStyle(Theme.textSecondary)
            Button("Crea una scheda", action: addTemplate)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func addTemplate() {
        let nextPosition = (templates.map(\.position).max() ?? -1) + 1
        let template = WorkoutTemplate(name: "Nuova scheda", position: nextPosition)
        context.insert(template)
        path.append(template)
    }
}

private struct TemplateCard: View {
    let template: WorkoutTemplate

    var body: some View {
        let items = template.orderedItems
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.display(20, weight: .bold))
                    .metallic()
                Text(items.isEmpty ? "Nessun esercizio" : "\(items.count) \(items.count == 1 ? "esercizio" : "esercizi")")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                if !items.isEmpty {
                    Text(items.prefix(3).compactMap { $0.exercise?.name }.joined(separator: " · "))
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
    }
}
