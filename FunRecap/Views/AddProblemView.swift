import SwiftUI
import SwiftData

struct AddProblemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    
    @State private var question = ""
    @State private var solution = ""
    @State private var difficulty = 3 // Default to medium difficulty
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextEditor(text: $question)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if question.isEmpty {
                                    Text("Enter your question here...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                Section(header: Text("Solution")) {
                    TextEditor(text: $solution)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if solution.isEmpty {
                                    Text("Enter the solution or answer here...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                Section(header: Text("Difficulty")) {
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Very Easy").tag(1)
                        Text("Easy").tag(2)
                        Text("Medium").tag(3)
                        Text("Hard").tag(4)
                        Text("Very Hard").tag(5)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: addProblemAndClose) {
                        Text("Add Problem")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                    }
                    .disabled(isFormInvalid)
                }
            }
            .navigationTitle("Add Problem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Check if form is valid
    private var isFormInvalid: Bool {
        question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        solution.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Add the problem and close the form
    private func addProblemAndClose() {
        // Validate input
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSolution = solution.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuestion.isEmpty else {
            showError(message: "Please enter a question")
            return
        }
        
        guard !trimmedSolution.isEmpty else {
            showError(message: "Please enter a solution")
            return
        }
        
        // Create and save the problem
        let problem = DataManager.shared.addProblem(
            question: trimmedQuestion,
            solution: trimmedSolution,
            difficulty: difficulty
        )
        
        // Schedule a notification for the problem (immediate review)
        NotificationManager.shared.scheduleProblemReview(for: problem, at: problem.nextReview)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
    
    // Show error message
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

struct AddProblemView_Previews: PreviewProvider {
    static var previews: some View {
        AddProblemView()
            .environmentObject(AppState())
    }
} 