import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    private let appGroupId = ShareExtensionConfig.appGroupId
    private let sharedKey = ShareExtensionConfig.sharedKey
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        
        // Process shared content
        handleSharedContent()
    }
    
    private func handleSharedContent() {
        guard let extensionContext = extensionContext else {
            print("Extension context is nil")
            completeRequest()
            return
        }
        
        let attachments = extensionContext.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .compactMap { $0.attachments }
            .flatMap { $0 }
        
        print("Found \(attachments.count) attachments")
        
        if attachments.isEmpty {
            print("No attachments found")
            completeRequest()
            return
        }
        
        processAttachments(attachments)
    }
    
    private func processAttachments(_ attachments: [NSItemProvider]) {
        var sharedData: [String: Any] = [:]
        let group = DispatchGroup()
        
        for attachment in attachments {
            // Handle URLs
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                    defer { group.leave() }
                    
                    if let url = data as? URL {
                        sharedData["url"] = url.absoluteString
                        sharedData["type"] = "url"
                    }
                }
            }
            
            // Handle text
            if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] (data, error) in
                    defer { group.leave() }
                    
                    if let text = data as? String {
                        sharedData["text"] = text
                        sharedData["type"] = "text"
                    }
                }
            }
            
            // Handle images
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (data, error) in
                    defer { group.leave() }
                    
                    if let imageData = self?.getImageData(from: data) {
                        sharedData["image"] = imageData
                        sharedData["type"] = "image"
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.saveSharedData(sharedData)
        }
    }
    
    private func getImageData(from data: Any?) -> String? {
        var imageData: Data?
        
        if let image = data as? UIImage {
            imageData = image.jpegData(compressionQuality: 0.8)
        } else if let data = data as? Data {
            imageData = data
        } else if let url = data as? URL {
            imageData = try? Data(contentsOf: url)
        }
        
        return imageData?.base64EncodedString()
    }
    
    private func saveSharedData(_ data: [String: Any]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("Failed to create UserDefaults with suite name: \(appGroupId)")
            DispatchQueue.main.async { [weak self] in
                self?.statusLabel.text = "Erro ao salvar dados"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.completeRequest()
            }
            return
        }
        
        // Add timestamp
        var sharedData = data
        sharedData["timestamp"] = Date().timeIntervalSince1970
        
        // Save to shared UserDefaults
        userDefaults.set(sharedData, forKey: sharedKey)
        let success = userDefaults.synchronize()
        
        print("Saved shared data: \(sharedData)")
        print("UserDefaults synchronize success: \(success)")
        
        // Update UI
        DispatchQueue.main.async { [weak self] in
            if success {
                self?.statusLabel.text = "Conteúdo salvo! Abrindo Gimie..."
                // Open main app
                self?.openMainApp()
            } else {
                self?.statusLabel.text = "Erro ao salvar conteúdo"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.completeRequest()
                }
            }
        }
    }
    
    private func openMainApp() {
        guard let url = URL(string: "\(ShareExtensionConfig.urlScheme)://share") else {
            print("Failed to create URL with scheme: \(ShareExtensionConfig.urlScheme)")
            completeRequest()
            return
        }
        
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.perform(#selector(openURL(_:)), with: url)
                break
            }
            responder = responder?.next
        }
        
        // Complete after a short delay to allow the app to open
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.completeRequest()
        }
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

extension ShareViewController {
    @objc func openURL(_ url: URL) {
        // This method will be called via perform selector
    }
}