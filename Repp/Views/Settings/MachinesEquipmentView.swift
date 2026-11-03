import SwiftUI
import SwiftData

/// Macchine e attrezzi della palestra, con la possibilità di aggiungerne altri.
struct MachinesEquipmentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Machine.name) private var machines: [Machine]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]

    @State private var addingMachine = false
    @State private var addingEquipment = false
    @State private var newName = ""
    @State private var newWeight = ""

    var body: some View {
        List {
            Section {
                ForEach(machines) { machine in
                    Text(machine.name)
                        .listRowBackground(Theme.surface)
                }
                Button {
                    newName = ""
                    addingMachine = true
                } label: {
                    Label("Aggiungi macchina", systemImage: "plus")
                        .foregroundStyle(Theme.silver)
                }
                .listRowBackground(Theme.surface)
            } header: {
                SectionLabel("Macchine · \(machines.count)")
            }

            Section {
                ForEach(equipment) { tool in
                    HStack {
                        Text(tool.name)
                        Spacer()
                        Text(tool.weightKg.map { "\($0.kgString) kg" } ?? "—")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surface)
                }
                Button {
                    newName = ""
                    newWeight = ""
                    addingEquipment = true
                } label: {
                    Label("Aggiungi attrezzo", systemImage: "plus")
                        .foregroundStyle(Theme.silver)
                }
                .listRowBackground(Theme.surface)
            } header: {
                SectionLabel("Attrezzi · \(equipment.count)")
            } footer: {
                Text("Il peso del bilanciere è solo un'informazione: in sessione segni sempre il carico totale.")
            }
        }
        .reppListStyle()
        .navigationTitle("Macchine e attrezzi")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Nuova macchina", isPresented: $addingMachine) {
            TextField("Nome", text: $newName)
            Button("Annulla", role: .cancel) {}
            Button("Aggiungi") { addMachine() }
        }
        .alert("Nuovo attrezzo", isPresented: $addingEquipment) {
            TextField("Nome", text: $newName)
            TextField("Peso in kg (facoltativo)", text: $newWeight)
                .keyboardType(.decimalPad)
            Button("Annulla", role: .cancel) {}
            Button("Aggiungi") { addEquipment() }
        }
    }

    private func addMachine() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        context.insert(Machine(name: name))
    }

    private func addEquipment() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let weight = Double(newWeight.replacingOccurrences(of: ",", with: "."))
        context.insert(Equipment(name: name, weightKg: weight))
    }
}
