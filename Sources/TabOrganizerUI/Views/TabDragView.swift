//
//  TabDragView.swift
//  TabOrganizerUI
//
//  Drag-and-drop handling view for tab association organization.
//  Provides drop zones for groups and handles tab movement between groups.
//

import SwiftUI
import TabOrganizerCore
import TabOrganizerSafariAPI
import UniformTypeIdentifiers

/// View that wraps content with drag-and-drop capabilities.
///
/// **Features** (FR-004):
/// - Drop zones for each group
/// - Visual feedback during drag operations
/// - Tab movement between groups
/// - Ungrouping via drop outside groups
/// - Accessibility support for drag gestures
///
/// **TDD Approach**: See Preview at bottom for visual testing.
public struct TabDragView<Content: View>: View {

    // MARK: - Environment

    @Environment(ExtensionState.self) private var state

    // MARK: - Properties

    /// The content to wrap with drag capabilities
    let content: Content

    /// The group this view represents (nil for ungrouped area)
    let targetGroup: TabAssociation?

    /// Callback when a tab is dropped
    let onTabDropped: (String, UUID?, UUID?) -> Void

    // MARK: - State

    @State private var isTargeted: Bool = false

    // MARK: - Initialization

    /// Creates a drag view.
    ///
    /// - Parameters:
    ///   - targetGroup: The group this drop zone represents (nil for ungrouped)
    ///   - onTabDropped: Callback with (tabID, fromGroupID, toGroupID)
    ///   - content: The content to wrap
    public init(
        targetGroup: TabAssociation?,
        onTabDropped: @escaping (String, UUID?, UUID?) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.targetGroup = targetGroup
        self.onTabDropped = onTabDropped
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        content
            .onDrop(
                of: [.text],
                isTargeted: $isTargeted
            ) { providers in
                handleDrop(providers: providers)
            }
            .overlay(
                dropIndicator
                    .opacity(isTargeted ? 1 : 0)
            )
            // MARK: - Accessibility
            .accessibilityDropPoint { _ in
                AccessibilityDropPointInfo(
                    description: dropZoneDescription
                )
            }
    }

    // MARK: - Subviews

    /// Visual indicator when drop zone is targeted.
    @ViewBuilder
    private var dropIndicator: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(
                Color.blue,
                style: StrokeStyle(lineWidth: 3, dash: [8])
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
            .padding(4)
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }

    // MARK: - Computed Properties

    /// Accessibility description for drop zone.
    private var dropZoneDescription: String {
        if let group = targetGroup {
            return "Drop zone for \(group.name) group"
        } else {
            return "Drop zone to ungroup tabs"
        }
    }

    // MARK: - Drop Handling

    /// Handles the drop operation.
    ///
    /// - Parameter providers: The item providers from drag operation
    /// - Returns: True if drop was handled
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            return false
        }

        // Extract tab ID from drag data
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { data, error in
            guard let data = data as? Data,
                  let tabID = String(data: data, encoding: .utf8) else {
                return
            }

            // Extract source group ID if available
            let fromGroupID: UUID? = {
                if let suggestedName = provider.suggestedName,
                   let uuid = UUID(uuidString: suggestedName) {
                    return uuid
                }
                return nil
            }()

            let toGroupID = targetGroup?.id

            // Execute drop on main actor
            Task { @MainActor in
                onTabDropped(tabID, fromGroupID, toGroupID)
            }
        }

        return true
    }
}

// MARK: - Convenience Initializers

extension TabDragView where Content == AnyView {
    /// Creates a drop zone for a group.
    ///
    /// - Parameters:
    ///   - group: The target group
    ///   - onTabDropped: Drop callback
    ///   - content: The content view
    public static func groupDropZone(
        group: TabAssociation,
        onTabDropped: @escaping (String, UUID?, UUID?) -> Void,
        @ViewBuilder content: () -> some View
    ) -> TabDragView {
        TabDragView(
            targetGroup: group,
            onTabDropped: onTabDropped,
            content: { AnyView(content()) }
        )
    }

    /// Creates a drop zone for ungrouping tabs.
    ///
    /// - Parameters:
    ///   - onTabDropped: Drop callback
    ///   - content: The content view
    public static func ungroupDropZone(
        onTabDropped: @escaping (String, UUID?, UUID?) -> Void,
        @ViewBuilder content: () -> some View
    ) -> TabDragView {
        TabDragView(
            targetGroup: nil,
            onTabDropped: onTabDropped,
            content: { AnyView(content()) }
        )
    }
}

// MARK: - AccessibilityDropPointInfo

/// Information about a drop point for accessibility.
///
/// This provides context to assistive technologies about where items can be dropped.
public struct AccessibilityDropPointInfo {
    let description: String
}

// MARK: - View Extension

extension View {
    /// Adds accessibility drop point information.
    ///
    /// - Parameter info: Callback providing drop point info
    /// - Returns: Modified view
    func accessibilityDropPoint(_ info: @escaping (CGPoint) -> AccessibilityDropPointInfo) -> some View {
        // This is a placeholder for proper accessibility integration
        // In production, would integrate with system accessibility APIs
        self
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Drop Zone - Group") {
    let sampleGroup = try! TabAssociation(
        id: UUID(),
        name: "Work",
        color: "#0066CC",
        collapsed: false,
        createdAt: Date(),
        updatedAt: Date(),
        tabIDs: ["tab-1", "tab-2"],
        metadata: [:]
    )

    TabDragView(
        targetGroup: sampleGroup,
        onTabDropped: { tabID, fromID, toID in
            print("Dropped \(tabID) from \(fromID?.uuidString ?? "none") to \(toID?.uuidString ?? "none")")
        }
    ) {
        VStack(spacing: 12) {
            Text("Work Group")
                .font(.headline)

            Text("Drop zone for tabs")
                .font(.caption)
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(Color.blue.opacity(0.2))
                .frame(height: 100)
        }
        .padding()
    }
    .environment(ExtensionState.preview)
    .frame(width: 400, height: 300)
}

#Preview("Drop Zone - Ungrouped") {
    return TabDragView(
        targetGroup: nil,
        onTabDropped: { tabID, fromID, toID in
            print("Ungrouped \(tabID) from \(fromID?.uuidString ?? "none")")
        }
    ) {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Ungrouped Tabs")
                .font(.headline)

            Text("Drop here to ungroup")
                .font(.caption)
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 80)
        }
        .padding()
    }
    .environment(ExtensionState.preview)
    .frame(width: 400, height: 300)
}

#Preview("Multiple Drop Zones") {
    let groups = [
        try! TabAssociation(
            id: UUID(),
            name: "Work",
            color: "#0066CC",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: [],
            metadata: [:]
        ),
        try! TabAssociation(
            id: UUID(),
            name: "Research",
            color: "#00CC66",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: [],
            metadata: [:]
        ),
        try! TabAssociation(
            id: UUID(),
            name: "Shopping",
            color: "#FF6600",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: [],
            metadata: [:]
        )
    ]

    VStack(spacing: 16) {
        ForEach(groups) { group in
            TabDragView(
                targetGroup: group,
                onTabDropped: { tabID, fromID, toID in
                    print("Dropped \(tabID) into \(group.name)")
                }
            ) {
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: group.color) ?? .blue)
                        .frame(width: 4, height: 40)

                    Text(group.name)
                        .font(.headline)

                    Spacer()

                    Text("Drop here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.05))
                )
            }
        }
    }
    .padding()
    .environment(ExtensionState.preview)
    .frame(width: 400, height: 400)
}
#endif
