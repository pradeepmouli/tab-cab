//
//  SafariWebExtensionHandler.swift
//  TabCab Extension
//
//  Created by Pradeep Mouli on 12/26/25.
//

import SafariServices
import os.log

@available(macOS 10.15, iOS 13.0, *)
@MainActor
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        // Handle different message types
        Task {
            await handleMessage(message, context: context, profile: profile)
        }
    }

    private func handleMessage(_ message: Any?, context: NSExtensionContext, profile: UUID?) async {
        guard let messageDict = message as? [String: Any],
              let type = messageDict["type"] as? String else {
            // Echo back for backward compatibility
            sendResponse(["echo": message as Any], to: context)
            return
        }

        switch type {
        case "GET_TABS":
            // Phase 2B: Return tabs from Safari
            sendResponse(["success": false, "error": "Not yet implemented"], to: context)

        case "TRIGGER_AI_GROUPING":
            // Phase 2B: Trigger AI processing via native app
            sendResponse(["success": false, "error": "AI grouping pending native app integration"], to: context)

        case "ACCESSIBILITY_CONTROL":
            // Phase 2B (macOS only): Control Safari tabs via Accessibility API
            sendResponse(["success": false, "error": "Accessibility API pending implementation"], to: context)

        default:
            os_log(.error, "Unknown message type: %@", type)
            sendResponse(["error": "Unknown message type"], to: context)
        }
    }

    private func sendResponse(_ response: [String: Any], to context: NSExtensionContext) {
        let responseItem = NSExtensionItem()
        if #available(iOS 15.0, macOS 11.0, *) {
            responseItem.userInfo = [SFExtensionMessageKey: response]
        } else {
            responseItem.userInfo = ["message": response]
        }
        context.completeRequest(returningItems: [responseItem], completionHandler: nil)
    }

}
