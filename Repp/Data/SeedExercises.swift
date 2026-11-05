import Foundation
import SwiftData

/// Catalogo esercizi di partenza (v2). Il nome dice solo l'esercizio: macchina e attrezzo sono i predefiniti
/// della singola voce. Se un esercizio ha senso con macchine o attrezzi diversi compare più volte, una per variante.
/// Ogni esercizio ha un solo gruppo muscolare. I nomi di macchine e attrezzi devono corrispondere a quelli di `SeedData`.
enum SeedExercises {
    struct Key: Hashable {
        let name: String
        let machine: String?
        let equipment: String?
    }

    struct Item {
        let name: String
        let group: String
        let machine: String?
        let equipment: String?

        var key: Key { Key(name: name, machine: machine, equipment: equipment) }
    }

    private static func list(_ group: String, _ rows: [(String, String?, String?)]) -> [Item] {
        rows.map { Item(name: $0.0, group: group, machine: $0.1, equipment: $0.2) }
    }

    static let all: [Item] = petto + schiena + spalle + bicipiti + tricipiti + gambe

    private static let petto = list("Petto", [
            ("Panca piana", "Panca", "Bilanciere olimpico"),
            ("Panca piana", "Panca", "Manubri"),
            ("Panca piana", "Multipower", nil),
            ("Panca inclinata", "Panca", "Bilanciere olimpico"),
            ("Panca inclinata", "Panca", "Manubri"),
            ("Panca inclinata", "Multipower", nil),
            ("Panca declinata", "Panca", "Bilanciere olimpico"),
            ("Panca declinata", "Panca", "Manubri"),
            ("Panca piana presa inversa", "Panca", "Bilanciere olimpico"),
            ("Croci su panca piana", "Panca", "Manubri"),
            ("Croci su panca inclinata", "Panca", "Manubri"),
            ("Pullover", "Panca", "Manubri"),
            ("Chest press", "Chest press", nil),
            ("Chest press presa stretta", "Chest press", nil),
            ("Croci ai cavi", "Cavi doppi (anche uso singolo)", "Maniglia"),
            ("Croci ai cavi dal basso", "Cavi regolabili doppi", "Maniglia"),
            ("Croci ai cavi dall'alto", "Cavi regolabili doppi", "Maniglia"),
            ("Croci a un braccio", "Cavo singolo", "Maniglia"),
            ("Dip per il petto", "Dips", nil),
            ("Piegamenti", nil, nil)
    ])

    private static let schiena = list("Schiena", [
            ("Lat machine", "Lat machine al castello", "Sbarra larga"),
            ("Lat machine", "Lat machine al castello", "Presa stretta"),
            ("Lat machine", "Lat machine macchina", nil),
            ("Lat machine presa inversa", "Lat machine al castello", "Sbarra corta"),
            ("Lat machine a un braccio", "Lat machine al castello", "Maniglia"),
            ("Pulley", "Pulley", "Presa stretta"),
            ("Pulley", "Pulley", "Sbarra larga"),
            ("Pulley a un braccio", "Pulley", "Maniglia"),
            ("Low row", "Low row", nil),
            ("Low row a un braccio", "Low row", nil),
            ("Trazioni", nil, nil),
            ("Trazioni assistite presa larga", "Macchina per trazioni assistite", nil),
            ("Trazioni assistite presa neutra", "Macchina per trazioni assistite", nil),
            ("Rematore", nil, "Bilanciere olimpico"),
            ("Rematore", "Multipower", nil),
            ("Rematore a un braccio", "Panca", "Manubri"),
            ("Rematore a un braccio", "Cavo singolo", "Maniglia"),
            ("Rematore su panca inclinata", "Panca", "Manubri"),
            ("Pullover in piedi", "Cavo singolo", "Sbarra corta"),
            ("Stacco da terra", nil, "Bilanciere olimpico")
    ])

