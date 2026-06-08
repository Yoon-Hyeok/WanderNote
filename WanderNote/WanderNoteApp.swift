import SwiftUI
import SwiftData

@main
struct WanderNoteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        .modelContainer(for: TravelRecord.self)
    }
}
