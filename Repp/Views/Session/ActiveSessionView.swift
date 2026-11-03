import SwiftUI
import SwiftData

/// Allenamento in corso: un esercizio alla volta, serie con carico totale e ripetizioni, faccine e timer di riposo.
struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Bindable var session: WorkoutSession
    let onFinish: (WorkoutSession) -> Void

    @State private var currentID: UUID?
    @State private var kgText = ""
    @State private var repsText = ""
    @State private var qualitySetID: UUID?
    @State private var sheet: SessionSheet?
    @State private var confirmingEnd = false
    @State private var restFinishedTick = 0
    @AppStorage("repp.rest.endsAt") private var restEndsAt: Double = 0
    @AppStorage("repp.rest.total") private var restTotal: Int = 0

    private enum SessionSheet: String, Identifiable {
        case substitute, machine, notes, addExercise
        var id: String { rawValue }
    }

    private var rows: [SessionExercise] { session.orderedExercises }

    private var current: SessionExercise? {
        rows.first { $0.id == currentID } ?? rows.first
    }

    private var currentIndex: Int {
        guard let current else { return 0 }
        return rows.firstIndex { $0.id == current.id } ?? 0
    }

    private var kg: Double {
        Double(kgText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var reps: Int {
        Int(repsText) ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)
            exerciseStrip
                .padding(.vertical, 12)

            ScrollView {
                if let current {
                    ExerciseSessionCard(
                        row: current,
                        session: session,
                        qualitySetID: qualitySetID,
                        isLast: currentIndex == rows.count - 1,
                        onSubstitute: { sheet = .substitute },
                        onMachine: { sheet = .machine },
                        onNotes: { sheet = .notes },
                        onNext: goToNext,
                        onQuality: setQuality,
                        onDeleteSet: deleteSet
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                Button {
                    sheet = .addExercise
                } label: {
                    Label("Aggiungi un esercizio solo per oggi", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.silver)
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            bottomPanel
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            if currentID == nil {
                currentID = (rows.first { $0.sets.count < $0.targetSets } ?? rows.first)?.id
            }
        }
        .onChange(of: current?.id, initial: true) { prefill() }
        .onChange(of: current?.exercise?.id) { prefill() }
        .onChange(of: current?.machine?.id) { prefill() }
        .task(id: restEndsAt) {
            let wait = restEndsAt - Date.now.timeIntervalSince1970
            guard wait > 0 else { return }
            try? await Task.sleep(for: .seconds(wait))
            if !Task.isCancelled { restFinishedTick += 1 }
        }
        .sensoryFeedback(.success, trigger: restFinishedTick)
        .sheet(item: $sheet) { kind in
            if let current {
                switch kind {
                case .substitute:
                    SubstituteSheet(row: current) { exercise in
                        let isOriginal = exercise.id == current.plannedItem?.exercise?.id
                        apply(
                            to: current,
                            exercise: exercise,
                            machine: isOriginal ? current.plannedItem?.machine : exercise.defaultMachine,
                            equipment: isOriginal ? current.plannedItem?.equipment : exercise.defaultEquipment
                        )
                    }
                case .machine:
                    MachineSheet(row: current, session: session) { machine, equipment in
                        if let exercise = current.exercise {
                            apply(to: current, exercise: exercise, machine: machine, equipment: equipment)
                        }
                    }
                case .notes:
                    if let exercise = current.exercise {
                        NotesSheet(exercise: exercise, session: session)
                    }
                case .addExercise:
                    ExercisePickerView(alreadyInTemplate: Set(rows.compactMap { $0.exercise?.id })) { exercises in
                        addForToday(exercises)
                    }
                }
            }
        }
        .confirmationDialog("Terminare l'allenamento?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("Termina e salva") { finish() }
            Button("Annulla allenamento", role: .destructive) { discard() }
            Button("Continua", role: .cancel) {}
        } message: {
            Text("Gli esercizi senza serie non finiscono nello storico.")
        }
    }

    // MARK: - Parti della schermata

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.template?.name ?? "Allenamento")
                    .font(.display(28))
                    .metallic()
                HStack(spacing: 6) {
                    Text("Esercizio \(currentIndex + 1) di \(rows.count) ·")
                    TimelineView(.periodic(from: session.startedAt, by: 1)) { context in
                        Text(Self.elapsed(from: session.startedAt, to: context.date))
                            .monospacedDigit()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button("Termina") { confirmingEnd = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
        }
    }

    private var exerciseStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        let isCurrent = row.id == current?.id
                        let isDone = row.sets.count >= row.targetSets
                        Button {
                            currentID = row.id
                        } label: {
                            HStack(spacing: 6) {
                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                }
                                Text(row.exercise?.name ?? "Esercizio")
                                    .lineLimit(1)
                                if row.isExerciseSubstitution || row.isMachineChange {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption2)
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 36)
                            .foregroundStyle(isCurrent ? Theme.background : (isDone ? Theme.textSecondary : Theme.text))
                            .background {
                                if isCurrent {
                                    Capsule().fill(Theme.metal)
                                } else {
                                    Capsule().fill(Theme.surface).overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .id(row.id)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: current?.id) { _, id in
                guard let id else { return }
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    private var bottomPanel: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remaining = Int((restEndsAt - timeline.date.timeIntervalSince1970).rounded(.up))
            VStack(spacing: 14) {
                if remaining > 0 {
                    restPanel(remaining: remaining)
                } else {
                    logPanel
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(Theme.surface.ignoresSafeArea(edges: .bottom))
        }
    }

    private func restPanel(remaining: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                SectionLabel("Riposo · \(nextLabel)")
                Spacer()
            }
            HStack(alignment: .center, spacing: 12) {
                Text(remaining.restString)
                    .font(.display(56))
                    .monospacedDigit()
                    .metallic()
                    .contentTransition(.numericText(countsDown: true))
                Spacer()
                Button("−15") { adjustRest(by: -15) }
                    .buttonStyle(RestControlStyle())
                Button("+15") { adjustRest(by: 15) }
                    .buttonStyle(RestControlStyle())
            }
            ProgressView(value: Double(max(restTotal - remaining, 0)), total: Double(max(restTotal, 1)))
                .tint(Theme.silver)
            Button("Salta il riposo") { skipRest() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.silver)
                .frame(minHeight: 36)
        }
    }

    private var logPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ValueField(title: "Carico totale (kg)", text: $kgText, keyboard: .decimalPad, step: 2.5)
                ValueField(title: "Ripetizioni", text: $repsText, keyboard: .numberPad, step: 1)
            }
            Button(logButtonTitle, action: logSet)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(current == nil || reps <= 0)
                .opacity(current == nil || reps <= 0 ? 0.4 : 1)
        }
    }

    private var logButtonTitle: String {
        guard let current else { return "Segna serie" }
        let next = (current.sets.map(\.setNumber).max() ?? 0) + 1
        return "Segna serie \(next) di \(max(current.targetSets, next))"
    }

    private var nextLabel: String {
        guard let current else { return "" }
        let done = current.sets.count
        if done < current.targetSets {
            return "poi serie \(done + 1) di \(current.exercise?.name ?? "")"
        }
        if currentIndex + 1 < rows.count, let name = rows[currentIndex + 1].exercise?.name {
            return "poi \(name)"
        }
        return "ultimo esercizio fatto"
    }

    // MARK: - Azioni

    private func prefill() {
        guard let row = current else { return }
        if let last = row.orderedSets.last {
            kgText = last.weightKg.kgString
            repsText = "\(last.reps)"
        } else if let key = row.historyKey,
                  let previous = SessionHistory.lastPerformance(of: key, in: context, excluding: session),
                  let first = previous.orderedSets.first {
            kgText = first.weightKg.kgString
            repsText = "\(first.reps)"
        } else {
            let isPlanned = !row.isExerciseSubstitution && !row.isMachineChange
            kgText = (isPlanned ? row.plannedItem?.targetWeightKg : nil)?.kgString ?? ""
            repsText = "\(row.plannedItem?.targetReps ?? 8)"
        }
    }

    private func logSet() {
        guard let row = current, reps > 0 else { return }
        let number = (row.sets.map(\.setNumber).max() ?? 0) + 1
        let rest = row.orderedSets.last.map { Int(Date.now.timeIntervalSince($0.completedAt)) }
        let set = SessionSet(setNumber: number, weightKg: kg, reps: reps, restSeconds: rest)
        context.insert(set)
        set.sessionExercise = row
        qualitySetID = set.id
        hideKeyboard()
        startRest(seconds: row.restSeconds)
    }

    private func setQuality(_ set: SessionSet, _ quality: SetQuality) {
        set.quality = quality
        if set.id == qualitySetID { qualitySetID = nil }
    }

    private func deleteSet(_ set: SessionSet) {
        guard let row = set.sessionExercise else { return }
        context.delete(set)
        let remaining = row.orderedSets.filter { $0.id != set.id }
        for (index, item) in remaining.enumerated() { item.setNumber = index + 1 }
        if qualitySetID == set.id { qualitySetID = nil }
    }

    private func goToNext() {
        guard currentIndex + 1 < rows.count else { return }
        currentID = rows[currentIndex + 1].id
    }

    /// Cambia esercizio, macchina o attrezzo solo per oggi. Se ci sono già serie fatte restano dov'erano
    /// e si continua su una riga nuova, così lo storico registra entrambe le cose.
    private func apply(to row: SessionExercise, exercise: Exercise, machine: Machine?, equipment: Equipment?) {
        if row.sets.isEmpty {
            row.exercise = exercise
            row.machine = machine
            row.equipment = equipment
        } else {
            for other in rows where other.position > row.position {
                other.position += 1
            }
            let newRow = SessionExercise(position: row.position + 1)
            context.insert(newRow)
            newRow.configure(session: session, plannedItem: row.plannedItem, exercise: exercise, machine: machine, equipment: equipment)
            currentID = newRow.id
        }
        prefill()
    }

    private func addForToday(_ exercises: [Exercise]) {
        var position = (rows.map(\.position).max() ?? -1) + 1
        var firstID: UUID?
        for exercise in exercises {
            let row = SessionExercise(position: position)
            context.insert(row)
            row.configure(session: session, plannedItem: nil, exercise: exercise, machine: exercise.defaultMachine, equipment: exercise.defaultEquipment)
            firstID = firstID ?? row.id
            position += 1
        }
        if let firstID { currentID = firstID }
    }

    private func startRest(seconds: Int) {
        restTotal = seconds
        restEndsAt = Date.now.addingTimeInterval(TimeInterval(seconds)).timeIntervalSince1970
        RestNotifier.schedule(at: Date(timeIntervalSince1970: restEndsAt), nextSet: nextLabel.capitalizedFirst)
    }

    private func adjustRest(by delta: Int) {
        let now = Date.now.timeIntervalSince1970
        restEndsAt = max(now, restEndsAt + TimeInterval(delta))
        restTotal = max(restTotal + delta, 1)
        if restEndsAt > now {
            RestNotifier.schedule(at: Date(timeIntervalSince1970: restEndsAt), nextSet: nextLabel.capitalizedFirst)
        } else {
            RestNotifier.cancel()
        }
    }

    private func skipRest() {
        restEndsAt = 0
        RestNotifier.cancel()
    }

    private func finish() {
        skipRest()
        let hasSets = rows.contains { !$0.sets.isEmpty }
        for row in rows where row.sets.isEmpty {
            context.delete(row)
        }
        if !hasSets {
            context.delete(session)
            try? context.save()
            return
        }
        session.endedAt = .now
        try? context.save()
        onFinish(session)
    }

    private func discard() {
        skipRest()
        context.delete(session)
        try? context.save()
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    static func elapsed(from start: Date, to now: Date) -> String {
        let total = max(Int(now.timeIntervalSince(start)), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Scheda dell'esercizio in corso

private struct ExerciseSessionCard: View {
    @Environment(\.modelContext) private var context
    let row: SessionExercise
    let session: WorkoutSession
    let qualitySetID: UUID?
    let isLast: Bool
    let onSubstitute: () -> Void
    let onMachine: () -> Void
    let onNotes: () -> Void
    let onNext: () -> Void
    let onQuality: (SessionSet, SetQuality) -> Void
    let onDeleteSet: (SessionSet) -> Void

    private var notes: [ExerciseNote] {
        (row.exercise?.notes ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    private var visibleNotes: [ExerciseNote] {
        // Le fissate prima: sono le indicazioni che valgono sempre.
        notes.filter { $0.isPinned || $0.session?.id == session.id }
            .sorted { $0.isPinned && !$1.isPinned }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(row.exercise?.name ?? "Esercizio")
                    .font(.display(26, weight: .bold))
                    .metallic()
                if row.isExerciseSubstitution, let planned = row.plannedItem?.exercise {
                    Label("Solo oggi al posto di \(planned.name)", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.pinkText)
                } else if row.isMachineChange {
                    Label("Solo oggi su un'altra macchina", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.pinkText)
                } else if row.plannedItem == nil {
                    Text("Aggiunto solo per oggi")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.pinkText)
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 8) {
                if row.plannedItem != nil {
                    CardAction(title: "Sostituisci", systemImage: "arrow.triangle.2.circlepath", action: onSubstitute)
                }
                CardAction(title: "Macchina", systemImage: "gearshape.2", action: onMachine)
                CardAction(title: notes.isEmpty ? "Note" : "Note (\(notes.count))", systemImage: "note.text", action: onNotes)
            }

            ForEach(visibleNotes) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                        .font(.caption)
                        .foregroundStyle(Theme.silver)
                        .padding(.top, 3)
                    Text(note.text)
                        .font(.subheadline)
                        .foregroundStyle(Theme.text)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let lastTime = lastTimeText {
                lastTimeBanner(lastTime)
            }

            setsTable

            if row.sets.count >= row.targetSets && !isLast {
                Button("Prossimo esercizio", action: onNext)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var subtitle: String {
        var parts: [String] = []
        if let setup = row.setupLabel { parts.append(setup) }
        if let item = row.plannedItem, !row.isExerciseSubstitution {
            if let reps = item.targetReps {
                parts.append("obiettivo \(item.targetSets) × \(reps)")
            } else {
                parts.append("obiettivo \(item.targetSets) serie")
            }
        }
        parts.append("riposo \(row.restSeconds.restString)")
        return parts.joined(separator: " · ")
    }

    /// Testo "Ultima volta": dice se l'esercizio della scheda era stato sostituito o fatto su un'altra macchina.
    private var lastTimeText: (title: String, detail: String, highlighted: Bool)? {
        var result: (String, String, Bool)?
        var shownRowID: UUID?
        if let item = row.plannedItem, let last = SessionHistory.lastTime(for: item, excluding: session) {
            let day = last.date.shortDay
            if let sub = last.rows.first(where: \.isExerciseSubstitution) {
                let detail = ["con \(sub.exercise?.name ?? "un altro esercizio")", sub.setupLabel, sub.setsSummary].compactMap { $0 }.joined(separator: " · ")
                result = ("Ultima volta (\(day)) l'hai sostituito", detail, true)
                shownRowID = sub.id
            } else if let change = last.rows.first(where: \.isMachineChange) {
                let detail = ["su \(change.machine?.name ?? "nessuna macchina")", change.setsSummary].joined(separator: " · ")
                result = ("Ultima volta (\(day)) hai cambiato macchina", detail, true)
                shownRowID = change.id
            } else if let same = last.rows.first {
                result = ("Ultima volta (\(day))", same.setsSummary, false)
                shownRowID = same.id
            }
        }
        // Se oggi è una variante, conta lo storico di questo esercizio su questa macchina,
        // a meno che sia proprio la riga già descritta sopra.
        if row.isExerciseSubstitution || row.isMachineChange || row.plannedItem == nil,
           let key = row.historyKey,
           let previous = SessionHistory.lastPerformance(of: key, in: context, excluding: session),
           previous.id != shownRowID {
            let name = [row.exercise?.name, row.machine.map { "su \($0.name)" }].compactMap { $0 }.joined(separator: " ")
            let line = "\(name): \(previous.session?.startedAt.shortDay ?? "") · \(previous.setsSummary)"
            if let current = result {
                result = (current.0, current.1 + "\nCon questa variante: " + line, current.2)
            } else {
                result = ("Con questa variante", line, false)
            }
        }
        return result.map { (title: $0.0, detail: $0.1, highlighted: $0.2) }
    }

    private func lastTimeBanner(_ info: (title: String, detail: String, highlighted: Bool)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(info.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(info.highlighted ? Theme.pinkText : Theme.text)
            Text(info.detail)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(info.highlighted ? Theme.pink.opacity(0.6) : Theme.line, lineWidth: 1)
        }
    }

    private var setsTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Serie").frame(width: 48, alignment: .leading)
                Text("Kg").frame(maxWidth: .infinity, alignment: .leading)
                Text("Rip.").frame(width: 56, alignment: .leading)
                Text("Qualità").frame(width: 88, alignment: .trailing)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.textSecondary)
            .padding(.bottom, 8)

            if row.sets.isEmpty {
                Text("Nessuna serie ancora. Segna la prima qui sotto.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }

            ForEach(row.orderedSets) { set in
                VStack(spacing: 10) {
                    HStack {
                        Text("\(set.setNumber)")
                            .frame(width: 48, alignment: .leading)
                            .foregroundStyle(Theme.textSecondary)
                        Text(set.weightKg.kgString)
                            .font(.headline)
                            .metallic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(set.reps)")
                            .font(.headline)
                            .frame(width: 56, alignment: .leading)
                        HStack(spacing: 6) {
                            if let quality = set.quality {
                                QualityFace(quality: quality, size: 22)
                                Text(quality.label)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            } else {
                                Text("—").foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .frame(width: 88, alignment: .trailing)
                    }
                    .monospacedDigit()
                    .contentShape(Rectangle())
                    .contextMenu {
                        ForEach(SetQuality.allCases) { quality in
                            Button(quality.label) { onQuality(set, quality) }
                        }
                        Button("Elimina serie", role: .destructive) { onDeleteSet(set) }
                    }

                    if set.id == qualitySetID {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Com'è andata la serie \(set.setNumber)?")
                                .font(.subheadline.weight(.semibold))
                            QualityPicker(selected: set.quality) { onQuality(set, $0) }
                        }
                    }
                }
                .padding(.vertical, 8)
                Divider().overlay(Theme.line)
            }
        }
    }
}

private struct CardAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        // Icona sopra il testo: affiancati, "Sostituisci" e "Macchina" venivano troncati su iPhone.
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.body)
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Campo numerico con − e + ai lati.
private struct ValueField: View {
    let title: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 4) {
                Button { change(by: -step) } label: {
                    Image(systemName: "minus").frame(width: 36, height: 44)
                }
                .accessibilityLabel("Meno")
                TextField("0", text: $text)
                    .keyboardType(keyboard)
                    .multilineTextAlignment(.center)
                    .font(.display(24, weight: .bold))
                    .monospacedDigit()
                Button { change(by: step) } label: {
                    Image(systemName: "plus").frame(width: 36, height: 44)
                }
                .accessibilityLabel("Più")
            }
            .foregroundStyle(Theme.text)
            .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func change(by delta: Double) {
        let value = Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
        text = max(value + delta, 0).kgString
    }
}

private struct RestControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.text)
            .frame(width: 56, height: 44)
            .background(Theme.surface2.opacity(configuration.isPressed ? 0.6 : 1), in: Capsule())
            .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}

extension String {
    /// "poi serie 2" → "Poi serie 2"
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
