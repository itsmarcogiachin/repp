import SwiftUI
import SwiftData

/// Catalogo esercizi: ricerca, filtro per gruppo muscolare, selezione multipla e creazione di un esercizio nuovo.
struct ExercisePickerView: View {
    let alreadyInTemplate: Set<UUID>
    let onAdd: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var group: String?
    @State private var selected: [Exercise] = []
    @State private var showingNew = false

    private var filtered: [Exercise] {
        exercises.filter { exercise in
            (group == nil || exercise.muscleGroup == group)
                && (search.isEmpty || exercise.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "Tutti", isSelected: group == nil) { group = nil }
                            ForEach(MuscleGroup.all, id: \.self) { name in
                                FilterChip(title: name, isSelected: group == name) { group = name }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label("Nessun esercizio", systemImage: "dumbbell")
                    } description: {
                        Text(exercises.isEmpty ? "Il catalogo è vuoto. Crea il primo esercizio con Crea nuovo." : "Nessun esercizio corrisponde alla ricerca.")
                    } actions: {
                        Button("Crea nuovo") { showingNew = true }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered) { exercise in
                        Button {
                            toggle(exercise)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .foregroundStyle(Theme.text)
                                    Text(subtitle(for: exercise))
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: isSelected(exercise) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected(exercise) ? Theme.pink : Theme.silver)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected(exercise) ? .isSelected : [])
                        .listRowBackground(Theme.surface)
                    }
                }
            }
            .reppListStyle()
            .searchable(text: $search, prompt: "Cerca esercizio")
            .navigationTitle("Aggiungi esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Crea nuovo") { showingNew = true }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty {
                    Button("Aggiungi \(selected.count) \(selected.count == 1 ? "esercizio" : "esercizi")") {
                        onAdd(selected)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.background)
                }
            }
            .sheet(isPresented: $showingNew) {
                NewExerciseView(initialGroup: group) { exercise in
                    selected.append(exercise)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func isSelected(_ exercise: Exercise) -> Bool {
        selected.contains { $0.id == exercise.id }
    }

    private func toggle(_ exercise: Exercise) {
        if let index = selected.firstIndex(where: { $0.id == exercise.id }) {
            selected.remove(at: index)
        } else {
            selected.append(exercise)
        }
    }

    private func subtitle(for exercise: Exercise) -> String {
        if alreadyInTemplate.contains(exercise.id) {
            return "Già nella scheda"
        }
        let parts = [exercise.muscleGroup, exercise.defaultMachine?.name ?? exercise.defaultEquipment?.name].compactMap { $0 }
        return parts.isEmpty ? " " : parts.joined(separator: " · ")
    }
}

/// Creazione di un esercizio nel catalogo, con macchina e attrezzo predefiniti facoltativi.
struct NewExerciseView: View {
    var initialGroup: String?
    let onCreate: (Exercise) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @State private var name = ""
    @State private var group = MuscleGroup.all[0]
    @State private var machine: Machine?
    @State private var tool: Equipment?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Es. Panca piana bilanciere", text: $name)
                } header: {
                    Text("Nome")
                }
                Section {
                    Picker("Gruppo muscolare", selection: $group) {
                        ForEach(MuscleGroup.all, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Macchina predefinita", selection: $machine) {
                        Text("Nessuna").tag(Machine?.none)
                        ForEach(machines) { Text($0.name).tag(Optional($0)) }
                    }
                    Picker("Attrezzo predefinito", selection: $tool) {
                        Text("Nessuno").tag(Equipment?.none)
                        ForEach(equipment) { Text($0.label).tag(Optional($0)) }
                    }
                } footer: {
                    Text("Macchina e attrezzo si possono cambiare in ogni scheda e, solo per una volta, durante la sessione.")
                }
            }
            .reppListStyle()
            .navigationTitle("Nuovo esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                if let initialGroup { group = initialGroup }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let exercise = Exercise(name: trimmedName, muscleGroup: group)
        context.insert(exercise)
        exercise.defaultMachine = machine
        exercise.defaultEquipment = tool
        onCreate(exercise)
        dismiss()
    }
}
