import SwiftUI
import UIKit

// Step 1: Create a UIViewControllerRepresentable wrapper for UIActivityViewController
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]?
    var completionHandler: ((Bool) -> Void)? // Add completion handler to detect finish

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = excludedActivityTypes

        // Set the completion handler to handle when the share sheet finishes
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let completionHandler = self.completionHandler {
                completionHandler(completed) // Pass the completion status
            }
        }

        return activityViewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update any properties if needed (usually not needed for this case)
    }
}
