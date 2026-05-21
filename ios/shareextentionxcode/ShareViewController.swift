import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

  private let appGroupId = "group.com.gimie.shareextension"
  private let sharedKey = "ShareKey"

  override func viewDidLoad() {
    super.viewDidLoad()
    processSharedItems()
  }

  private func processSharedItems() {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      finish()
      return
    }

    var payload: [String: Any]?
    let group = DispatchGroup()

    for item in items {
      guard let providers = item.attachments else { continue }
      for provider in providers {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let url = item as? URL {
              payload = ["type": "url", "url": url.absoluteString]
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let text = item as? String {
              payload = ["type": "text", "text": text]
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
              payload = ["type": "image", "image": data.base64EncodedString()]
            }
          }
        }
      }
    }

    group.notify(queue: .main) { [weak self] in
      self?.persistAndOpenApp(payload: payload)
    }
  }

  private func persistAndOpenApp(payload: [String: Any]?) {
    if let payload = payload,
       let defaults = UserDefaults(suiteName: appGroupId) {
      defaults.set(payload, forKey: sharedKey)
      defaults.synchronize()
    }

    guard let url = URL(string: "gimie://share") else {
      finish()
      return
    }

    extensionContext?.open(url, completionHandler: { [weak self] _ in
      self?.finish()
    })
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
