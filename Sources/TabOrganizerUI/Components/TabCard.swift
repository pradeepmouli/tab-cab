//
//  TabCard.swift
//  TabOrganizerUI
//
//  SwiftUI component for displaying individual tab information.
//  Supports drag-and-drop, selection, and accessibility.
//

import SwiftUI
import TabOrganizerCore
import TabOrganizerSafariAPI
import UniformTypeIdentifiers

/// SwiftUI card component for displaying a browser tab.
///
/// **Features**:
/// - Displays tab title, URL/domain, and favicon (future)
/// - Supports selection state
/// - Drag-and-drop for group membership (FR-004)
/// - Full accessibility support (FR-032, Constitution Principle VI)
///
/// **TDD Approach**: See Preview at bottom for visual testing with sample states.
public struct TabCard: View {

    // MARK: - Properties

    /// The tab information to display
    let tab: TabInfo

    /// Whether this tab is selected
    let isSelected: Bool

    /// Action when tab is tapped
    let onTap: () -> Void

    /// Action when tab is activated (navigate to)
    let onActivate: () -> Void

    // MARK: - Initialization

    /// Creates a tab card.
    ///
    /// - Parameters:
    ///   - tab: The tab information
    ///   - isSelected: Whether the tab is selected
    ///   - onTap: Action when tapped (for selection toggle)
    ///   - onActivate: Action when activated (navigate to tab)
    public init(
        tab: TabInfo,
        isSelected: Bool = false,
        onTap: @escaping () -> Void = {},
        onActivate: @escaping () -> Void = {}
    ) {
        self.tab = tab
        self.isSelected = isSelected
        self.onTap = onTap
        self.onActivate = onActivate
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 20))
                    .accessibilityLabel("Selected")
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 20))
                    .accessibilityLabel("Not selected")
            }

            // Favicon placeholder
            faviconView

            // Tab info
            VStack(alignment: .leading, spacing: 4) {
                Text(tab.title)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(tab.url.host ?? tab.url.absoluteString)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Activate button
            Button {
                onActivate()
            } label: {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Navigate to tab")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        // MARK: - Accessibility (Constitution Principle VI, FR-032)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tab.title), \(tab.url.host ?? "unknown domain")")
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
        .accessibilityIdentifier("TabCard_\(tab.id)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Subviews

    /// Favicon view (placeholder for now).
    private var faviconView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(colorForDomain(tab.url.host))
            .frame(width: 32, height: 32)
            .overlay(
                Text(domainInitial(tab.url.host))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }

    // MARK: - Helper Functions

    /// Generates a consistent color for a domain.
    private func colorForDomain(_ domain: String?) -> Color {
        guard let domain else { return .gray }

        // Simple hash-based color generation
        let hash = domain.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }

    /// Gets the first letter of the domain for favicon placeholder.
    private func domainInitial(_ domain: String?) -> String {
        guard let domain, let first = domain.first else {
            return "?"
        }
        return String(first).uppercased()
    }
}

// MARK: - Draggable Extension

extension TabCard {
    /// Makes the card draggable for association assignment.
    ///
    /// **FR-004**: Support drag-and-drop to move tabs between associations
    ///
    /// - Parameter associationID: The current association ID (nil if ungrouped)
    /// - Returns: Modified view with drag capability
    public func draggable(fromAssociationID associationID: UUID?) -> some View {
        self
            .draggable(DraggableTab(tabID: tab.id, fromAssociationID: associationID))
    }
}

// MARK: - Transferable Types

/// Transferable wrapper for dragging tabs
struct DraggableTab: Codable, Transferable {
    let tabID: String
    let fromAssociationID: UUID?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableTab)
    }
}

extension UTType {
    static let draggableTab = UTType(exportedAs: "com.taborganizer.draggable-tab")
}

// MARK: - Preview

#if DEBUG
#Preview("Default State") {
    TabCard(
        tab: TabInfo(
            id: "tab-1",
            url: URL(string: "https://github.com")!,
            title: "GitHub - Where the world builds software",
            windowID: "window-1",
            index: 0,
            isActive: false,
            isPinned: false
        ),
        isSelected: false,
        onTap: { print("Tapped") },
        onActivate: { print("Activated") }
    )
    .padding()
    .frame(width: 400)
}

#Preview("Selected State") {
    TabCard(
        tab: TabInfo(
            id: "tab-2",
            url: URL(string: "https://stackoverflow.com")!,
            title: "Stack Overflow - Where Developers Learn",
            windowID: "window-1",
            index: 1,
            isActive: true,
            isPinned: false
        ),
        isSelected: true,
        onTap: { print("Tapped") },
        onActivate: { print("Activated") }
    )
    .padding()
    .frame(width: 400)
}

#Preview("Long Title") {
    TabCard(
        tab: TabInfo(
            id: "tab-3",
            url: URL(string: "https://developer.apple.com/documentation/swiftui")!,
            title: "SwiftUI | Apple Developer Documentation - Building User Interfaces Across All Apple Platforms",
            windowID: "window-1",
            index: 2,
            isActive: false,
            isPinned: false
        ),
        isSelected: false,
        onTap: { print("Tapped") },
        onActivate: { print("Activated") }
    )
    .padding()
    .frame(width: 400)
}

#Preview("Multiple Cards") {
    VStack(spacing: 8) {
        TabCard(
            tab: TabInfo(
                id: "tab-1",
                url: URL(string: "https://github.com")!,
                title: "GitHub",
                windowID: "window-1",
                index: 0,
                isActive: false,
                isPinned: false
            ),
            isSelected: false
        )

        TabCard(
            tab: TabInfo(
                id: "tab-2",
                url: URL(string: "https://stackoverflow.com")!,
                title: "Stack Overflow",
                windowID: "window-1",
                index: 1,
                isActive: false,
                isPinned: false
            ),
            isSelected: true
        )

        TabCard(
            tab: TabInfo(
                id: "tab-3",
                url: URL(string: "https://apple.com")!,
                title: "Apple",
                windowID: "window-1",
                index: 2,
                isActive: false,
                isPinned: false
            ),
            isSelected: false
        )
    }
    .padding()
    .frame(width: 400)
}
#endif
