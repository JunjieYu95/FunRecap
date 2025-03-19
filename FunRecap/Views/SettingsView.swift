import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("studyReminders") private var studyReminders = true
    @AppStorage("reminderTime") private var reminderTime = Date.now
    @AppStorage("dailyGoal") private var dailyGoal = 5
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoArchiveCompleted") private var autoArchiveCompleted = false
    
    @State private var showResetAlert = false
    @State private var showingExportView = false
    
    @Query private var problemCount: Int {
        let descriptor = FetchDescriptor<StudyProblem>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Form {
                // Notification settings
                notificationSection
                
                // Study settings
                studySection
                
                // App settings
                appSection
                
                // Data management
                dataSection
                
                // About section
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive, action: resetAllData)
            } message: {
                Text("Are you sure you want to reset all data? This action cannot be undone.")
            }
        }
    }
    
    // Notification settings section
    private var notificationSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { newValue in
                    if newValue {
                        NotificationManager.shared.requestAuthorization()
                    }
                }
            
            if notificationsEnabled {
                Toggle("Daily Study Reminders", isOn: $studyReminders)
                
                if studyReminders {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
        }
    }
    
    // Study settings section
    private var studySection: some View {
        Section(header: Text("Study Settings")) {
            Stepper("Daily Goal: \(dailyGoal) problems", value: $dailyGoal, in: 1...20)
            
            Toggle("Auto-archive Completed", isOn: $autoArchiveCompleted)
                .foregroundColor(.primary)
            
            if autoArchiveCompleted {
                Text("Problems will be archived after 5 successful reviews with high confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // App settings section
    private var appSection: some View {
        Section(header: Text("App Settings")) {
            Toggle("Haptic Feedback", isOn: $hapticFeedback)
                .onChange(of: hapticFeedback) { newValue in
                    if newValue {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
            
            NavigationLink(destination: AppearanceSettingsView()) {
                Text("Appearance")
            }
        }
    }
    
    // Data management section
    private var dataSection: some View {
        Section(header: Text("Data Management")) {
            HStack {
                Text("Problems")
                Spacer()
                Text("\(problemCount)")
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                showingExportView = true
            }) {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
                // Import functionality would be implemented here
            }) {
                Label("Import Data", systemImage: "square.and.arrow.down")
            }
            
            Button(role: .destructive, action: {
                showResetAlert = true
            }) {
                Label("Reset All Data", systemImage: "trash")
            }
        }
    }
    
    // About section
    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: URL(string: "https://example.com/privacy")!) {
                Text("Privacy Policy")
            }
            
            Link(destination: URL(string: "https://example.com/terms")!) {
                Text("Terms of Service")
            }
            
            Link(destination: URL(string: "mailto:support@example.com")!) {
                Text("Contact Support")
            }
        }
    }
    
    // Reset all data
    private func resetAllData() {
        // Delete all problems
        let descriptor = FetchDescriptor<StudyProblem>()
        
        do {
            let problems = try modelContext.fetch(descriptor)
            for problem in problems {
                modelContext.delete(problem)
            }
            try modelContext.save()
            
            // Provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

// Appearance settings view
struct AppearanceSettingsView: View {
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("fontScale") private var fontScale: Double = 1.0
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Toggle("Use System Theme", isOn: $useSystemTheme)
                
                if !useSystemTheme {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
            }
            
            Section(header: Text("Text Size")) {
                Text("Sample Text")
                    .font(.body)
                    .scaleEffect(fontScale)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                
                HStack {
                    Text("A")
                    Slider(value: $fontScale, in: 0.8...1.5, step: 0.1)
                    Text("A").font(.title)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 