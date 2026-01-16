//
//  SafariExtensionViewController.swift
//  TabCab
//
//  View controller for the Safari Extension popover.
//  Hosts the SwiftUI PopoverView.
//

import SafariServices
import SwiftUI

/// View controller that hosts the SwiftUI PopoverView in the Safari extension popover.
@MainActor
final class SafariExtensionViewController: SFSafariExtensionViewController {

    static let shared = SafariExtensionViewController()

    private var hostingController: NSHostingController<PopoverView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the SwiftUI view
        let popoverView = PopoverView()

        // Host it in an NSHostingController
        let hosting = NSHostingController(rootView: popoverView)
        hostingController = hosting

        // Add as child view controller
        addChild(hosting)
        view.addSubview(hosting.view)

        // Configure constraints
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Set preferred content size (matches PopoverView frame)
        preferredContentSize = NSSize(width: 400, height: 600)
    }
}
