import Foundation

/// Комнаты. В бэкенде нет эндпоинта со списком комнат — roomId это произвольная строка
/// (в README пример: "room-1"), поэтому список задан здесь.
struct Room: Identifiable, Hashable {
    let id: String
    let name: String

    static let all: [Room] = (1...4).map { Room(id: "room-\($0)", name: "Переговорная \($0)") }

    static func name(for roomId: String) -> String {
        all.first { $0.id == roomId }?.name ?? roomId
    }
}

/// Ответ сервера: BookingResponse
struct Booking: Codable, Identifiable, Hashable {
    let id: Int64
    let roomId: String
    let startTime: Date
    let endTime: Date
    let bookedBy: String
}

/// Тело запроса: BookingRequest
struct BookingRequest: Encodable {
    let roomId: String
    let startTime: Date
    let endTime: Date
    let bookedBy: String
}

/// Ответ проверки доступности: AvailabilityResponse
struct AvailabilityResponse: Decodable {
    let available: Bool
}
