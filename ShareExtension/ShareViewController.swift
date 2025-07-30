//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by James Swent on 7/22/25.
//

import UIKit
import OSLog

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let logger = Logger(subsystem: "ShareExtension", category: "ViewController")
    private let dataProcessor: ShareDataProcessing = ShareDataProcessor()
    private lazy var coordinator = ShareExtensionCoordinator(viewController: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("ShareViewController viewDidLoad started")
        
        processSharedContent()
    }
}

// MARK: - Private Methods

private extension ShareViewController {
    
    func processSharedContent() {
        // Extract shared content from extension context
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            logger.error("No extension item or attachments found")
            return
        }
        
        logger.info("Found \(attachments.count) attachments")
        
        // Process attachments using the data processor
        dataProcessor.processAttachments(attachments) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.coordinator.presentShareInterface(with: data)
                case .failure(let error):
                    self?.logger.error("Failed to process attachments: \(error.localizedDescription)")
                    self?.coordinator.closeExtension()
                }
            }
        }
    }
}
