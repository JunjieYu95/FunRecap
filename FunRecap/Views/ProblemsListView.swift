import SwiftUI
import SwiftData

struct ProblemsListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \.lastReviewed, order: .reverse) private var problems: [StudyProblem]
    
    @State private var searchText = ""
    @State private var selectedProblem: StudyProblem?
    @State private var isEditingProblem = false
    @State private var isShowingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if problems.isEmpty {
                    emptyStateView
                } else {
                    problemsList
                }
            }
            .navigationTitle("Problems")
            .searchable(text: $searchText, prompt: "Search problems")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.isAddingProblem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isEditingProblem) {
                if let problem = selectedProblem {
                    EditProblemView(problem: problem)
                }
            }
            .alert("Delete Problem", isPresented: $isShowingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let problem = selectedProblem {
                        deleteProblems(with: [problem.id])
                    }
                }
            } message: {
                Text("Are you sure you want to delete this problem? This action cannot be undone.")
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Problems Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add your first problem to get started with spaced repetition learning.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                appState.isAddingProblem = true
            }) {
                Text("Add Problem")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Filtered problems based on search text
    private var filteredProblems: [StudyProblem] {
        if searchText.isEmpty {
            return problems
        } else {
            return problems.filter { problem in
                problem.question.localizedCaseInsensitiveContains(searchText) ||
                problem.solution.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Problems list view
    private var problemsList: some View {
        List {
            ForEach(filteredProblems) { problem in
                ProblemListItem(problem: problem)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProblem = problem
                        isEditingProblem = true
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            selectedProblem = problem
                            isShowingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            selectedProblem = problem
                            isEditingProblem = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            // Mark for review immediately
                            do {
                                problem.nextReview = Date()
                                try modelContext.save()
                            } catch {
                                print("Failed to mark for review: \(error)")
                            }
                        } label: {
                            Label("Review", systemImage: "clock.arrow.circlepath")
                        }
                        .tint(.orange)
                    }
            }
            .onDelete { indexSet in
                let problemsToDelete = indexSet.map { filteredProblems[$0].id }
                deleteProblems(with: problemsToDelete)
            }
        }
    }
    
    // Delete problems with the given IDs
    private func deleteProblems(with ids: [UUID]) {
        for id in ids {
            do {
                try DataManager.shared.deleteProblem(with: id)
            } catch {
                print("Failed to delete problem: \(error)")
            }
        }
    }
}

// Individual problem list item
struct ProblemListItem: View {
    let problem: StudyProblem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(problem.question)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                // Stats
                HStack(spacing: 15) {
                    // Review count
                    Label("\(problem.attempts.count)", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Last reviewed date
                    if problem.lastReviewed != Date.distantPast {
                        Label(
                            relativeTimeString(from: problem.lastReviewed),
                            systemImage: "clock"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
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
        .padding(.vertical, 4)
    }
    
    // Format relative time
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Edit problem view
struct EditProblemView: View {
    let problem: StudyProblem
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var question: String
    @State private var solution: String
    @State private var difficulty: Int
    
    init(problem: StudyProblem) {
        self.problem = problem
        _question = State(initialValue: problem.question)
        _solution = State(initialValue: problem.solution)
        _difficulty = State(initialValue: problem.difficulty)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextEditor(text: $question)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Solution")) {
                    TextEditor(text: $solution)
                        .frame(minHeight: 150)
                }
                
                Section(header: Text("Difficulty")) {
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Very Easy").tag(1)
                        Text("Easy").tag(2)
                        Text("Medium").tag(3)
                        Text("Hard").tag(4)
                        Text("Very Hard").tag(5)
                    }
                }
                
                // Stats section
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Reviews")
                        Spacer()
                        Text("\(problem.attempts.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Success Rate")
                        Spacer()
                        Text("\(successRateString)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Average Confidence")
                        Spacer()
                        Text(String(format: "%.1f", problem.confidence))
                            .foregroundColor(.secondary)
                    }
                    
                    if problem.lastReviewed != Date.distantPast {
                        HStack {
                            Text("Last Reviewed")
                            Spacer()
                            Text(formattedDate(problem.lastReviewed))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Next Review")
                        Spacer()
                        Text(formattedDate(problem.nextReview))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Problem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProblem()
                    }
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                             solution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // Format date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Calculate success rate
    private var successRateString: String {
        let successCount = problem.attempts.filter { $0.success }.count
        
        if problem.attempts.isEmpty {
            return "N/A"
        } else {
            let rate = Double(successCount) / Double(problem.attempts.count) * 100
            return String(format: "%.0f%%", rate)
        }
    }
    
    // Save problem changes
    private func saveProblem() {
        problem.question = question
        problem.solution = solution
        problem.difficulty = difficulty
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save problem: \(error)")
        }
    }
} 