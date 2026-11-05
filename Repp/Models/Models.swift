import Foundation
import SwiftData

/// Qualità di una serie, scelta con le faccine dopo ogni serie.
enum SetQuality: String, Codable, CaseIterable, Identifiable {
    case ottima, buona, media, bassa

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ottima: "Ottima"
        case .buona: "Buona"
        case .media: "Media"
        case .bassa: "Bassa"
        }
    }
}

// MARK: - Palestra

/// Una macchina della palestra (es. Panca, Multipower, Leg curl).
@Model
final class Machine {
    @Attribute(.unique) var id: UUID
    var name: String
    var isBuiltIn: Bool
    var createdAt: Date

    init(name: String, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }
}

/// Un attrezzo (manubri, bilancieri). Il peso è solo informativo: in sessione si segna sempre il carico totale.
@Model
final class Equipment {
    @Attribute(.unique) var id: UUID
    var name: String
    var weightKg: Double?
    var isBuiltIn: Bool
    var createdAt: Date

    init(name: String, weightKg: Double? = nil, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.weightKg = weightKg
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }
}

// MARK: - Esercizi

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroup: String?
    /// Macchina e attrezzo usati di solito; in sessione si possono cambiare solo per quella volta.
    var defaultMachine: Machine?
    var defaultEquipment: Equipment?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseNote.exercise)
    var notes: [ExerciseNote] = []
    /// Esercizio del catalogo di partenza (non creato dall'utente).
    var isBuiltIn: Bool = false
    var createdAt: Date

    init(name: String, muscleGroup: String? = nil, defaultMachine: Machine? = nil, defaultEquipment: Equipment? = nil) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.defaultMachine = defaultMachine
        self.defaultEquipment = defaultEquipment
        self.createdAt = .now
    }
}

/// Nota su un esercizio. Se fissata si vede sempre in sessione; se ha una sessione, è la nota di quel giorno.
@Model
final class ExerciseNote {
    @Attribute(.unique) var id: UUID
    var exercise: Exercise?
    var session: WorkoutSession?
    var text: String
    var isPinned: Bool
    var createdAt: Date

    /// Esercizio e sessione si impostano dopo `context.insert`.
    init(text: String, isPinned: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isPinned = isPinned
        self.createdAt = .now
    }
}

// MARK: - Schede

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var position: Int
    /// Le schede eliminate vengono solo archiviate, così lo storico delle sessioni resta intatto.
    var isArchived: Bool = false
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var items: [TemplateExercise] = []
    var createdAt: Date

    init(name: String, position: Int = 0) {
        self.id = UUID()
        self.name = name
        self.position = position
        self.createdAt = .now
    }

    var orderedItems: [TemplateExercise] {
        items.sorted { $0.position < $1.position }
    }
}

/// Un esercizio dentro una scheda, con gli obiettivi.
@Model
final class TemplateExercise {
    @Attribute(.unique) var id: UUID
    var template: WorkoutTemplate?
    var exercise: Exercise?
    var machine: Machine?
    var equipment: Equipment?
    var position: Int
    var targetSets: Int
    var targetReps: Int?
    var targetWeightKg: Double?
    var restSeconds: Int
    /// Le righe di sessione nate da questo esercizio della scheda (anche quelle sostituite).
    @Relationship(deleteRule: .nullify, inverse: \SessionExercise.plannedItem)
    var sessionRows: [SessionExercise] = []

    /// Le relazioni (esercizio, macchina, attrezzo, scheda) si impostano dopo `context.insert`, con `configure(exercise:template:)`.
    init(position: Int, targetSets: Int = 3, targetReps: Int? = 8, targetWeightKg: Double? = nil, restSeconds: Int = 90) {
        self.id = UUID()
        self.position = position
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.restSeconds = restSeconds
    }

    func configure(exercise: Exercise, template: WorkoutTemplate) {
        self.exercise = exercise
        self.machine = exercise.defaultMachine
        self.equipment = exercise.defaultEquipment
        self.template = template
    }
}

// MARK: - Sessioni

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var template: WorkoutTemplate?
    var startedAt: Date
    var endedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []
    /// Le note scritte durante questa sessione.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseNote.session)
    var notes: [ExerciseNote] = []

    /// La scheda si imposta dopo `context.insert`.
    init(startedAt: Date = .now) {
        self.id = UUID()
        self.startedAt = startedAt
    }

    var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.position < $1.position }
    }
}

