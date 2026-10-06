import SwiftUI

struct NewBookingView: View {
    @Environment(BookingStore.self) private var store
    @AppStorage("bookedBy") private var bookedBy = ""

    @State private var roomId = Room.all[0].id
    @State private var start = NewBookingView.nextSlot()
    @State private var durationMinutes = 60

    @State private var availability: Availability = .idle
    @State private var isSaving = false
    @State private var submitError: String?
    @State private var showSuccess = false

    private enum Availability: Equatable {
        case idle, checking, free, busy
        case failed(String)
    }

    /// Ключ для .task(id:): при смене комнаты, времени или длительности проверка перезапускается
    private struct AvailabilityQuery: Equatable {
        let roomId: String
        let start: Date
        let durationMinutes: Int
    }

    private var end: Date {
        start.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    private var formError: String? {
        BookingRules.fieldsError(roomId: roomId, bookedBy: bookedBy)
            ?? BookingRules.timeError(start: start, end: end)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Кто бронирует") {
                    TextField("Имя", text: $bookedBy)
                        .textContentType(.name)
                }

                Section("Комната") {
                    Picker("Комната", selection: $roomId) {
                        ForEach(Room.all) { room in
                            Text(room.name).tag(room.id)
                        }
                    }
                }

                Section("Время") {
                    DatePicker(
                        "Начало",
                        selection: $start,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Picker("Длительность", selection: $durationMinutes) {
                        let options = Array(stride(from: BookingRules.minDurationMinutes, through: BookingRules.maxDurationMinutes, by: 15))
                        ForEach(options, id: \.self) { minutes in
                            Text(Self.durationTitle(minutes)).tag(minutes)
                        }
                    }

                    LabeledContent("Окончание", value: end.formatted(date: .omitted, time: .shortened))
                }

                Section("Доступность") {
                    availabilityLabel
                }

                if let formError {
                    Section {
                        Label(formError, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Забронировать").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(formError != nil || isSaving || availability == .busy)
                }
            }
            .navigationTitle("Новая бронь")
            .task(id: AvailabilityQuery(roomId: roomId, start: start, durationMinutes: durationMinutes)) {
                await checkAvailability()
            }
            .alert("Ошибка бронирования", isPresented: Binding(
                get: { submitError != nil },
                set: { if !$0 { submitError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(submitError ?? "")
            }
            .alert("Бронь создана", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(Room.name(for: roomId)), \(start.formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    @ViewBuilder
    private var availabilityLabel: some View {
        switch availability {
        case .idle:
            Text("Выберите время").foregroundStyle(.secondary)
        case .checking:
            HStack {
                ProgressView()
                Text("Проверяем…").foregroundStyle(.secondary)
            }
        case .free:
            Label("Комната свободна", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .busy:
            Label("На это время комната занята", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .failed(let message):
            Label(message, systemImage: "wifi.exclamationmark")
                .foregroundStyle(.orange)
        }
    }

    private func checkAvailability() async {
        // Невалидное время не отправляем — его покажет formError
        guard BookingRules.timeError(start: start, end: end) == nil else {
            availability = .idle
            return
        }

        availability = .checking
        // Небольшая пауза: при быстром перелистывании запрос не уходит на каждое значение
        try? await Task.sleep(for: .milliseconds(400))
        if Task.isCancelled { return }

        do {
            let free = try await store.isAvailable(roomId: roomId, start: start, end: end)
            availability = free ? .free : .busy
        } catch {
            availability = .failed(error.localizedDescription)
        }
    }

    private func submit() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await store.create(
                roomId: roomId,
                bookedBy: bookedBy.trimmed,
                start: start,
                end: end
            )
            showSuccess = true
            start = NewBookingView.nextSlot()
            durationMinutes = 60
        } catch {
            submitError = error.localizedDescription
        }
    }

    /// Ближайший полный час — стартовое значение формы
    private static func nextSlot() -> Date {
        let inOneHour = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return Calendar.current.dateInterval(of: .hour, for: inOneHour)?.start ?? inOneHour
    }

    private static func durationTitle(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) мин"
        case (_, 0): return "\(hours) ч"
        default: return "\(hours) ч \(rest) мин"
        }
    }
}
