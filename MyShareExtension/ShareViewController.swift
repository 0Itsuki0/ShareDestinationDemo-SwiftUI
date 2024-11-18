//
//  ShareViewController.swift
//  MyShareExtension
//
//  Created by Itsuki on 2024/11/17.
//

import SwiftUI

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let itemProviders = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments else {
            print("item not found!")
            cancelRequest(.itemNotFound)
            return
        }

        let hostingView = UIHostingController(
            rootView:
                ShareView(itemProviders: itemProviders, completeRequest: completeRequest, cancelRequest: cancelRequest)
        )
        self.addChild(hostingView)
        self.view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        hostingView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        hostingView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
        hostingView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        hostingView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
    }
    
    private func completeRequest() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func cancelRequest(_ error: ShareError) {
        self.extensionContext?.cancelRequest(withError: error)
    }
}
