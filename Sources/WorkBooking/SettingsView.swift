import SwiftUI

struct SettingsView: View {
    @Environment(BookingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var checkResult: String?
    @State private var isChecking = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    TextField(BookingStore.defaultServerURL, text: $store.serverURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Адрес сервера")
                } footer: {
                    Text("В симуляторе используйте localhost. На реальном устройстве укажите IP компьютера в той же сети, например http://192.168.1.10:8080.")
                }

                Section {
                    Button {
                        Task { await checkConnection() }
                    } label: {
                        HStack {
                            Text("Проверить соединение")
                            Spacer()
                            if isChecking { ProgressView() }
                        }
                    }
                    .disabled(isChecking)

                    if let checkResult {
                        Text(checkResult)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func checkConnection() async {
        isChecking = true
        defer { isChecking = false }

        await store.load()
        if let error = store.errorMessage {
            checkResult = error
        } else {
            checkResult = "Соединение есть. Броней на сервере: \(store.bookings.count)"
        }
    }
}
