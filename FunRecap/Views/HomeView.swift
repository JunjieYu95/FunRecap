import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var problems: [StudyProblem]
    @Query private var dueProblems: [StudyProblem]
    
    @State private var selectedProblem: StudyProblem?
    @State private var isShowingReview = false
    
    // Filter for due problems
    init() {
        let now = Date()
        let predicate = #Predicate<StudyProblem> { $0.nextReview <= now }
        _dueProblems = Query(filter: predicate)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    headerSection
                    
                    // Stats section
                    statsSection
                    
                    // Due problems section
                    dueProblemsSection
                    
                    // Quick actions
                    actionButtons
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("FunRecap")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.isAddingProblem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingReview, onDismiss: {
                selectedProblem = nil
            }) {
                if let problem = selectedProblem {
                    ProblemReviewView(problem: problem)
                        .environmentObject(appState)
                }
            }
        }
    }
    
    // Header with welcome message and current stats
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to FunRecap")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your spaced repetition learning companion")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    // Stats summary section
    private var statsSection: some View {
        VStack(spacing: 15) {
            HStack {
                statCard(
                    title: "Total",
                    value: "\(problems.count)",
                    icon: "books.vertical",
                    color: .blue
                )
                
                statCard(
                    title: "Due Today",
                    value: "\(dueProblems.count)",
                    icon: "clock",
                    color: .orange
                )
            }
            
            HStack {
                statCard(
                    title: "Completed",
                    value: "\(completedCount)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                statCard(
                    title: "Streak",
                    value: "\(calculateStreak()) days",
                    icon: "flame",
                    color: .red
                )
            }
        }
    }
    
    // Individual stat card
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // Due problems section
    private var dueProblemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Due for Review")
                .font(.headline)
            
            if dueProblems.isEmpty {
                Text("No problems due right now")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(dueProblems.prefix(3)) { problem in
                    DueProblemCard(problem: problem)
                        .onTapGesture {
                            selectedProblem = problem
                            isShowingReview = true
                        }
                }
                
                if dueProblems.count > 3 {
                    Button(action: {
                        appState.selectedTab = 1 // Go to Study tab
                    }) {
                        Text("See all \(dueProblems.count) due problems")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
            }
        }
    }
    
    // Action buttons
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                startQuickStudy()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Quick Study Session")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                appState.isAddingProblem = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add New Problem")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    // Start a quick study session with a random problem
    private func startQuickStudy() {
        if let problem = DataManager.shared.selectRandomProblem() {
            selectedProblem = problem
            isShowingReview = true
        }
    }
    
    // Helper properties and methods
    
    // Count of completed problems (problems with at least one successful attempt)
    private var completedCount: Int {
        problems.filter { problem in
            problem.attempts.contains { $0.success }
        }.count
    }
    
    // Calculate current streak (simplified implementation)
    private func calculateStreak() -> Int {
        // For the initial implementation, we'll return a placeholder value
        // In a real app, you'd track daily usage and calculate the actual streak
        return 3
    }
}

// Card view for due problems
struct DueProblemCard: View {
    let problem: StudyProblem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(problem.question)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Label(
                    timeRemainingText,
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundColor(.orange)
                
                Spacer()
                
                // Difficulty indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < problem.difficulty ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(i < problem.difficulty ? .yellow : .gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // Format the time remaining text
    private var timeRemainingText: String {
        let now = Date()
        
        if problem.nextReview < now {
            return "Due now"
        }
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: now, to: problem.nextReview)
        
        if let hours = components.hour, hours > 0 {
            return "Due in \(hours) hour\(hours == 1 ? "" : "s")"
        } else if let minutes = components.minute, minutes > 0 {
            return "Due in \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "Due now"
        }
    }
} 