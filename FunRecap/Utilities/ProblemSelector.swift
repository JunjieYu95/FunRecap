import Foundation

struct ProblemSelector {
    private let prefixSums: [Int]
    
    init(weights: [Int]) {
        var runningSum = 0
        prefixSums = weights.map { weight in
            runningSum += weight
            return runningSum
        }
    }
    
    func pickIndex() -> Int {
        guard let total = prefixSums.last, total > 0 else {
            return 0
        }
        
        let random = Int.random(in: 0..<total)
        return binarySearch(random)
    }
    
    private func binarySearch(_ target: Int) -> Int {
        var left = 0
        var right = prefixSums.count - 1
        
        while left < right {
            let mid = left + (right - left) / 2
            if prefixSums[mid] <= target {
                left = mid + 1
            } else {
                right = mid
            }
        }
        
        return left
    }
}

class ProblemWeightCalculator {
    // Constants for weight calculation
    private let baseWeight = 100
    private let confidenceMultiplier = 20
    private let difficultyMultiplier = 10
    private let recencyMultiplier = 5
    
    // Calculate weight for a problem based on various factors
    func calculateWeight(for problem: StudyProblem) -> Int {
        // Base weight
        var weight = baseWeight
        
        // Adjust for confidence (lower confidence = higher weight)
        let confidenceAdjustment = Int((5.0 - problem.confidence) * Float(confidenceMultiplier))
        weight += confidenceAdjustment
        
        // Adjust for difficulty (higher difficulty = higher weight)
        let difficultyAdjustment = problem.difficulty * difficultyMultiplier
        weight += difficultyAdjustment
        
        // Adjust for recency (older = higher weight)
        let daysSinceLastReview = daysBetween(problem.lastReviewed, Date())
        let recencyAdjustment = min(daysSinceLastReview * recencyMultiplier, 100)
        weight += recencyAdjustment
        
        // Apply Ebbinghaus forgetting curve factor
        weight = applyForgettingCurve(weight: weight, daysSinceLastReview: daysSinceLastReview)
        
        return max(1, weight) // Ensure weight is at least 1
    }
    
    // Apply the forgetting curve adjustment
    private func applyForgettingCurve(weight: Int, daysSinceLastReview: Int) -> Int {
        // Simplified implementation of the forgetting curve
        // R = e^(-t/S) where R is retention, t is time, S is strength of memory
        
        if daysSinceLastReview <= 0 {
            return weight
        }
        
        // S value increases with confidence
        let forgettingFactor = Double(daysSinceLastReview) / 5.0
        let adjustmentMultiplier = 1.0 + (1.0 - exp(-forgettingFactor))
        
        return Int(Double(weight) * adjustmentMultiplier)
    }
    
    // Calculate days between two dates
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
} 