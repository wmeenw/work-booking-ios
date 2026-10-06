import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Бэкенд работает с LocalDateTime — без часового пояса: "2026-09-10T10:00:00".
/// Используем локальную зону телефона, чтобы время, которое выбрал пользователь,
/// совпадало с тем, что уходит на сервер и приходит обратно.
enum WireDate {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from text: String) -> Date? {
        // Jackson может добавить дробную часть секунд ("…:00.123456") — она нам не нужна
        formatter.date(from: String(text.prefix(19)))
    }
}
