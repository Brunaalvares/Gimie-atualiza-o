import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let appGroupId = "group.com.gimie.shareextension"
  private let sharedKey = "ShareKey"
  private let darwinNotificationName = "com.gimie.share.pending" as CFString
  private var shareChannel: FlutterMethodChannel?
  private var darwinObserverRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerDarwinObserverIfNeeded()
    setupShareChannelAndNotifyIfNeeded(forceNotify: hasPendingSharedData())
    return result
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerDarwinObserverIfNeeded()
    // Sempre tenta notificar se houver partilha pendente no App Group.
    setupShareChannelAndNotifyIfNeeded(forceNotify: hasPendingSharedData())
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "gimie" && url.host == "share" {
      setupShareChannelAndNotifyIfNeeded(forceNotify: true)
    }
    return super.application(app, open: url, options: options)
  }

  deinit {
    if darwinObserverRegistered {
      CFNotificationCenterRemoveObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        Unmanaged.passUnretained(self).toOpaque(),
        CFNotificationName(darwinNotificationName),
        nil
      )
    }
  }

  private func registerDarwinObserverIfNeeded() {
    guard !darwinObserverRegistered else { return }
    darwinObserverRegistered = true

    let callback: CFNotificationCallback = { _, observer, _, _, _ in
      guard let observer = observer else { return }
      let delegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
      DispatchQueue.main.async {
        delegate.setupShareChannelAndNotifyIfNeeded(forceNotify: true)
      }
    }

    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      Unmanaged.passUnretained(self).toOpaque(),
      callback,
      darwinNotificationName,
      nil,
      .deliverImmediately
    )
  }

  private func hasPendingSharedData() -> Bool {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return false }
    defaults.synchronize()
    return defaults.object(forKey: sharedKey) != nil
  }

  private func setupShareChannelAndNotifyIfNeeded(
    forceNotify: Bool = false,
    retries: Int = 25
  ) {
    let shouldNotify = forceNotify || hasPendingSharedData()

    if setupShareChannelIfNeeded() {
      if shouldNotify {
        // Pequeno atraso para o Dart ter o handler pronto.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
          self?.shareChannel?.invokeMethod("onSharedContent", arguments: nil)
        }
        // Segunda notificação por se a primeira cair no meio do resume.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
          guard let self = self, self.hasPendingSharedData() || forceNotify else { return }
          self.shareChannel?.invokeMethod("onSharedContent", arguments: nil)
        }
      }
      return
    }

    guard retries > 0 else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
      self?.setupShareChannelAndNotifyIfNeeded(
        forceNotify: forceNotify,
        retries: retries - 1
      )
    }
  }

  private func getSharedData(result: @escaping FlutterResult) {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
      print("Failed to create UserDefaults with suite name: \(appGroupId)")
      result(nil)
      return
    }

    userDefaults.synchronize()
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

  @discardableResult
  private func setupShareChannelIfNeeded() -> Bool {
    if shareChannel != nil {
      return true
    }

    guard let controller = currentFlutterViewController() else {
      return false
    }

    let channel = FlutterMethodChannel(
      name: "com.gimie.share",
      binaryMessenger: controller.binaryMessenger
    )
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
