import SwiftUI
import SwiftData

/// Modifica di una scheda: nome, esercizi con obiettivi, ordine, macchina e attrezzo predefiniti.
struct TemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var template: WorkoutTemplate
    @State private var expandedID: UUID?
    @State private var showingPicker = false
    @State private var confirmingDelete = false

    var body: some View {
        List {
            Section {
                TextField("Nome scheda", text: $template.name)
                    .font(.display(22, weight: .bold))
                    .listRowBackground(Theme.surface)
            } header: {
                SectionLabel("Nome scheda")
            }

            Section {
                ForEach(template.orderedItems) { item in
                    TemplateItemRow(item: item, isExpanded: expandedID == item.id) {
                        withAnimation(.snappy) {
                            expandedID = expandedID == item.id ? nil : item.id
                        }
                    }
                    .listRowBackground(Theme.surface)
                }
                .onMove(perform: move)
                .onDelete(perform: delete)

                Button {
                    showingPicker = true
                } label: {
                    Label("Aggiungi esercizio", systemImage: "plus")
                        .foregroundStyle(Theme.silver)
                }
                .listRowBackground(Theme.surface)
            } header: {
                SectionLabel("Esercizi")
            } footer: {
                Text("Tocca un esercizio per modificarlo. Usa Modifica per cambiare l'ordine o eliminarlo.")
            }

            Section {
                Button("Elimina scheda", role: .destructive) {
                    confirmingDelete = true
                }
                .listRowBackground(Theme.surface)
            }
        }
        .reppListStyle()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(template.name.isEmpty ? "Scheda" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView(alreadyInTemplate: Set(template.items.compactMap { $0.exercise?.id })) { exercises in
                add(exercises)
            }
        }
        .confirmationDialog("Eliminare la scheda?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Elimina", role: .destructive) {
                template.isArchived = true
                // Chiamato subito, dismiss chiuderebbe il dialogo invece di tornare all'elenco.
                DispatchQueue.main.async { dismiss() }
            }
        } message: {
            Text("Le sessioni già fatte con questa scheda restano nello storico.")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            EditButton()
        }
        // Il tastierino del carico non ha un tasto Invio: serve un modo per chiuderlo.
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Fine") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }

    private func add(_ exercises: [Exercise]) {
        var position = (template.items.map(\.position).max() ?? -1) + 1
        for exercise in exercises {
            let item = TemplateExercise(position: position, restSeconds: RestSettings.defaultRest)
            context.insert(item)
            item.configure(exercise: exercise, template: template)
            position += 1
        }
        if let first = template.orderedItems.last, exercises.count == 1 {
            expandedID = first.id
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var items = template.orderedItems
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.position = index
        }
    }

    private func delete(at offsets: IndexSet) {
        let items = template.orderedItems
        let remaining = items.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        for index in offsets {
            context.delete(items[index])
        }
        for (index, item) in remaining.enumerated() {
            item.position = index
        }
    }
}

/// Riga di un esercizio nella scheda; aperta mostra i controlli per serie, ripetizioni, carico, riposo, macchina e attrezzo.
private struct TemplateItemRow: View {
    @Bindable var item: TemplateExercise
    let isExpanded: Bool
    let toggle: () -> Void

    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.exercise?.name ?? "Esercizio")
                            .font(.headline)
                            .foregroundStyle(isExpanded ? AnyShapeStyle(Theme.metal) : AnyShapeStyle(Theme.text))
                        Text(item.summary)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    GroupBadge(item.exercise?.muscleGroup)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 16) {
                    Stepper("Serie: \(item.targetSets)", value: $item.targetSets, in: 1...10)
                    Stepper("Ripetizioni: \(item.targetReps ?? 0)", value: repsBinding, in: 1...50)
                    HStack {
                        Text("Carico (kg)")
                        Spacer()
                        TextField("kg", value: $item.targetWeightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 10))
                    }
                    Stepper("Riposo: \(item.restSeconds.restString)", value: $item.restSeconds, in: 15...600, step: 15)
                    Picker("Macchina", selection: $item.machine) {
                        Text("Nessuna").tag(Machine?.none)
                        ForEach(machines) { machine in
                            Text(machine.name).tag(Optional(machine))
                        }
                    }
                    Picker("Attrezzo", selection: $item.equipment) {
                        Text("Nessuno").tag(Equipment?.none)
                        ForEach(equipment) { tool in
                            Text(tool.label).tag(Optional(tool))
                        }
                    }
                }
                .font(.subheadline)
                .tint(Theme.pink)
            }
        }
        .padding(.vertical, 4)
    }

    private var repsBinding: Binding<Int> {
        Binding(
            get: { item.targetReps ?? 8 },
            set: { item.targetReps = $0 }
        )
    }
}
