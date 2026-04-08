import SwiftUI
#if !DEBUG
import Sparkle
#endif

@main
struct AnnaExpensesApp: App {
    @State private var store = DataStore()
    #if !DEBUG
    private let updaterController: SPUStandardUpdaterController
    #endif

    init() {
        #if !DEBUG
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .commands {
            #if !DEBUG
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            #endif

            // Navigation shortcuts
            CommandMenu("Navigate") {
                ForEach(Array(SidebarSection.allCases.enumerated()), id: \.element) { index, section in
                    if index < 9 {
                        Button(section.rawValue) {
                            NotificationCenter.default.post(
                                name: .navigateToSection,
                                object: section
                            )
                        }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                    }
                }
                Button("Import CSV") {
                    NotificationCenter.default.post(
                        name: .navigateToSection,
                        object: SidebarSection.importCSV
                    )
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            // Item actions — replaces default "New Window" (⌘N)
            CommandGroup(replacing: .newItem) {
                Button("New Item") {
                    NotificationCenter.default.post(name: .triggerAddItem, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Import...") {
                    NotificationCenter.default.post(
                        name: .navigateToSection,
                        object: SidebarSection.importCSV
                    )
                }
                .keyboardShortcut("i", modifiers: .command)

                Divider()

                Button("Previous Month") {
                    NotificationCenter.default.post(name: .navigatePreviousMonth, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)

                Button("Next Month") {
                    NotificationCenter.default.post(name: .navigateNextMonth, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(store)
        }
    }
}

extension Notification.Name {
    static let navigateToSection = Notification.Name("navigateToSection")
    static let navigatePreviousMonth = Notification.Name("navigatePreviousMonth")
    static let navigateNextMonth = Notification.Name("navigateNextMonth")
}
