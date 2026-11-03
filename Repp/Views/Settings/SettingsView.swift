import SwiftUI
import SwiftData

/// Impostazioni: allenamento, palestra e dati sul telefono.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(RestSettings.defaultRestKey) private var defaultRest = 90
    @AppStorage(RestSettings.alertsKey) private var restAlerts = true
    @AppStorage(RestSettings.liveActivityKey) private var liveActivity = true
    @AppStorage(RestSettings.askQualityKey) private var askQuality = true
    @AppStorage(RestSettings.loadStepKey) private var loadStep = 2.5
    @Query private var machines: [Machine]
    @Query private var equipment: [Equipment]
    @State private var export: ExportFile?
    @State private var exportFailed = false

    private let loadSteps: [Double] = [1, 1.25, 2, 2.5, 5]

    var body: some View {
        List {
            Section {
                Stepper(value: $defaultRest, in: 15...600, step: 15) {
                    row("Riposo predefinito", defaultRest.restString)
                }
                Toggle("Suono e vibrazione a fine riposo", isOn: $restAlerts)
                Toggle("Timer sulla schermata di blocco", isOn: $liveActivity)
                Toggle("Chiedi la qualità dopo ogni serie", isOn: $askQuality)
            } header: {
                SectionLabel("Allenamento")
            } footer: {
                Text("Il riposo predefinito vale per gli esercizi che aggiungi da ora in poi.")
            }
            .listRowBackground(Theme.surface)
            .tint(Theme.pink)

            Section {
                NavigationLink {
                    MachinesEquipmentView()
                } label: {
                    row("Macchine e attrezzi", "\(machines.count + equipment.count)")
                }
                row("Unità di peso", "kg")
                Picker("Incremento carico", selection: $loadStep) {
                    ForEach(loadSteps, id: \.self) { step in
                        Text("\(step.kgString) kg").tag(step)
                    }
                }
            } header: {
                SectionLabel("Palestra")
            } footer: {
                Text("L'incremento è il passo dei pulsanti − e + del carico durante la sessione.")
            }
            .listRowBackground(Theme.surface)

            Section {
                Button("Esporta tutti i dati (JSON)", action: exportData)
                    .foregroundStyle(Theme.silver)
            } header: {
                SectionLabel("Dati sul telefono")
            } footer: {
                Text("Repp \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") · tutti i dati restano sul tuo telefono, senza account. L'esportazione ti permette di salvarne una copia in File o dove preferisci.")
            }
            .listRowBackground(Theme.surface)
        }
        .reppListStyle()
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $export) { file in
            ShareSheet(items: [file.url])
                .ignoresSafeArea()
        }
        .alert("Esportazione non riuscita", isPresented: $exportFailed) {
            Button("OK", role: .cancel) {}
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func exportData() {
        do {
            let url = try DataExport.write(from: context)
            export = ExportFile(url: url)
        } catch {
            exportFailed = true
        }
    }
}

private struct ExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Esportazione leggibile di schede, esercizi e sessioni.
enum DataExport {
    private struct Export: Encodable {
        let exportedAt: Date
        let machines: [String]
        let equipment: [EquipmentItem]
        let exercises: [ExerciseItem]
        let templates: [TemplateItem]
        let sessions: [SessionItem]
    }

    private struct EquipmentItem: Encodable { let name: String; let weightKg: Double? }
    private struct ExerciseItem: Encodable { let name: String; let muscleGroup: String?; let defaultMachine: String?; let defaultEquipment: String?; let notes: [String] }
    private struct TemplateItem: Encodable { let name: String; let exercises: [TemplateExerciseItem] }
    private struct TemplateExerciseItem: Encodable { let exercise: String?; let machine: String?; let equipment: String?; let sets: Int; let reps: Int?; let weightKg: Double?; let restSeconds: Int }
    private struct SessionItem: Encodable { let template: String?; let startedAt: Date; let endedAt: Date?; let exercises: [SessionExerciseItem] }
    private struct SessionExerciseItem: Encodable { let exercise: String?; let plannedExercise: String?; let machine: String?; let equipment: String?; let substitution: Bool; let machineChange: Bool; let sets: [SetItem] }
    private struct SetItem: Encodable { let number: Int; let weightKg: Double; let reps: Int; let quality: String?; let completedAt: Date }

    static func write(from context: ModelContext) throws -> URL {
        let machines = try context.fetch(FetchDescriptor<Machine>(sortBy: [SortDescriptor(\.name)]))
        let equipment = try context.fetch(FetchDescriptor<Equipment>(sortBy: [SortDescriptor(\.name)]))
        let exercises = try context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)]))
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>(sortBy: [SortDescriptor(\.position)]))
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt)]))

        let export = Export(
            exportedAt: .now,
            machines: machines.map(\.name),
            equipment: equipment.map { EquipmentItem(name: $0.name, weightKg: $0.weightKg) },
            exercises: exercises.map {
                ExerciseItem(name: $0.name, muscleGroup: $0.muscleGroup, defaultMachine: $0.defaultMachine?.name,
                             defaultEquipment: $0.defaultEquipment?.name, notes: $0.notes.map(\.text))
            },
            templates: templates.filter { !$0.isArchived }.map { template in
                TemplateItem(name: template.name, exercises: template.orderedItems.map {
                    TemplateExerciseItem(exercise: $0.exercise?.name, machine: $0.machine?.name, equipment: $0.equipment?.name,
                                         sets: $0.targetSets, reps: $0.targetReps, weightKg: $0.targetWeightKg, restSeconds: $0.restSeconds)
                })
            },
            sessions: sessions.filter { $0.endedAt != nil }.map { session in
                SessionItem(template: session.template?.name, startedAt: session.startedAt, endedAt: session.endedAt,
                            exercises: session.orderedExercises.map { row in
                                SessionExerciseItem(exercise: row.exercise?.name, plannedExercise: row.plannedItem?.exercise?.name,
                                                    machine: row.machine?.name, equipment: row.equipment?.name,
                                                    substitution: row.isExerciseSubstitution, machineChange: row.isMachineChange,
                                                    sets: row.orderedSets.map {
                                                        SetItem(number: $0.setNumber, weightKg: $0.weightKg, reps: $0.reps,
                                                                quality: $0.qualityRaw, completedAt: $0.completedAt)
                                                    })
                            })
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)
        let day = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Repp-\(day).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