    private static let spalle = list("Spalle", [
            ("Lento avanti", nil, "Bilanciere olimpico"),
            ("Lento avanti", "Multipower", nil),
            ("Lento dietro", "Multipower", nil),
            ("Lento avanti seduto", "Panca", "Manubri"),
            ("Lento avanti in piedi", nil, "Manubri"),
            ("Arnold press", "Panca", "Manubri"),
            ("Alzate laterali", nil, "Manubri"),
            ("Alzate laterali", "Cavo singolo", "Maniglia"),
            ("Alzate laterali", "Cavi regolabili doppi", "Maniglia"),
            ("Alzate frontali", nil, "Manubri"),
            ("Alzate frontali", nil, "Bilanciere"),
            ("Alzate frontali", "Cavo singolo", "Corda"),
            ("Alzate posteriori a busto flesso", nil, "Manubri"),
            ("Alzate a Y su panca inclinata", "Panca", "Manubri"),
            ("Croci inverse", "Cavi doppi (anche uso singolo)", "Maniglia"),
            ("Face pull", "Cavo singolo", "Corda"),
            ("Tirate al mento", nil, "Bilanciere Z"),
            ("Tirate al mento", "Cavo singolo", "Sbarra corta"),
            ("Scrollate", nil, "Manubri"),
            ("Scrollate", nil, "Bilanciere olimpico")
    ])

    private static let bicipiti = list("Bicipiti", [
            ("Curl", nil, "Bilanciere"),
            ("Curl", nil, "Bilanciere Z"),
            ("Curl presa larga", nil, "Bilanciere olimpico"),
            ("Curl inverso", nil, "Bilanciere Z"),
            ("Curl 21", nil, "Bilanciere Z"),
            ("Drag curl", nil, "Bilanciere"),
            ("Curl alternato", nil, "Manubri"),
            ("Curl a martello", nil, "Manubri"),
            ("Curl concentrato", nil, "Manubri"),
            ("Curl Zottman", nil, "Manubri"),
            ("Curl su panca inclinata", "Panca", "Manubri"),
            ("Spider curl", "Panca", "Manubri"),
            ("Curl alla panca Scott", "Panca Scott", "Bilanciere Z"),
            ("Curl alla panca Scott", "Panca Scott", "Manubri"),
            ("Curl a martello alla panca Scott", "Panca Scott", "Manubri"),
            ("Curl al cavo", "Cavo singolo", "Sbarra corta"),
            ("Curl a martello al cavo", "Cavo singolo", "Corda"),
            ("Curl a un braccio al cavo", "Cavo singolo", "Maniglia"),
            ("Curl ai cavi alti", "Cavi doppi (anche uso singolo)", "Maniglia"),
            ("Curl Bayesian", "Cavi regolabili doppi", "Maniglia")
    ])

    private static let tricipiti = list("Tricipiti", [
            ("Push down", "Cavo singolo", "Sbarra corta"),
            ("Push down", "Cavo singolo", "Corda"),
            ("Push down presa inversa", "Cavo singolo", "Sbarra corta"),
            ("Push down a un braccio", "Cavo singolo", "Maniglia"),
            ("Estensioni sopra la testa", "Cavo singolo", "Corda"),
            ("Estensioni sopra la testa", nil, "Manubri"),
            ("Estensioni a un braccio sopra la testa", "Cavi regolabili doppi", "Maniglia"),
            ("Estensioni incrociate", "Cavi doppi (anche uso singolo)", "Maniglia"),
            ("Kickback", "Cavo singolo", "Maniglia"),
            ("Kickback", nil, "Manubri"),
            ("French press", "Panca", "Bilanciere Z"),
            ("French press", "Panca", "Manubri"),
            ("French press su panca inclinata", "Panca", "Bilanciere Z"),
            ("Tate press", "Panca", "Manubri"),
            ("Panca presa stretta", "Panca", "Bilanciere olimpico"),
            ("Panca presa stretta", "Multipower", nil),
            ("JM press", "Multipower", nil),
            ("Dip", "Dips", nil),
            ("Dip su panca", "Panca", nil),
            ("Piegamenti presa stretta", nil, nil)
    ])

