import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

  private let appGroupId = "group.com.gimie.shareextension"
  private let sharedKey = "ShareKey"
  private let darwinNotificationName = "com.gimie.share.pending" as CFString
  private var didFinish = false
  private var didStart = false

  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.text = "Abrindo a Gimie…"
    label.textAlignment = .center
    label.textColor = UIColor(red: 0.42, green: 0.17, blue: 0.36, alpha: 1)
    label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    view.addSubview(statusLabel)
    NSLayoutConstraint.activate([
      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didStart else { return }
    didStart = true
    processSharedItems()
  }

  private func processSharedItems() {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      finish()
      return
    }

    var sharedURL: String?
    var sharedText: String?
    var sharedImageBase64: String?
    let group = DispatchGroup()

    for item in items {
      guard let providers = item.attachments else { continue }
      for provider in providers {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let url = item as? URL {
              sharedURL = url.absoluteString
            } else if let raw = item as? String, !raw.isEmpty {
              sharedURL = raw
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let url = item as? URL {
              sharedURL = url.absoluteString
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let text = item as? String, !text.isEmpty {
              sharedText = text
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
            defer { group.leave() }
            if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
              sharedImageBase64 = data.base64EncodedString()
            } else if let data = item as? Data {
              sharedImageBase64 = data.base64EncodedString()
            } else if let url = item as? URL, let data = try? Data(contentsOf: url) {
              sharedImageBase64 = data.base64EncodedString()
            }
          }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
          group.enter()
          provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { item, _ in
            defer { group.leave() }
            guard let dict = item as? [String: Any],
                  let results = dict[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
            else { return }
            if let url = results["URL"] as? String, !url.isEmpty {
              sharedURL = url
            } else if let url = results["url"] as? String, !url.isEmpty {
              sharedURL = url
            }
          }
        }
      }
    }

    group.notify(queue: .main) { [weak self] in
      guard let self = self else { return }

      var payload: [String: Any]?
      if let url = sharedURL, !url.isEmpty {
        payload = ["type": "url", "url": url]
      } else if let text = sharedText, !text.isEmpty {
        // Extrai URL de textos tipo "Olha isso https://..."
        if let match = text.range(of: #"https?://[^\s]+"#, options: .regularExpression) {
          payload = ["type": "url", "url": String(text[match])]
        } else {
          payload = ["type": "text", "text": text]
        }
      } else if let image = sharedImageBase64, !image.isEmpty {
        payload = ["type": "image", "image": image]
      }

      self.persistAndOpenApp(payload: payload)
    }
  }

  private func persistAndOpenApp(payload: [String: Any]?) {
    if let payload = payload,
       let defaults = UserDefaults(suiteName: appGroupId) {
      defaults.removeObject(forKey: sharedKey)
      defaults.set(payload, forKey: sharedKey)
      defaults.synchronize()
    }

    // Avisa o app host (se já estiver em memória) antes de tentar abrir.
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(darwinNotificationName),
      nil,
      nil,
      true
    )

    openHostApp()
  }

  private func openHostApp() {
    guard let url = URL(string: "gimie://share") else {
      finish()
      return
    }

    // 1) UIApplication.shared via selector (mais fiável em Share Extensions)
    if openWithSharedApplication(url) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
        self?.finish()
      }
      return
    }

    // 2) Responder chain
    var responder: UIResponder? = self
    let selector = sel_registerName("openURL:")
    while let current = responder {
      if current.responds(to: selector) {
        _ = current.perform(selector, with: url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
          self?.finish()
        }
        return
      }
      responder = current.next
    }

    // 3) extensionContext.open
    extensionContext?.open(url, completionHandler: { [weak self] success in
      if !success {
        self?.statusLabel.text = "Abra a Gimie para ver a pré-visualização"
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        self?.finish()
      }
    })

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.finish()
    }
  }

  private func openWithSharedApplication(_ url: URL) -> Bool {
    let sharedSel = NSSelectorFromString("sharedApplication")
    guard UIApplication.responds(to: sharedSel),
          let unmanaged = UIApplication.perform(sharedSel),
          let application = unmanaged.takeUnretainedValue() as? UIApplication
    else {
      return false
    }

    if #available(iOS 10.0, *) {
      application.open(url, options: [:], completionHandler: nil)
      return true
    }

    let openSel = NSSelectorFromString("openURL:")
    if application.responds(to: openSel) {
      _ = application.perform(openSel, with: url)
      return true
    }
    return false
  }

  private func finish() {
    guard !didFinish else { return }
    didFinish = true
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
