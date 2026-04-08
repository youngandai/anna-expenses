import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            KeyboardShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Text("Anna Expenses")
                .font(.headline)
            Text("Manage your tutoring business finances.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .navigationTitle("General")
    }
}

struct KeyboardShortcutsSettingsView: View {
    private let shortcuts: [(String, String)] = [
        ("Cmd+1–9", "Switch sidebar section"),
        ("Cmd+0", "Import CSV"),
        ("Cmd+N", "New item (context-aware)"),
        ("Cmd+I", "Import..."),
        ("Cmd+[", "Previous month (Dashboard / Teacher Payments)"),
        ("Cmd+]", "Next month (Dashboard / Teacher Payments)"),
        ("Cmd+U", "Check for Updates"),
        ("Cmd+,", "Settings"),
        ("Escape", "Close dialog"),
        ("Return", "Save / confirm"),
    ]

    var body: some View {
        Form {
            ForEach(shortcuts, id: \.0) { shortcut in
                HStack {
                    Text(shortcut.0)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 120, alignment: .leading)
                    Text(shortcut.1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Keyboard Shortcuts")
    }
}