/// Cosa è stato fatto davvero in sessione per un esercizio della scheda.
/// Se esercizio o macchina sono diversi da quelli previsti, è una sostituzione valida solo per questa sessione.
@Model
final class SessionExercise {
    @Attribute(.unique) var id: UUID
    var session: WorkoutSession?
    /// L'esercizio previsto dalla scheda (nil se aggiunto solo per oggi).
    var plannedItem: TemplateExercise?
    var exercise: Exercise?
    var machine: Machine?
    var equipment: Equipment?
    var position: Int
    @Relationship(deleteRule: .cascade, inverse: \SessionSet.sessionExercise)
    var sets: [SessionSet] = []
    /// Serie di riscaldamento: si vedono in sessione ma non contano nelle serie, nei progressi e nei record.
    @Relationship(deleteRule: .cascade, inverse: \WarmupSet.sessionExercise)
    var warmupSets: [WarmupSet] = []

    /// Le relazioni si impostano dopo `context.insert`, con `configure(...)`.
    init(position: Int) {
        self.id = UUID()
        self.position = position
    }

    func configure(session: WorkoutSession, plannedItem: TemplateExercise?, exercise: Exercise, machine: Machine?, equipment: Equipment?) {
        self.session = session
        self.plannedItem = plannedItem
        self.exercise = exercise
        self.machine = machine
        self.equipment = equipment
    }

    /// Esercizio diverso da quello della scheda.
    var isExerciseSubstitution: Bool {
        guard let planned = plannedItem?.exercise else { return false }
        return planned.id != exercise?.id
    }

    /// Stesso esercizio ma con un'altra macchina o un altro attrezzo: nello storico conta come una variante a sé.
    var isMachineChange: Bool {
        guard let planned = plannedItem, !isExerciseSubstitution else { return false }
        return planned.machine?.id != machine?.id || planned.equipment?.id != equipment?.id
    }

    /// Chiave dello storico: esercizio + macchina + attrezzo.
    var historyKey: HistoryKey? {
        guard let exercise else { return nil }
        return HistoryKey(exerciseID: exercise.id, machineID: machine?.id, equipmentID: equipment?.id)
    }

    var setupKey: SetupKey {
        SetupKey(machineID: machine?.id, equipmentID: equipment?.id)
    }

    var orderedWarmupSets: [WarmupSet] {
        warmupSets.sorted { $0.completedAt < $1.completedAt }
    }

    var orderedSets: [SessionSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }
}

@Model
final class SessionSet {
    @Attribute(.unique) var id: UUID
    var sessionExercise: SessionExercise?
    var setNumber: Int
    /// Carico totale in kg, bilanciere incluso.
    var weightKg: Double
    var reps: Int
    var qualityRaw: String?
    var restSeconds: Int?
    var completedAt: Date

    /// La riga di sessione (`sessionExercise`) si imposta dopo `context.insert`.
    init(setNumber: Int, weightKg: Double, reps: Int, quality: SetQuality? = nil, restSeconds: Int? = nil) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.qualityRaw = quality?.rawValue
        self.restSeconds = restSeconds
        self.completedAt = .now
    }

    var quality: SetQuality? {
        get { qualityRaw.flatMap(SetQuality.init(rawValue:)) }
        set { qualityRaw = newValue?.rawValue }
    }
}

/// Serie di riscaldamento di un esercizio in sessione.
@Model
final class WarmupSet {
    @Attribute(.unique) var id: UUID
    var sessionExercise: SessionExercise?
    var weightKg: Double
    var reps: Int
    var completedAt: Date

    /// La riga di sessione (`sessionExercise`) si imposta dopo `context.insert`.
    init(weightKg: Double, reps: Int) {
        self.id = UUID()
        self.weightKg = weightKg
        self.reps = reps
        self.completedAt = .now
    }
}

/// Lo storico è separato per esercizio, macchina e attrezzo: cambiarli è come cambiare esercizio.
struct HistoryKey: Hashable {
    let exerciseID: UUID
    let machineID: UUID?
    let equipmentID: UUID?

    var setup: SetupKey { SetupKey(machineID: machineID, equipmentID: equipmentID) }
}

/// Macchina + attrezzo usati per un esercizio.
struct SetupKey: Hashable {
    let machineID: UUID?
    let equipmentID: UUID?
}
