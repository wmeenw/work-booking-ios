import Foundation
import Observation

/// Состояние приложения: список броней и адрес сервера
@MainActor
@Observable
final class BookingStore {
    static let serverKey = "serverURL"
    static let defaultServerURL = "http://localhost:8080"

    private(set) var bookings: [Booking] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var serverURLString: String {
        didSet { UserDefaults.standard.set(serverURLString, forKey: Self.serverKey) }
    }

    init() {
        serverURLString = UserDefaults.standard.string(forKey: Self.serverKey) ?? Self.defaultServerURL
    }

    private var api: BookingAPI? {
        guard let url = URL(string: serverURLString.trimmed), url.scheme != nil else { return nil }
        return BookingAPI(baseURL: url)
    }

    func load() async {
        guard let api else {
            errorMessage = APIError.invalidURL.localizedDescription
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            bookings = sorted(try await api.fetchBookings())
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(roomId: String, bookedBy: String, start: Date, end: Date) async throws {
        guard let api else { throw APIError.invalidURL }
        let request = BookingRequest(roomId: roomId, startTime: start, endTime: end, bookedBy: bookedBy)
        let booking = try await api.createBooking(request)
        bookings = sorted(bookings + [booking])
    }

    func cancel(_ booking: Booking) async {
        guard let api else { return }
        do {
            try await api.cancelBooking(id: booking.id)
            bookings.removeAll { $0.id == booking.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isAvailable(roomId: String, start: Date, end: Date) async throws -> Bool {
        guard let api else { throw APIError.invalidURL }
        return try await api.isRoomAvailable(roomId: roomId, from: start, to: end)
    }

    private func sorted(_ list: [Booking]) -> [Booking] {
        list.sorted { $0.startTime < $1.startTime }
    }
}
