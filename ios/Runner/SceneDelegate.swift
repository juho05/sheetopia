import Flutter
import UIKit
import flutter_sharing_intent

// TODO: migrate to plugin solution once flutter_sharing_intent supports UIScene lifecycle natively.
/// Custom scene delegate that bridges incoming custom-scheme URLs to the
/// flutter_sharing_intent plugin.
///
/// Since Flutter 3.44 the iOS app adopts the UIScene lifecycle
/// (`FlutterSceneDelegate` in Info.plist). Under that lifecycle UIKit no longer
/// calls `application(_:open:options:)` on the `AppDelegate`; URLs are delivered
/// to the scene delegate instead. flutter_sharing_intent (2.0.4) only
/// registers the legacy app-delegate hook, so the share extension's redirect URL
/// never reaches it. We forward the URLs here manually.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UISceneConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Cold launch: the app was started by the share extension's redirect URL.
    forward(urlContexts: connectionOptions.urlContexts, isInitial: true)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    // Warm launch: the app was already running when the share happened.
    forward(urlContexts: URLContexts, isInitial: false)
  }

  private func forward(urlContexts: Set<UIOpenURLContext>, isInitial: Bool) {
    let plugin = SwiftFlutterSharingIntentPlugin.instance
    for context in urlContexts where plugin.hasSameSchemePrefix(url: context.url) {
      if isInitial {
        // Route through `didFinishLaunchingWithOptions` so the payload is stored
        // as `initialSharing` and picked up by `getInitialSharing` on startup.
        _ = plugin.application(
          UIApplication.shared,
          didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey.url: context.url]
        )
      } else {
        _ = plugin.application(UIApplication.shared, open: context.url, options: [:])
      }
    }
  }
}