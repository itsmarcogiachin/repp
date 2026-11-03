import SwiftUI
import SwiftData

// MARK: - Sostituisci per oggi

/// Sostituisce l'esercizio solo per questa sessione: la scheda non cambia.
struct SubstituteSheet: View {
    let row: SessionExercise
    let onChoose: (Exercise) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var selected: Exercise?
    @State private var search = ""
    @State private var showingNew = false
    @State private var pastSubstitutes: [SessionExercise] = []

    private var original: Exercise? { row.plannedItem?.exercise }

    private var pastIDs: Set<UUID> {
        Set(pastSubstitutes.compactMap { $0.exercise?.id })
    }

    private var sameGroup: [Exercise] {
        guard let group = original?.muscleGroup else { return [] }
        return exercises.filter { $0.muscleGroup == group && $0.id != original?.id && $0.id != row.exercise?.id && !pastIDs.contains($0.id) }
    }

    /// Senza ricerca mostra solo quello che non compare già nelle sezioni sopra.
    private var searchResults: [Exercise] {
        let shownAbove = search.isEmpty ? pastIDs.union(sameGroup.map(\.id)) : []
        return exercises.filter { exercise in
            exercise.id != original?.id
                && exercise.id != row.exercise?.id
                && !shownAbove.contains(exercise.id)
                && (search.isEmpty || exercise.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Al posto di \(original?.name ?? "questo esercizio"). La scheda \(row.session?.template?.name ?? "") non cambia.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Color.clear)
                }

                if row.isExerciseSubstitution, let original {
                    Section {
                        choiceRow(original, detail: "Torna all'esercizio della scheda")
                    }
                }

                if search.isEmpty && !pastSubstitutes.isEmpty {
                    Section {
                        ForEach(pastSubstitutes) { past in
                            if let exercise = past.exercise {
                                choiceRow(exercise, detail: pastDetail(past))
                            }
                        }
                    } header: {
                        SectionLabel("Già usati al suo posto")
                    }
                }

                if search.isEmpty && !sameGroup.isEmpty {
                    Section {
                        ForEach(sameGroup) { exercise in
                            choiceRow(exercise, detail: exercise.defaultMachine?.name ?? exercise.defaultEquipment?.name)
                        }
                    } header: {
                        SectionLabel("Altri esercizi · \(original?.muscleGroup ?? "")")
                    }
                }

                Section {
                    if searchResults.isEmpty && (!search.isEmpty || (pastIDs.isEmpty && sameGroup.isEmpty)) {
                        Text("Nessun esercizio. Creane uno con Crea nuovo.")
                            .foregroundStyle(Theme.textSecondary)
                            .listRowBackground(Theme.surface)
                    }
                    ForEach(searchResults) { exercise in
                        choiceRow(exercise, detail: [exercise.muscleGroup, exercise.defaultMachine?.name].compactMap { $0 }.joined(separator: " · "))
                    }
                } header: {
                    if !search.isEmpty {
                        SectionLabel("Risultati")
                    } else if !searchResults.isEmpty {
                        SectionLabel("Resto del catalogo")
                    }
                } footer: {
                    if let selected {
                        Text("Nello storico resta scritto che oggi hai fatto \(selected.name) al posto di \(original?.name ?? "").")
                    }
                }
            }
            .reppListStyle()
            .searchable(text: $search, prompt: "Cerca nel catalogo")
            .navigationTitle("Sostituisci per oggi")
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
                if let selected {
                    Button(selected.id == original?.id ? "Torna a \(selected.name)" : "Sostituisci solo per oggi") {
                        onChoose(selected)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.background)
                }
            }
            .sheet(isPresented: $showingNew) {
                NewExerciseView(initialGroup: original?.muscleGroup) { exercise in
                    selected = exercise
                }
            }
            .onAppear {
                if let original {
                    pastSubstitutes = SessionHistory.pastSubstitutes(for: original, in: context)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func choiceRow(_ exercise: Exercise, detail: String?) -> some View {
        let isSelected = selected?.id == exercise.id
        return Button {
            selected = isSelected ? nil : exercise
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .foregroundStyle(Theme.text)
                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.pink : Theme.silver)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .listRowBackground(Theme.surface)
    }

    /// "mar 27 ott · Panca · 4 serie · 30 kg × 8"
    private func pastDetail(_ past: SessionExercise) -> String {
        [past.session?.startedAt.shortDay, past.machine?.name, past.setsSummary]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

// MARK: - Macchina e attrezzo per oggi

/// Sceglie macchina e attrezzo per questa sessione. Ogni macchina ha il suo storico.
struct MachineSheet: View {
    let row: SessionExercise
    let session: WorkoutSession
    let onChoose: (Machine?, Equipment?) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]
    @State private var machine: Machine?
    @State private var tool: Equipment?
    @State private var makeDefault = false
    @State private var lastByMachine: [UUID?: String] = [:]

    private var defaultMachine: Machine? {
        row.isExerciseSubstitution || row.plannedItem == nil ? row.exercise?.defaultMachine : row.plannedItem?.machine
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    machineRow(nil, name: "Nessuna macchina")
                    ForEach(machines) { item in
                        machineRow(item, name: item.name)
                    }
                } header: {
                    SectionLabel("Su quale macchina?")
                } footer: {
                    Text("Ogni macchina ha il suo storico: i carichi su una macchina non si mescolano con quelli su un'altra.")
                }

                Section {
                    Picker("Attrezzo", selection: $tool) {
                        Text("Nessuno").tag(Equipment?.none)
                        ForEach(equipment) { Text($0.label).tag(Optional($0)) }
                    }
                    .listRowBackground(Theme.surface)
                } footer: {
                    Text("Il peso del bilanciere è solo un'informazione: segni sempre il carico totale.")
                }

                if machine?.id != defaultMachine?.id {
                    Section {
                        Toggle("Rendi \(machine?.name ?? "nessuna macchina") la predefinita per questo esercizio", isOn: $makeDefault)
                            .tint(Theme.pink)
                            .listRowBackground(Theme.surface)
                    }
                }
            }
            .reppListStyle()
            .navigationTitle(row.exercise?.name ?? "Macchina")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(makeDefault ? "Salva come predefinita" : "Usa \(machine?.name ?? "nessuna macchina") oggi") {
                    if makeDefault {
                        row.exercise?.defaultMachine = machine
                        if !row.isExerciseSubstitution, let item = row.plannedItem {
                            item.machine = machine
                        }
                    }
                    onChoose(machine, tool)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.background)
            }
            .onAppear {
                machine = row.machine
                tool = row.equipment
                loadHistory()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func machineRow(_ item: Machine?, name: String) -> some View {
        let isSelected = machine?.id == item?.id
        return Button {
            machine = item
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name).foregroundStyle(Theme.text)
                        if item?.id == defaultMachine?.id {
                            Text("Predefinita")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.metal, in: Capsule())
                        }
                    }
                    if let last = lastByMachine[item?.id] {
                        Text(last)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.pink : Theme.silver)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .listRowBackground(Theme.surface)
    }

    private func loadHistory() {
        guard let exercise = row.exercise else { return }
        var result: [UUID?: String] = [:]
        for past in SessionHistory.finishedRows(in: context) where past.exercise?.id == exercise.id && past.session?.id != session.id {
            let key = past.machine?.id
            if result[key] == nil {
                result[key] = "Ultima volta \(past.session?.startedAt.shortDay ?? "") · \(past.setsSummary)"
            }
        }
        lastByMachine = result
    }
}

