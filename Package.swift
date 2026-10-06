// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

// iOS-приложение WORK BOOKING — клиент для REST API из репозитория
// https://github.com/wmeenw/work-booking
let package = Package(
    name: "WorkBooking",
    platforms: [.iOS(.v17)],
    products: [
        .iOSApplication(
            name: "WorkBooking",
            targets: ["WorkBooking"],
            bundleIdentifier: "com.example.workbooking",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .calendar),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait],
            appCategory: .business,
            additionalInfoPlistContentFilePath: "AdditionalInfo.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "WorkBooking",
            path: "Sources/WorkBooking"
        )
    ],
    swiftLanguageModes: [.v5]
)
