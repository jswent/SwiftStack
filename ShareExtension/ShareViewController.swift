//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by James Swent on 7/22/25.
//

import UIKit
import SwiftUI
import SwiftData
import SavedItem
import LinkPresentation
import UniformTypeIdentifiers
import OSLog

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let logger = Logger(subsystem: "ShareExtension", category: "ViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("ShareViewController viewDidLoad started")
        
        // Extract shared content from extension context
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            logger.error("No extension item or attachments found")
            close()
            return
        }
        
        logger.info("Found \(attachments.count) attachments")
        
        // Look for URL or JavaScript results
        processAttachments(attachments) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.showSwiftUIView(with: data)
                case .failure(let error):
                    self?.logger.error("Failed to process attachments: \(error.localizedDescription)")
                    self?.close()
                }
            }
        }
        
        // Listen for close notification from SwiftUI view
        NotificationCenter.default.addObserver(forName: NSNotification.Name("closeShareExtension"), object: nil, queue: nil) { _ in
            self.logger.info("Received close notification from SwiftUI view")
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
    private func processAttachments(_ attachments: [NSItemProvider], completion: @escaping (Result<ShareData, Error>) -> Void) {
        // First try JavaScript preprocessing results
        let propertyListProvider = attachments.first { $0.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) }
        
        if let provider = propertyListProvider {
            provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { item, error in
                if let plistDict = item as? [String: Any],
                   let jsResults = plistDict["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: Any] {
                    let data = ShareData(
                        title: jsResults["title"] as? String ?? "",
                        url: jsResults["url"] as? String ?? "",
                        notes: jsResults["description"] as? String ?? ""
                    )
                    completion(.success(data))
                    return
                }
                
                // If JavaScript processing fails, try URL fallback
                self.tryURLFallback(attachments: attachments, completion: completion)
            }
            return
        }
        
        // No JavaScript preprocessing, try URL fallback directly
        tryURLFallback(attachments: attachments, completion: completion)
    }
    
    private func tryURLFallback(attachments: [NSItemProvider], completion: @escaping (Result<ShareData, Error>) -> Void) {
        let urlProvider = attachments.first { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }
        
        guard let provider = urlProvider else {
            completion(.failure(ShareExtensionError.noValidURL))
            return
        }
        
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let url = item as? URL {
                let data = ShareData(
                    title: "",
                    url: url.absoluteString,
                    notes: ""
                )
                completion(.success(data))
            } else {
                completion(.failure(ShareExtensionError.invalidURL))
            }
        }
    }
    
    private func showSwiftUIView(with data: ShareData) {
        logger.info("Showing SwiftUI view with data: title='\(data.title)', url='\(data.url)'")
        
        let contentView = UIHostingController(
            rootView: ShareExtensionView(shareData: data)
                .modelContainer(SharedModelContainer.container)
        )
        
        addChild(contentView)
        view.addSubview(contentView.view)
        
        // Set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        contentView.didMove(toParent: self)
    }
    
    /// Close the Share Extension
    func close() {
        logger.info("Closing share extension")
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Share Data Model

struct ShareData {
    let title: String
    let url: String
    let notes: String
}

// MARK: - Errors

enum ShareExtensionError: LocalizedError {
    case noInputItems
    case noValidURL
    case invalidURL
    case invalidJavaScriptResults
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .noInputItems:
            return "No content was shared"
        case .noValidURL:
            return "No valid URL found in shared content"
        case .invalidURL:
            return "The shared URL is invalid"
        case .invalidJavaScriptResults:
            return "Could not process shared web page"
        case .timeout:
            return "Request timed out"
        }
    }
}

// MARK: - SwiftUI View for Share Extension

struct ShareExtensionView: View {
    let shareData: ShareData
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ShareExtensionFormView(shareData: shareData)
            .onReceive(NotificationCenter.default.publisher(for: .savedItemCreated)) { _ in
                completeExtension()
            }
    }
    
    private func cancelExtension() {
        print("DEBUG: Cancel button tapped, posting close notification")
        NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
    }
    
    private func completeExtension() {
        print("DEBUG: Completing extension")
        NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
    }
}

struct ShareExtensionFormView: View {
    let shareData: ShareData
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String
    @State private var urlString: String
    @State private var notes: String
    
    init(shareData: ShareData) {
        self.shareData = shareData
        self._title = State(initialValue: shareData.title)
        self._urlString = State(initialValue: shareData.url)
        self._notes = State(initialValue: shareData.notes)
    }
    
    var body: some View {            // Form content
        NavigationView {
            SavedItemFormView(
                title: $title,
                urlString: $urlString,
                notes: $notes,
                onCancel: cancelExtension,
                onSave: saveAndComplete
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: cancelExtension)
                        .font(.body)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveAndComplete)
                        .font(.body.weight(.semibold))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func cancelExtension() {
        print("DEBUG: Cancel button tapped in share extension")
        NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
    }
    
    private func saveAndComplete() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = trimmed.isEmpty ? nil : URL(string: trimmed)

        let newItem = SavedItem(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            url: url
        )
        modelContext.insert(newItem)
        
        // Ensure save is called before closing extension
        Task {
            do {
                try await modelContext.save()
                print("DEBUG: Successfully saved item to shared container")
                
                // Post local notification for coordination
                NotificationCenter.default.post(name: .savedItemCreated, object: newItem)
                
                // Post Darwin notification to wake up main app
                postDarwinNotification()
                
                // Only close after successful save
                await MainActor.run {
                    print("DEBUG: Item saved, closing extension")
                    NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
                }
            } catch {
                print("ERROR: Failed to save item in share extension: \(error)")
                // Still close the extension to avoid hanging
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
                }
            }
        }
    }
    
    private func postDarwinNotification() {
        let notificationName = "com.jswent.STACK.shareDidSave"
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )
        print("DEBUG: Posted Darwin notification: \(notificationName)")
    }
}


// MARK: - Shared Model Container

enum SharedModelContainer {
    static let container: ModelContainer = {
        let schema = Schema([SavedItem.self])
        let configuration = ModelConfiguration(
            schema: schema,
            allowsSave: true,
            groupContainer: .identifier("group.com.jswent.STACK")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}

// MARK: - Notification Extension

extension Notification.Name {
    static let savedItemCreated = Notification.Name("savedItemCreated")
}
