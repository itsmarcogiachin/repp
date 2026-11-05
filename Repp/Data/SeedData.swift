import Foundation
import SwiftData

/// Macchine e attrezzi della palestra di partenza, inseriti al primo avvio.
/// L'utente può aggiungerne altri dall'app.
enum SeedData {
    static let machines: [String] = [
        "Panca",
        "Multipower",
        "Leg press carico diretto",
        "Leg press orizzontale",
        "Leg extension",
        "Leg curl",
        "Chest press",
        "Lat machine macchina",
        "Lat machine al castello",
        "Low row",
        "Pulley",
        "Panca Scott",
        "Cavi doppi (anche uso singolo)",
        "Cavi regolabili doppi",
        "Cavo singolo",
        "Dips",
        "Macchina per trazioni assistite"
    ]

    static let equipment: [(name: String, weightKg: Double?)] = [
        ("Manubri", nil),
        ("Bilanciere olimpico", 20),
        ("Bilanciere", 10),
        ("Bilanciere Z", 8),
        ("Maniglia", nil),
        ("Corda", nil),
        ("Sbarra corta", nil),
        ("Sbarra larga", nil),
        ("Presa stretta", nil)
    ]

    /// Inserisce i dati di partenza solo se il database è vuoto.
    @MainActor
    static func insertIfNeeded(into context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Machine>())) ?? 0
        guard existing == 0 else { return }

        for name in machines {
            context.insert(Machine(name: name, isBuiltIn: true))
        }
        for item in equipment {
            context.insert(Equipment(name: item.name, weightKg: item.weightKg, isBuiltIn: true))
        }
        try? context.save()
    }

    /// Aggiunge gli attrezzi di partenza che mancano (per chi aveva già l'app prima che fossero aggiunti).
    @MainActor
    static func addMissingEquipment(into context: ModelContext) {
        let existing = Set(((try? context.fetch(FetchDescriptor<Equipment>())) ?? []).map { $0.name.lowercased() })
        for item in equipment where !existing.contains(item.name.lowercased()) {
            context.insert(Equipment(name: item.name, weightKg: item.weightKg, isBuiltIn: true))
        }
        try? context.save()
    }
}
