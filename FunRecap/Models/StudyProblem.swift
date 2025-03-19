import Foundation
import SwiftData

@Model
class StudyProblem {
    var id: UUID
    var question: String
    var solution: String
    var difficulty: Int
    var lastReviewed: Date
    var nextReview: Date
    var confidence: Float
    
    @Relationship(deleteRule: .cascade)
    var attempts: [AttemptHistory]
    
    init(question: String, solution: String, difficulty: Int = 2) {
        self.id = UUID()
        self.question = question
        self.solution = solution
        self.difficulty = difficulty
        self.lastReviewed = Date.distantPast
        self.nextReview = Date()
        self.confidence = 0.0
        self.attempts = []
    }
}

@Model
class AttemptHistory {
    var id: UUID
    var date: Date
    var success: Bool
    var confidenceRating: Int // 1-5 stars
    
    init(success: Bool, confidenceRating: Int) {
        self.id = UUID()
        self.date = Date()
        self.success = success
        self.confidenceRating = confidenceRating
    }
} 