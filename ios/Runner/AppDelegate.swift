import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  
  private let appGroupId = "group.com.gimie.shareextension"
  private let sharedKey = "ShareKey"
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let shareChannel = FlutterMethodChannel(name: "com.gimie.share", binaryMessenger: controller.binaryMessenger)
    
    shareChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getSharedData":
        self?.getSharedData(result: result)
      case "clearSharedData":
        self?.clearSharedData(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getSharedData(result: @escaping FlutterResult) {
    do {
      guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
        print("Failed to create UserDefaults with suite name: \(appGroupId)")
        result(nil)
        return
      }
      
      let sharedData = userDefaults.object(forKey: sharedKey) as? [String: Any]
      print("Retrieved shared data: \(sharedData?.description ?? "nil")")
      result(sharedData)
    } catch {
      print("Error getting shared data: \(error)")
      result(nil)
    }
  }
  
  private func clearSharedData(result: @escaping FlutterResult) {
    do {
      guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
        print("Failed to create UserDefaults with suite name: \(appGroupId)")
        result(false)
        return
      }
      
      userDefaults.removeObject(forKey: sharedKey)
      let success = userDefaults.synchronize()
      print("Cleared shared data, success: \(success)")
      result(success)
    } catch {
      print("Error clearing shared data: \(error)")
      result(false)
    }
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Handle URL scheme (gimie://share)
    if url.scheme == "gimie" && url.host == "share" {
      // Notify Flutter about the shared content
      let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
      let shareChannel = FlutterMethodChannel(name: "com.gimie.share", binaryMessenger: controller.binaryMessenger)
      shareChannel.invokeMethod("onSharedContent", arguments: nil)
    }
    
    return super.application(app, open: url, options: options)
  }
}
