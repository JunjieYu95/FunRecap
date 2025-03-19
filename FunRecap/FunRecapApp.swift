import SwiftUI
import SwiftData

@main
struct FunRecapApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Request notification permissions
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(for: [StudyProblem.self, AttemptHistory.self])
    }
}

// App-wide state management
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var isAddingProblem: Bool = false
    @Published var selectedProblemID: UUID?
    
    func showProblem(_ id: UUID) {
        selectedProblemID = id
        selectedTab = 1 // Assuming 1 is the Study tab
    }
} 