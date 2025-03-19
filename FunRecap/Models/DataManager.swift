import Foundation
import SwiftData
import Combine

class DataManager {
    static let shared = DataManager()
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // Error types
    enum DataError: Error {
        case failedToSave
        case problemNotFound
        case invalidData
    }
    
    private init() {
        do {
            // Create the SwiftData model container
            let schema = Schema([StudyProblem.self, AttemptHistory.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.modelContext = ModelContext(modelContainer)
            
            // Enable CloudKit synchronization for the container
            setupCloudKitSync()
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
    
    // Set up CloudKit synchronization
    private func setupCloudKitSync() {
        // CloudKit setup would go here if we were using NSPersistentCloudKitContainer
        // SwiftData currently has limited direct CloudKit support
        // This would be implemented differently in a production app
    }
    
    // MARK: - Problem Management
    
    // Add a new problem
    func addProblem(question: String, solution: String, difficulty: Int) -> StudyProblem {
        let problem = StudyProblem(question: question, solution: solution, difficulty: difficulty)
        modelContext.insert(problem)
        saveContext()
        return problem
    }
    
    // Get all problems
    func getAllProblems() -> [StudyProblem] {
        let descriptor = FetchDescriptor<StudyProblem>()
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch problems: \(error.localizedDescription)")
            return []
        }
    }
    
    // Get problems due for review
    func getProblemsForReview() -> [StudyProblem] {
        let now = Date()
        let descriptor = FetchDescriptor<StudyProblem>(predicate: #Predicate<StudyProblem> { $0.nextReview <= now })
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch problems for review: \(error.localizedDescription)")
            return []
        }
    }
    
    // Get a specific problem by ID
    func getProblem(with id: UUID) -> StudyProblem? {
        let descriptor = FetchDescriptor<StudyProblem>(predicate: #Predicate<StudyProblem> { $0.id == id })
        
        do {
            let problems = try modelContext.fetch(descriptor)
            return problems.first
        } catch {
            print("Failed to fetch problem with ID \(id): \(error.localizedDescription)")
            return nil
        }
    }
    
    // Update problem after review
    func updateProblemAfterReview(id: UUID, success: Bool, confidenceRating: Int) throws {
        guard let problem = getProblem(with: id) else {
            throw DataError.problemNotFound
        }
        
        // Create a new attempt history
        let attempt = AttemptHistory(success: success, confidenceRating: confidenceRating)
        problem.attempts.append(attempt)
        
        // Update problem details
        problem.lastReviewed = Date()
        
        // Update confidence score (weighted average)
        let totalAttempts = problem.attempts.count
        if totalAttempts > 0 {
            let totalConfidence = problem.attempts.reduce(0) { $0 + Float($1.confidenceRating) }
            problem.confidence = totalConfidence / Float(totalAttempts)
        } else {
            problem.confidence = Float(confidenceRating)
        }
        
        // Calculate next review date based on performance
        problem.nextReview = calculateNextReviewDate(
            problem: problem,
            wasSuccessful: success,
            confidenceRating: confidenceRating
        )
        
        // Save changes
        saveContext()
        
        // Schedule notification for next review
        NotificationManager.shared.scheduleProblemReview(for: problem, at: problem.nextReview)
    }
    
    // Calculate the next review date using spaced repetition algorithm
    private func calculateNextReviewDate(problem: StudyProblem, wasSuccessful: Bool, confidenceRating: Int) -> Date {
        // Base interval in hours
        var intervalHours = 6.0
        
        // If successful, increase interval based on confidence
        if wasSuccessful {
            // Exponential growth based on confidence
            // Confidence 1: 6h, 2: 12h, 3: 24h, 4: 48h, 5: 96h
            intervalHours *= pow(2.0, Double(confidenceRating - 1))
        } else {
            // If unsuccessful, review sooner (30 min to 3 hours based on confidence)
            intervalHours = Double(confidenceRating) / 2.0
        }
        
        // Apply difficulty factor
        let difficultyFactor = 1.0 / Double(problem.difficulty)
        intervalHours *= (0.5 + difficultyFactor)
        
        // Calculate next review date
        return Date().addingTimeInterval(intervalHours * 3600)
    }
    
    // Delete a problem
    func deleteProblem(with id: UUID) throws {
        guard let problem = getProblem(with: id) else {
            throw DataError.problemNotFound
        }
        
        // Cancel any pending notifications
        NotificationManager.shared.cancelNotification(for: id)
        
        // Delete the problem
        modelContext.delete(problem)
        saveContext()
    }
    
    // Save context
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    // Get weights for all problems
    func getProblemWeights() -> [(problem: StudyProblem, weight: Int)] {
        let problems = getAllProblems()
        let calculator = ProblemWeightCalculator()
        
        return problems.map { problem in
            return (problem: problem, weight: calculator.calculateWeight(for: problem))
        }
    }
    
    // Select a problem using weighted random selection
    func selectRandomProblem() -> StudyProblem? {
        let weightedProblems = getProblemWeights()
        
        if weightedProblems.isEmpty {
            return nil
        }
        
        let problems = weightedProblems.map { $0.problem }
        let weights = weightedProblems.map { $0.weight }
        
        let selector = ProblemSelector(weights: weights)
        let selectedIndex = selector.pickIndex()
        
        return problems[selectedIndex]
    }
} 