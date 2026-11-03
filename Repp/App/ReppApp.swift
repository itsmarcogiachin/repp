import SwiftUI
import SwiftData

@main
struct ReppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.pink)
        }
        .modelContainer(ReppSchema.container)
    }
}

/// Tutti i modelli dell'app. I dati restano solo sul telefono (SwiftData, nessun account).
enum ReppSchema {
    static let models: [any PersistentModel.Type] = [
        Machine.self,
        Equipment.self,
        Exercise.self,
        ExerciseNote.self,
        WorkoutTemplate.self,
        TemplateExercise.self,
        WorkoutSession.self,
        SessionExercise.self,
        SessionSet.self
    ]

    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Schema(models))
        } catch {
            fatalError("Impossibile aprire il database locale: \(error)")
        }
    }()
}
