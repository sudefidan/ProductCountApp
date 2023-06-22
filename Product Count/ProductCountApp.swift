import SwiftUI
import UserNotifications

@main
struct ProductCountApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var selectedMachine: Machine?
    @State private var totalProductCount = 0
    // Machines
    @State private var machines: [Machine] = [
        Machine(name: "Machine A", timeInSeconds: 90, productCount: 0),
        Machine(name: "Machine B", timeInSeconds: 60, productCount: 0),
        Machine(name: "Machine C", timeInSeconds: 120, productCount: 0)
    ]
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(selectedMachine: $selectedMachine, totalProductCount: $totalProductCount, machines: $machines)
                    .tabItem {
                        Label("Machines", systemImage: "square.grid.2x2")
                    }
            }
            .onAppear {
                appDelegate.registerForRemoteNotifications()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Request user authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("User authorization granted for notifications")
            } else if let error = error {
                print("Error requesting authorization for notifications: \(error.localizedDescription)")
            }
        }
        // Set the delegate for handling user notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func registerForRemoteNotifications() {
        let center = UNUserNotificationCenter.current()
        // Request authorization for remote notifications
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                // If authorization is granted, register for remote notifications on the main queue
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                // If there's an error requesting authorization, print the error message
                print("Error requesting authorization for remote notifications: \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(token)")
        
        // TODO: Send the device token to server to associate it with the user to send push notification to device
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Handle remote notifications when the app is in the foreground or background
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Alert with the notification
        let content = notification.request.content
        let alert = UIAlertController(title: content.title, message: content.body, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert on main window
        if let mainWindowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let mainWindow = mainWindowScene.windows.first {
            mainWindow.rootViewController?.present(alert, animated: true, completion: nil)
        }
        
        // Completion handler
        completionHandler([.banner, .sound])
    }
}
