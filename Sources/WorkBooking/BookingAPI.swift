import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unreachable(URL)
    case server(status: Int, message: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный адрес сервера"
        case .unreachable(let url):
            return "Нет связи с сервером \(url.absoluteString). Запущен ли Spring Boot?"
        case .server(_, let message):
            return message
        case .invalidResponse:
            return "Сервер вернул неожиданный ответ"
        }
    }
}

/// Клиент для REST API бэкенда (см. README репозитория)
struct BookingAPI {
    let baseURL: URL
    var session: URLSession = .shared

    private static let decoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom { dec in
            let text = try dec.singleValueContainer().decode(String.self)
            guard let date = WireDate.date(from: text) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: dec.codingPath, debugDescription: "Неверная дата: \(text)")
                )
            }
            return date
        }
        return jsonDecoder
    }()

    private static let encoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .custom { date, enc in
            var container = enc.singleValueContainer()
            try container.encode(WireDate.string(from: date))
        }
        return jsonEncoder
    }()

    /// GET /api/bookings
    func fetchBookings() async throws -> [Booking] {
        let data = try await perform("api/bookings")
        return try Self.decoder.decode([Booking].self, from: data)
    }

    /// POST /api/bookings → 201 Created
    func createBooking(_ request: BookingRequest) async throws -> Booking {
        let body = try Self.encoder.encode(request)
        let data = try await perform("api/bookings", method: "POST", body: body)
        return try Self.decoder.decode(Booking.self, from: data)
    }

    /// DELETE /api/bookings/{id} → 204 No Content
    func cancelBooking(id: Int64) async throws {
        _ = try await perform("api/bookings/\(id)", method: "DELETE")
    }

    /// GET /api/rooms/{roomId}/availability?from=...&to=...
    func isRoomAvailable(roomId: String, from: Date, to: Date) async throws -> Bool {
        let data = try await perform(
            "api/rooms/\(roomId)/availability",
            query: [
                URLQueryItem(name: "from", value: WireDate.string(from: from)),
                URLQueryItem(name: "to", value: WireDate.string(from: to))
            ]
        )
        return try Self.decoder.decode(AvailabilityResponse.self, from: data).available
    }

    private func perform(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> Data {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.unreachable(baseURL)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(status: http.statusCode, message: Self.errorMessage(from: data, status: http.statusCode))
        }
        return data
    }

    /// Бэкенд отдаёт ошибки двух видов:
    /// • бизнес-логика (400/404/409): {"timestamp", "status", "error", "message"}
    /// • валидация (400): {"поле": "сообщение"}
    private static func errorMessage(from data: Data, status: Int) -> String {
        if let body = try? JSONDecoder().decode(ErrorBody.self, from: data), let message = body.message {
            return message
        }
        if let fields = try? JSONDecoder().decode([String: String].self, from: data), !fields.isEmpty {
            return fields.values.sorted().joined(separator: "\n")
        }
        return "Ошибка сервера (\(status))"
    }

    private struct ErrorBody: Decodable {
        let message: String?
    }
}
