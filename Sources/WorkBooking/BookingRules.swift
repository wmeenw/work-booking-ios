import Foundation

/// Бизнес-правила из BookingServiceImpl / BookingRequest бэкенда.
/// Проверяем их и на клиенте, чтобы показать ошибку до отправки запроса.
enum BookingRules {
    static let minDurationMinutes = 15
    static let maxDurationMinutes = 240

    /// Проверки полей (@NotBlank в BookingRequest)
    static func fieldsError(roomId: String, bookedBy: String) -> String? {
        if roomId.trimmed.isEmpty { return "Выберите комнату" }
        if bookedBy.trimmed.isEmpty { return "Укажите, на кого бронируем" }
        return nil
    }

    /// Проверки времени (validateTimeRange и проверка «в будущем» в createBooking)
    static func timeError(start: Date, end: Date, now: Date = .now) -> String? {
        guard start < end else { return "Время окончания должно быть позже начала" }

        let minutes = Int(end.timeIntervalSince(start)) / 60
        if minutes < minDurationMinutes {
            return "Бронь должна длиться не меньше \(minDurationMinutes) минут"
        }
        if minutes > maxDurationMinutes {
            return "Бронь не может длиться больше \(maxDurationMinutes) минут"
        }
        if start <= now {
            return "Время начала должно быть в будущем"
        }
        return nil
    }
}
