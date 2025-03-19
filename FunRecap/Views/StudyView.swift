import SwiftUI
import SwiftData

struct StudyView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var dueProblems: [StudyProblem]
    
    @State private var selectedProblem: StudyProblem?
    @State private var isShowingReview = false
    @State private var isStudyCompleted = false
    
    // Filter for due problems
    init() {
        let now = Date()
        let predicate = #Predicate<StudyProblem> { $0.nextReview <= now }
        _dueProblems = Query(filter: predicate, sort: \.nextReview)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if dueProblems.isEmpty {
                    emptyStateView
                } else {
                    problemListView
                }
            }
            .navigationTitle("Study")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectRandomProblem()
                    }) {
                        Image(systemName: "shuffle")
                    }
                    .disabled(dueProblems.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingReview, onDismiss: {
                selectedProblem = nil
                checkForCompletedStudy()
            }) {
                if let problem = selectedProblem {
                    ProblemReviewView(problem: problem)
                }
            }
            .alert("Study Completed", isPresented: $isStudyCompleted) {
                Button("Great!", role: .cancel) { }
            } message: {
                Text("You've reviewed all your due problems. Nice work!")
            }
        }
    }
    
    // View when there are no due problems
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Caught Up!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You don't have any problems due for review right now.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Switch to random practice mode
                if let problem = DataManager.shared.selectRandomProblem() {
                    selectedProblem = problem
                    isShowingReview = true
                }
            }) {
                Text("Practice Random Problem")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
            .disabled(DataManager.shared.getAllProblems().isEmpty)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // List of due problems
    private var problemListView: some View {
        List {
            Section(header: Text("Due for Review (\(dueProblems.count))")) {
                ForEach(dueProblems) { problem in
                    ProblemRow(problem: problem)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProblem = problem
                            isShowingReview = true
                        }
                }
            }
            
            // Button to start a study session with all due problems
            Section {
                Button(action: {
                    startStudySession()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Study Session")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .contentShape(Rectangle())
                }
            }
        }
    }
    
    // Select a random problem for review
    private func selectRandomProblem() {
        if let problem = DataManager.shared.selectRandomProblem() {
            selectedProblem = problem
            isShowingReview = true
        }
    }
    
    // Start a sequential study session with all due problems
    private func startStudySession() {
        if !dueProblems.isEmpty {
            selectedProblem = dueProblems[0]
            isShowingReview = true
        }
    }
    
    // Check if all problems have been studied
    private func checkForCompletedStudy() {
        let now = Date()
        let stillDueProblems = dueProblems.filter { $0.nextReview <= now }
        
        if !stillDueProblems.isEmpty {
            // There are still problems due, but the user finished the review
            // We could auto-start the next problem here
        } else if !dueProblems.isEmpty {
            // All problems have been reviewed
            isStudyCompleted = true
        }
    }
}

// Row for a problem in the list
struct ProblemRow: View {
    let problem: StudyProblem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(problem.question)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                // Due time
                if problem.nextReview <= Date() {
                    Label("Due now", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Label(
                        relativeTimeString(from: problem.nextReview),
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence indicator (stars)
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < Int(problem.confidence) ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(i < Int(problem.confidence) ? .yellow : .gray)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Format relative time
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Problem review view - shown as a sheet
struct ProblemReviewView: View {
    let problem: StudyProblem
    
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAnswer = false
    @State private var confidenceRating = 0
    @State private var success = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question section
                    questionSection
                    
                    // Answer section (only shown when revealed)
                    if isShowingAnswer {
                        answerSection
                    }
                    
                    // Action buttons
                    actionButtons
                    
                    // Rating section (only shown when answer is revealed)
                    if isShowingAnswer {
                        ratingSection
                    }
                }
                .padding()
            }
            .navigationTitle("Review Problem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if isShowingAnswer {
                            submitReview()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // Question display
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Question")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(problem.question)
                .font(.title3)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }
    
    // Answer display
    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Answer")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(problem.solution)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
    }
    
    // Action buttons
    private var actionButtons: some View {
        VStack(spacing: 15) {
            if !isShowingAnswer {
                Button(action: {
                    withAnimation {
                        isShowingAnswer = true
                    }
                }) {
                    Text("Show Answer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // Confidence rating section
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("How well did you know this?")
                .font(.headline)
            
            // Did you get it right toggle
            Toggle(isOn: $success) {
                Text("I got this right")
                    .font(.subheadline)
            }
            .padding(.bottom, 5)
            
            // Star rating
            Text("Confidence level:")
                .font(.subheadline)
            
            HStack {
                ForEach(1...5, id: \.self) { rating in
                    Image(systemName: rating <= confidenceRating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundColor(rating <= confidenceRating ? .yellow : .gray)
                        .onTapGesture {
                            confidenceRating = rating
                        }
                }
            }
            .padding(.bottom)
            
            // Submit button
            Button(action: {
                submitReview()
            }) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(confidenceRating > 0 ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(confidenceRating == 0)
        }
    }
    
    // Submit the review
    private func submitReview() {
        do {
            try DataManager.shared.updateProblemAfterReview(
                id: problem.id,
                success: success,
                confidenceRating: confidenceRating
            )
            
            // Provide haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            dismiss()
        } catch {
            print("Error updating problem: \(error.localizedDescription)")
        }
    }
} 