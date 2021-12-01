# Tiqr

Tiqr, the open source authentication solution for smartphones and Web Applications.

## Requirements

- iOS 11.0 + 
- Swift 5 +

## Installation

#### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate **Tiqr** click File -> Add Packages -> and enter package URL:

```
https://github.com/SURFnet/tiqr-app-core-ios
```

Select Tiqr and press Add Package

## Usage

```
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = Tiqr.shared.startWithOptions(options: connectionOptions, theme: Theme())
    window?.makeKeyAndVisible()
}
```

for push notification support add

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
        if let error = error {
            print(error.localizedDescription)
        } else if granted {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    return true
}

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Tiqr.shared.registerDeviceToken(token: deviceToken)
        print("Successfully registered for notifications")
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Tiqr.shared.startChallenge(challenge: url.absoluteString)
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let challenge = userInfo["challenge"] as? String {
            Tiqr.shared.startChallenge(challenge: challenge)
        }
    }
}

```