// MARK: - Note

/// Note dell'esercizio: quelle fissate si vedono sempre in sessione, le altre restano legate al giorno.
struct NotesSheet: View {
    let exercise: Exercise
    let session: WorkoutSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var pin = false

    private var pinned: [ExerciseNote] {
        exercise.notes.filter(\.isPinned).sorted { $0.createdAt > $1.createdAt }
    }

    private var fromSessions: [ExerciseNote] {
        exercise.notes.filter { !$0.isPinned }.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Nuova nota per oggi", text: $text, axis: .vertical)
                        .lineLimit(2...5)
                        .listRowBackground(Theme.surface)
                    Toggle("Fissala, così la vedi sempre in sessione", isOn: $pin)
                        .tint(Theme.pink)
                        .listRowBackground(Theme.surface)
                    Button("Salva nota", action: save)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .listRowBackground(Theme.surface)
                }

                if !pinned.isEmpty {
                    Section {
                        ForEach(pinned) { note in
                            noteRow(note)
                        }
                    } header: {
                        SectionLabel("Fissate")
                    }
                }

                if !fromSessions.isEmpty {
                    Section {
                        ForEach(fromSessions) { note in
                            noteRow(note)
                        }
                    } header: {
                        SectionLabel("Dalle sessioni")
                    }
                }
            }
            .reppListStyle()
            .navigationTitle("Note · \(exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func noteRow(_ note: ExerciseNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.text)
                .foregroundStyle(Theme.text)
            Text(note.session?.id == session.id ? "Oggi" : note.createdAt.shortDay)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .listRowBackground(Theme.surface)
        .swipeActions(edge: .trailing) {
            Button("Elimina", role: .destructive) {
                context.delete(note)
            }
        }
        .swipeActions(edge: .leading) {
            Button(note.isPinned ? "Stacca" : "Fissa") {
                note.isPinned.toggle()
            }
            .tint(Theme.silver)
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let note = ExerciseNote(text: trimmed, isPinned: pin)
        context.insert(note)
        note.exercise = exercise
        note.session = session
        text = ""
        pin = false
    }
}