    private static let gambe = list("Gambe", [
            ("Squat", nil, "Bilanciere olimpico"),
            ("Squat", "Multipower", nil),
            ("Front squat", nil, "Bilanciere olimpico"),
            ("Goblet squat", nil, "Manubri"),
            ("Leg press", "Leg press carico diretto", nil),
            ("Leg press piedi stretti", "Leg press carico diretto", nil),
            ("Leg press", "Leg press orizzontale", nil),
            ("Leg extension", "Leg extension", nil),
            ("Leg extension a una gamba", "Leg extension", nil),
            ("Leg curl", "Leg curl", nil),
            ("Leg curl a una gamba", "Leg curl", nil),
            ("Affondi", nil, "Manubri"),
            ("Affondi camminati", nil, "Manubri"),
            ("Affondi", "Multipower", nil),
            ("Squat bulgaro", "Panca", "Manubri"),
            ("Step up", "Panca", "Manubri"),
            ("Stacco rumeno", nil, "Bilanciere olimpico"),
            ("Stacco rumeno", nil, "Manubri"),
            ("Calf in piedi", "Multipower", nil),
            ("Calf", "Leg press orizzontale", nil)
    ])

    /// Esercizi del vecchio catalogo (v1) usati nelle schede, con la voce corrispondente del catalogo nuovo.
    static let legacy: [String: Key] = [
        "Panca piana bilanciere": Key(name: "Panca piana", machine: "Panca", equipment: "Bilanciere olimpico"),
        "Panca inclinata manubri": Key(name: "Panca inclinata", machine: "Panca", equipment: "Manubri"),
        "Lento avanti manubri seduto": Key(name: "Lento avanti seduto", machine: "Panca", equipment: "Manubri"),
        "Alzate laterali manubri": Key(name: "Alzate laterali", machine: nil, equipment: "Manubri"),
        "Curl bilanciere Z": Key(name: "Curl", machine: nil, equipment: "Bilanciere Z"),
        "French press bilanciere Z": Key(name: "French press", machine: "Panca", equipment: "Bilanciere Z"),
        "Curl a martello": Key(name: "Curl a martello", machine: nil, equipment: "Manubri"),
        "Push down con corda": Key(name: "Push down", machine: "Cavo singolo", equipment: "Corda"),
        "Lat machine al castello presa larga": Key(name: "Lat machine", machine: "Lat machine al castello", equipment: "Sbarra larga"),
        "Lat machine al castello presa neutra": Key(name: "Lat machine", machine: "Lat machine al castello", equipment: "Presa stretta"),
        "Pulley presa stretta": Key(name: "Pulley", machine: "Pulley", equipment: "Presa stretta"),
        "Rematore manubri su panca inclinata": Key(name: "Rematore su panca inclinata", machine: "Panca", equipment: "Manubri"),
        "Low row a un braccio": Key(name: "Low row a un braccio", machine: "Low row", equipment: nil),
        "Curl alla panca Scott bilanciere Z": Key(name: "Curl alla panca Scott", machine: "Panca Scott", equipment: "Bilanciere Z"),
        "Croci ai cavi": Key(name: "Croci ai cavi", machine: "Cavi doppi (anche uso singolo)", equipment: "Maniglia"),
        "Curl su panca inclinata manubri": Key(name: "Curl su panca inclinata", machine: "Panca", equipment: "Manubri"),
        "Estensioni a un braccio sopra la testa al cavo": Key(name: "Estensioni a un braccio sopra la testa", machine: "Cavi regolabili doppi", equipment: "Maniglia"),
        "Chest press": Key(name: "Chest press", machine: "Chest press", equipment: nil),
        "Lento avanti bilanciere": Key(name: "Lento avanti", machine: nil, equipment: "Bilanciere olimpico"),
        "Curl Bayesian al cavo": Key(name: "Curl Bayesian", machine: "Cavi regolabili doppi", equipment: "Maniglia"),
        "Curl concentrato": Key(name: "Curl concentrato", machine: nil, equipment: "Manubri"),
        "Estensioni sopra la testa manubrio": Key(name: "Estensioni sopra la testa", machine: nil, equipment: "Manubri")
    ]

