import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let appGroupId = "group.com.gimie.shareextension"
  private let sharedKey = "ShareKey"
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    setupShareChannelWhenReady()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    setupShareChannelWhenReady()
  }

  private func getSharedData(result: @escaping FlutterResult) {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      print("Failed to create UserDefaults with suite name: \(appGroupId)")
      result(nil)
      return
    }

    let sharedData = userDefaults.object(forKey: sharedKey) as? [String: Any]
    print("Retrieved shared data: \(sharedData?.description ?? "nil")")
    result(sharedData)
  }

  private func clearSharedData(result: @escaping FlutterResult) {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      print("Failed to create UserDefaults with suite name: \(appGroupId)")
      result(false)
      return
    }

    userDefaults.removeObject(forKey: sharedKey)
    let success = userDefaults.synchronize()
    print("Cleared shared data, success: \(success)")
    result(success)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "gimie" && url.host == "share" {
      setupShareChannelWhenReady()
      shareChannel?.invokeMethod("onSharedContent", arguments: nil)
    }

    return super.application(app, open: url, options: options)
  }

  private func setupShareChannelWhenReady(retries: Int = 12) {
    if setupShareChannelIfNeeded() {
      return
    }
    guard retries > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      self?.setupShareChannelWhenReady(retries: retries - 1)
    }
  }

  @discardableResult
  private func setupShareChannelIfNeeded() -> Bool {
    if shareChannel != nil {
      return true
    }

    guard let controller = currentFlutterViewController() else {
      return false
    }

    let channel = FlutterMethodChannel(name: "com.gimie.share", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getSharedData":
        self?.getSharedData(result: result)
      case "clearSharedData":
        self?.clearSharedData(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    shareChannel = channel
    return true
  }

  private func currentFlutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }

    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        if let controller = window.rootViewController as? FlutterViewController {
          return controller
        }
      }
    }

    return nil
  }
}
