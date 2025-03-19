import Foundation
import UserNotifications
import CoreLocation

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var locationManager: CLLocationManager?
    
    // Notification action identifiers
    enum NotificationAction: String {
        case markSolved = "MARK_SOLVED_ACTION"
        case reviewNow = "REVIEW_NOW_ACTION"
        case snooze = "SNOOZE_ACTION"
    }
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
    }
    
    // Request permission for notifications
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    // Set up notification categories and actions
    private func setupNotificationCategories() {
        // Mark Solved action
        let markSolvedAction = UNNotificationAction(
            identifier: NotificationAction.markSolved.rawValue,
            title: "Mark Solved",
            options: .foreground
        )
        
        // Review Now action
        let reviewNowAction = UNNotificationAction(
            identifier: NotificationAction.reviewNow.rawValue,
            title: "Review Now",
            options: .foreground
        )
        
        // Snooze action
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Snooze",
            options: .foreground
        )
        
        // Create category with actions
        let reviewCategory = UNNotificationCategory(
            identifier: "REVIEW_CATEGORY",
            actions: [markSolvedAction, reviewNowAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register category
        notificationCenter.setNotificationCategories([reviewCategory])
    }
    
    // Schedule a notification for a problem
    func scheduleProblemReview(for problem: StudyProblem, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to review"
        content.body = "Review: \(problem.question)"
        content.sound = .default
        content.categoryIdentifier = "REVIEW_CATEGORY"
        
        // Store problem ID in notification
        content.userInfo = ["problemID": problem.id.uuidString]
        
        // Create a trigger for the scheduled time
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "review-\(problem.id)",
            content: content,
            trigger: trigger
        )
        
        // Add the request
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Cancel a scheduled notification
    func cancelNotification(for problemID: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["review-\(problemID)"])
    }
    
    // Reschedule a notification with exponential backoff
    func snoozeNotification(for problemID: UUID, backoffFactor: Int = 1) {
        let delay = TimeInterval(30 * min(backoffFactor, 16)) // 30 min × backoff (max 8 hours)
        let newDate = Date().addingTimeInterval(delay)
        
        // Find the problem with the given ID and reschedule
        // This would need integration with your data manager
        // For example: DataManager.shared.getProblem(with: problemID) { problem in ... }
    }
    
    // Setup location-based notifications (for future implementation)
    func setupLocationBasedNotifications() {
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        // Further implementation would depend on app requirements
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract problem ID
        guard let problemIDString = userInfo["problemID"] as? String,
              let problemID = UUID(uuidString: problemIDString) else {
            completionHandler()
            return
        }
        
        // Handle based on action
        switch response.actionIdentifier {
        case NotificationAction.markSolved.rawValue:
            // Mark the problem as solved
            // DataManager.shared.markProblemAsSolved(problemID)
            print("Problem marked as solved")
            
        case NotificationAction.reviewNow.rawValue:
            // Deep link to the problem
            // AppCoordinator.shared.showProblem(problemID)
            print("Opening problem for review")
            
        case NotificationAction.snooze.rawValue:
            // Reschedule with backoff
            snoozeNotification(for: problemID)
            print("Notification snoozed")
            
        default:
            break
        }
        
        completionHandler()
    }
} 