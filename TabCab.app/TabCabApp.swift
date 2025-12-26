import SwiftUI
import TabOrganizerUI
import TabOrganizerCore
import TabOrganizerStorage
import TabOrganizerSafariAPI

@main
struct TabCabApp: App {
    var body: some Scene {
        WindowGroup {
            GroupListView()
                .environment(ExtensionState.preview)
                .frame(minWidth: 400, minHeight: 600)
        }
    }
}
