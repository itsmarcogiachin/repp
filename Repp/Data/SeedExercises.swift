import Foundation
import SwiftData

/// Catalogo esercizi di partenza: 20 esercizi comuni per gruppo muscolare,
/// ognuno legato a una macchina e/o un attrezzo della palestra (nessuno = corpo libero).
/// I nomi di macchine e attrezzi devono corrispondere a quelli di `SeedData`.
enum SeedExercises {
    struct Item {
        let name: String
        let group: String
        let machine: String?
        let equipment: String?
    }

    // Macchine
    private static let panca = "Panca"
    private static let multipower = "Multipower"
    private static let legPress45 = "Leg press carico diretto"
    private static let legPressOrizz = "Leg press orizzontale"
    private static let legExtension = "Leg extension"
    private static let legCurl = "Leg curl"
    private static let chestPress = "Chest press"
    private static let latMachine = "Lat machine macchina"
    private static let latCastello = "Lat machine al castello"
    private static let lowRow = "Low row"
    private static let pulley = "Pulley"
    private static let pancaScott = "Panca Scott"
    private static let caviDoppi = "Cavi doppi (anche uso singolo)"
    private static let caviRegolabili = "Cavi regolabili doppi"
    private static let cavoSingolo = "Cavo singolo"
    private static let dips = "Dips"
    private static let trazioniAssistite = "Macchina per trazioni assistite"

    // Attrezzi
    private static let manubri = "Manubri"
    private static let olimpico = "Bilanciere olimpico"
    private static let bilanciere = "Bilanciere"
    private static let barraZ = "Bilanciere Z"

    private static func list(_ group: String, _ rows: [(String, String?, String?)]) -> [Item] {
        rows.map { Item(name: $0.0, group: group, machine: $0.1, equipment: $0.2) }
    }