    private static let seededV1Key = "repp.seed.exercises.v1"
    private static let seededV2Key = "repp.seed.exercises.v2"

    /// Al primo avvio inserisce il catalogo. Su un telefono che aveva il catalogo v1, lo sostituisce con il nuovo:
    /// schede, sessioni e note passano alle voci nuove, e i vecchi esercizi di partenza non usati vengono tolti.
    @MainActor
    static func insertIfNeeded(into context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededV2Key) else { return }

        SeedData.addMissingEquipment(into: context)
        let machines = (try? context.fetch(FetchDescriptor<Machine>())) ?? []
        let equipment = (try? context.fetch(FetchDescriptor<Equipment>())) ?? []
        let machineByName = Dictionary(machines.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let equipmentByName = Dictionary(equipment.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let oldExercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []

        var created: [Key: Exercise] = [:]
        for item in all {
            let exercise = Exercise(name: item.name, muscleGroup: item.group)
            exercise.isBuiltIn = true
            context.insert(exercise)
            exercise.defaultMachine = item.machine.flatMap { machineByName[$0] }
            exercise.defaultEquipment = item.equipment.flatMap { equipmentByName[$0] }
            created[item.key] = exercise
        }

        if defaults.bool(forKey: seededV1Key) || !oldExercises.isEmpty {
            migrate(oldExercises, to: created, in: context)
        }

        try? context.save()
        defaults.set(true, forKey: seededV2Key)
    }

    /// Collega schede, sessioni e note degli esercizi vecchi alle voci nuove.
    @MainActor
    private static func migrate(_ oldExercises: [Exercise], to created: [Key: Exercise], in context: ModelContext) {
        var byName: [String: [Exercise]] = [:]
        for (key, exercise) in created { byName[key.name, default: []].append(exercise) }

        // Gruppi rinominati: Dorso diventa Schiena, Glutei va in Gambe.
        for exercise in oldExercises {
            switch exercise.muscleGroup {
            case "Dorso": exercise.muscleGroup = "Schiena"
            case "Glutei": exercise.muscleGroup = "Gambe"
            default: break
            }
        }

        var replacement: [UUID: Exercise] = [:]
        for old in oldExercises where old.isBuiltIn {
            if let key = legacy[old.name], let target = created[key] {
                replacement[old.id] = target
            } else if let matches = byName[old.name], matches.count == 1 {
                replacement[old.id] = matches[0]
            }
        }

        let items = (try? context.fetch(FetchDescriptor<TemplateExercise>())) ?? []
        let rows = (try? context.fetch(FetchDescriptor<SessionExercise>())) ?? []
        var used = Set<UUID>()

        for item in items {
            guard let old = item.exercise else { continue }
            if let target = replacement[old.id] {
                item.exercise = target
                if item.machine == nil { item.machine = target.defaultMachine }
                if item.equipment == nil { item.equipment = target.defaultEquipment }
            } else {
                used.insert(old.id)
            }
        }
        for row in rows {
            guard let old = row.exercise else { continue }
            if let target = replacement[old.id] {
                row.exercise = target
                if row.machine == nil { row.machine = target.defaultMachine }
                if row.equipment == nil { row.equipment = target.defaultEquipment }
            } else {
                used.insert(old.id)
            }
        }

        // Le note passano alla voce nuova prima di togliere il vecchio esercizio (che le cancellerebbe con sé).
        for old in oldExercises where old.isBuiltIn {
            guard let target = replacement[old.id] else { continue }
            for note in Array(old.notes) { note.exercise = target }
        }
        try? context.save()

        for old in oldExercises where old.isBuiltIn {
            if replacement[old.id] != nil {
                context.delete(old)
            } else if used.contains(old.id) || !old.notes.isEmpty {
                // Usato ma senza una voce nuova corrispondente: resta, come esercizio tuo.
                old.isBuiltIn = false
            } else {
                context.delete(old)
            }
        }
    }
}
