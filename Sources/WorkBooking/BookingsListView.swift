import SwiftUI

struct BookingsListView: View {
    @Environment(BookingStore.self) private var store

    @State private var showSettings = false
    @State private var pendingCancel: Booking?

    var body: some View {
        NavigationStack {
            Group {
                if store.bookings.isEmpty && !store.isLoading {
                    ContentUnavailableView(
                        "Броней пока нет",
                        systemImage: "calendar",
                        description: Text(store.errorMessage ?? "Создайте первую бронь на вкладке «Новая бронь»")
                    )
                } else {
                    bookingList
                }
            }
            .navigationTitle("Брони")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable { await store.load() }
            .task { await store.load() }
            .sheet(isPresented: $showSettings, onDismiss: { Task { await store.load() } }) {
                SettingsView()
            }
            .alert("Отменить бронь?", isPresented: isCancelAlertShown, presenting: pendingCancel) { booking in
                Button("Отменить бронь", role: .destructive) {
                    Task { await store.cancel(booking) }
                }
                Button("Оставить", role: .cancel) {}
            } message: { booking in
                Text("\(Room.name(for: booking.roomId)), \(booking.startTime.formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    private var bookingList: some View {
        List {
            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            ForEach(daySections, id: \.day) { section in
                Section(section.day.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                    ForEach(section.bookings) { booking in
                        BookingRow(booking: booking)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingCancel = booking
                                } label: {
                                    Label("Отменить", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    /// Брони, сгруппированные по дням (как список в API, но для удобного просмотра)
    private var daySections: [(day: Date, bookings: [Booking])] {
        let grouped = Dictionary(grouping: store.bookings) { Calendar.current.startOfDay(for: $0.startTime) }
        return grouped
            .sorted { $0.key < $1.key }
            .map { (day: $0.key, bookings: $0.value) }
    }

    private var isCancelAlertShown: Binding<Bool> {
        Binding(
            get: { pendingCancel != nil },
            set: { if !$0 { pendingCancel = nil } }
        )
    }
}

private struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Room.name(for: booking.roomId))
                .font(.headline)
            Text("\(booking.startTime.formatted(date: .omitted, time: .shortened)) – \(booking.endTime.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline.monospacedDigit())
            Label(booking.bookedBy, systemImage: "person")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