    static let all: [Item] =
        list("Petto", [
            ("Panca piana bilanciere", panca, olimpico),
            ("Panca inclinata bilanciere", panca, olimpico),
            ("Panca declinata bilanciere", panca, olimpico),
            ("Panca piana presa inversa", panca, olimpico),
            ("Panca piana manubri", panca, manubri),
            ("Panca inclinata manubri", panca, manubri),
            ("Panca declinata manubri", panca, manubri),
            ("Croci manubri su panca piana", panca, manubri),
            ("Croci manubri su panca inclinata", panca, manubri),
            ("Pullover manubrio", panca, manubri),
            ("Panca piana al multipower", multipower, nil),
            ("Panca inclinata al multipower", multipower, nil),
            ("Chest press", chestPress, nil),
            ("Chest press presa stretta", chestPress, nil),
            ("Croci ai cavi", caviDoppi, nil),
            ("Croci ai cavi dal basso", caviRegolabili, nil),
            ("Croci ai cavi dall'alto", caviRegolabili, nil),
            ("Croci a un braccio al cavo", cavoSingolo, nil),
            ("Dip per il petto", dips, nil),
            ("Piegamenti sulle braccia", nil, nil)
        ])
        + list("Dorso", [
            ("Lat machine presa larga", latMachine, nil),
            ("Lat machine presa stretta", latMachine, nil),
            ("Lat machine presa inversa", latMachine, nil),
            ("Lat machine al castello presa larga", latCastello, nil),
            ("Lat machine al castello presa neutra", latCastello, nil),
            ("Pulley presa stretta", pulley, nil),
            ("Pulley presa larga", pulley, nil),
            ("Low row", lowRow, nil),
            ("Low row a un braccio", lowRow, nil),
            ("Trazioni alla sbarra", nil, nil),
            ("Trazioni assistite presa larga", trazioniAssistite, nil),
            ("Trazioni assistite presa neutra", trazioniAssistite, nil),
            ("Rematore bilanciere", nil, olimpico),
            ("Rematore al multipower", multipower, nil),
            ("Rematore manubrio a un braccio", panca, manubri),
            ("Rematore manubri su panca inclinata", panca, manubri),
            ("Rematore a un braccio al cavo", cavoSingolo, nil),
            ("Pullover al cavo in piedi", cavoSingolo, nil),
            ("Stacco da terra", nil, olimpico),
            ("Scrollate bilanciere", nil, olimpico)
        ])
        + list("Spalle", [
            ("Lento avanti bilanciere", nil, olimpico),
            ("Lento avanti al multipower", multipower, nil),
            ("Lento dietro al multipower", multipower, nil),
            ("Lento avanti manubri seduto", panca, manubri),
            ("Lento avanti manubri in piedi", nil, manubri),
            ("Arnold press", panca, manubri),
            ("Alzate laterali manubri", nil, manubri),
            ("Alzate laterali al cavo", cavoSingolo, nil),
            ("Alzate laterali al cavo dal basso", caviRegolabili, nil),
            ("Alzate frontali manubri", nil, manubri),
            ("Alzate frontali bilanciere", nil, bilanciere),
            ("Alzate frontali al cavo", cavoSingolo, nil),
            ("Alzate posteriori manubri a busto flesso", nil, manubri),
            ("Alzate a Y su panca inclinata", panca, manubri),
            ("Croci inverse ai cavi", caviDoppi, nil),
            ("Face pull", cavoSingolo, nil),
            ("Tirate al mento bilanciere Z", nil, barraZ),
            ("Tirate al mento al cavo", cavoSingolo, nil),
            ("Scrollate manubri", nil, manubri),
            ("Scrollate al multipower", multipower, nil)
        ])
        + list("Gambe", [
            ("Squat bilanciere", nil, olimpico),
            ("Front squat", nil, olimpico),
            ("Squat al multipower", multipower, nil),
            ("Goblet squat", nil, manubri),
            ("Leg press 45°", legPress45, nil),
            ("Leg press 45° piedi stretti", legPress45, nil),
            ("Leg press orizzontale", legPressOrizz, nil),
            ("Leg extension", legExtension, nil),
            ("Leg extension a una gamba", legExtension, nil),
            ("Leg curl", legCurl, nil),
            ("Leg curl a una gamba", legCurl, nil),
            ("Affondi manubri", nil, manubri),
            ("Affondi camminati manubri", nil, manubri),
            ("Affondi al multipower", multipower, nil),
            ("Squat bulgaro manubri", panca, manubri),
            ("Step up su panca manubri", panca, manubri),
            ("Stacco rumeno bilanciere", nil, olimpico),
            ("Stacco rumeno manubri", nil, manubri),
            ("Calf in piedi al multipower", multipower, nil),
            ("Calf alla leg press", legPressOrizz, nil)
        ])
        + list("Glutei", [
            ("Hip thrust bilanciere", panca, olimpico),
            ("Hip thrust al multipower", multipower, nil),
            ("Hip thrust manubrio", panca, manubri),
            ("Hip thrust a una gamba", panca, nil),
            ("Glute bridge bilanciere", nil, olimpico),
            ("Glute bridge a corpo libero", nil, nil),
            ("Frog pump", nil, nil),
            ("Stacco sumo bilanciere", nil, olimpico),
            ("Squat sumo manubrio", nil, manubri),
            ("Good morning bilanciere", nil, olimpico),
            ("Stacco rumeno a una gamba manubrio", nil, manubri),
            ("Affondi inversi manubri", nil, manubri),
            ("Affondi laterali manubri", nil, manubri),
            ("Squat bulgaro al multipower", multipower, nil),
            ("Step up alto manubri", panca, manubri),
            ("Leg press piedi alti e larghi", legPress45, nil),
            ("Slanci posteriori al cavo", cavoSingolo, nil),
            ("Kickback al cavo in quadrupedia", cavoSingolo, nil),
            ("Abduzioni al cavo in piedi", cavoSingolo, nil),
            ("Pull through al cavo", cavoSingolo, nil)
        ])
        + list("Bicipiti", [
            ("Curl bilanciere", nil, bilanciere),
            ("Curl bilanciere presa larga", nil, olimpico),
            ("Curl bilanciere Z", nil, barraZ),
            ("Curl inverso bilanciere Z", nil, barraZ),
            ("Curl 21 bilanciere Z", nil, barraZ),
            ("Drag curl bilanciere", nil, bilanciere),
            ("Curl manubri alternato", nil, manubri),
            ("Curl a martello", nil, manubri),
            ("Curl concentrato", nil, manubri),
            ("Curl Zottman", nil, manubri),
            ("Curl su panca inclinata manubri", panca, manubri),
            ("Spider curl manubri", panca, manubri),
            ("Curl alla panca Scott bilanciere Z", pancaScott, barraZ),
            ("Curl alla panca Scott manubrio", pancaScott, manubri),
            ("Curl a martello alla panca Scott", pancaScott, manubri),
            ("Curl al cavo basso", cavoSingolo, nil),
            ("Curl a martello al cavo con corda", cavoSingolo, nil),
            ("Curl a un braccio al cavo", cavoSingolo, nil),
            ("Curl ai cavi alti", caviDoppi, nil),
            ("Curl Bayesian al cavo", caviRegolabili, nil)
        ])
        + list("Tricipiti", [
            ("Push down al cavo con barra", cavoSingolo, nil),
            ("Push down con corda", cavoSingolo, nil),
            ("Push down presa inversa", cavoSingolo, nil),
            ("Push down a un braccio", cavoSingolo, nil),
            ("Estensioni sopra la testa al cavo con corda", cavoSingolo, nil),
            ("Estensioni a un braccio sopra la testa al cavo", caviRegolabili, nil),
            ("Estensioni incrociate ai cavi", caviDoppi, nil),
            ("Kickback al cavo", cavoSingolo, nil),
            ("French press bilanciere Z", panca, barraZ),
            ("French press su panca inclinata", panca, barraZ),
            ("French press manubri", panca, manubri),
            ("Tate press manubri", panca, manubri),
            ("Estensioni sopra la testa manubrio", nil, manubri),
            ("Kickback manubrio", nil, manubri),
            ("Panca presa stretta", panca, olimpico),
            ("Panca presa stretta al multipower", multipower, nil),
            ("JM press al multipower", multipower, nil),
            ("Dip alle parallele", dips, nil),
            ("Dip su panca", panca, nil),
            ("Piegamenti presa stretta", nil, nil)
        ])
        + list("Addome", [
            ("Crunch", nil, nil),
            ("Crunch inverso", nil, nil),
            ("Bicycle crunch", nil, nil),
            ("Crunch su panca declinata", panca, nil),
            ("Crunch al cavo in ginocchio", cavoSingolo, nil),
            ("Crunch obliquo al cavo", cavoSingolo, nil),
            ("Woodchopper al cavo", cavoSingolo, nil),
            ("Pallof press al cavo", cavoSingolo, nil),
            ("Plank", nil, nil),
            ("Plank laterale", nil, nil),
            ("Hollow hold", nil, nil),
            ("Dead bug", nil, nil),
            ("Mountain climber", nil, nil),
            ("V-up", nil, nil),
            ("Leg raise a terra", nil, nil),
            ("Sollevamento gambe alla sbarra", nil, nil),
            ("Sollevamento ginocchia alle parallele", dips, nil),
            ("Russian twist manubrio", nil, manubri),
            ("Flessioni laterali manubrio", nil, manubri),
            ("Rollout con bilanciere", nil, olimpico)
        ])

    private static let seededKey = "repp.seed.exercises.v1"

    /// Inserisce il catalogo una volta sola, saltando gli esercizi con lo stesso nome già presenti.
    @MainActor
    static func insertIfNeeded(into context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        let machines = (try? context.fetch(FetchDescriptor<Machine>())) ?? []
        let equipment = (try? context.fetch(FetchDescriptor<Equipment>())) ?? []
        let existing = Set(((try? context.fetch(FetchDescriptor<Exercise>())) ?? []).map { $0.name.lowercased() })
        let machineByName = Dictionary(machines.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let equipmentByName = Dictionary(equipment.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

        for item in all where !existing.contains(item.name.lowercased()) {
            let exercise = Exercise(name: item.name, muscleGroup: item.group)
            exercise.isBuiltIn = true
            context.insert(exercise)
            exercise.defaultMachine = item.machine.flatMap { machineByName[$0] }
            exercise.defaultEquipment = item.equipment.flatMap { equipmentByName[$0] }
        }
        try? context.save()
        defaults.set(true, forKey: seededKey)
    }
}
