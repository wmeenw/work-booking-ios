import SwiftUI

@main
struct WorkBookingApp: App {
    @State private var store = BookingStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                BookingsListView()
                    .tabItem { Label("Брони", systemImage: "list.bullet.rectangle") }

                NewBookingView()
                    .tabItem { Label("Новая бронь", systemImage: "plus.circle") }
            }
            .environment(store)
        }
    }
}
