//
//  GroupHeader.swift
//  TabOrganizerUI
//
//  SwiftUI component for tab group header with collapse/expand and actions.
//  Displays group name, color, tab count, and control buttons.
//

import SwiftUI
import TabOrganizerCore

/// Header component for tab groups.
///
/// **Features**:
/// - Group name and color indicator
/// - Tab count badge
/// - Collapse/expand button (FR-003)
/// - Edit and delete actions (FR-005)
/// - Double-click to convert to native (US7, FR-047)
/// - Full accessibility support
///
/// **TDD Approach**: See Preview at bottom for visual testing with sample states.
public struct GroupHeader: View {

    // MARK: - Properties

    /// The tab group
    let group: TabGroup

    /// Number of tabs in group
    let tabCount: Int

    /// Action when collapse/expand is toggled
    let onToggleCollapse: () -> Void

    /// Action when edit is tapped
    let onEdit: () -> Void

    /// Action when delete is tapped
    let onDelete: () -> Void

    /// Action when header is double-clicked (convert to native)
    let onDoubleClick: () -> Void

    // MARK: - State

    @State private var isHovered: Bool = false

    // MARK: - Initialization

    public init(
        group: TabGroup,
        tabCount: Int,
        onToggleCollapse: @escaping () -> Void = {},
        onEdit: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {},
        onDoubleClick: @escaping () -> Void = {}
    ) {
        self.group = group
        self.tabCount = tabCount
        self.onToggleCollapse = onToggleCollapse
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onDoubleClick = onDoubleClick
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: group.color) ?? .blue)
                .frame(width: 4)
                .accessibilityHidden(true)

            // Collapse/expand button
            Button {
                onToggleCollapse()
            } label: {
                Image(systemName: group.collapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(group.collapsed ? "Expand group" : "Collapse group")

            // Group name
            Text(group.name)
                .font(.headline)
                .foregroundStyle(.primary)

            // Tab count badge
            Text("\(tabCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                )
                .accessibilityLabel("\(tabCount) tabs")

            Spacer()

            // Action buttons (visible on hover)
            if isHovered {
                HStack(spacing: 8) {
                    // Edit button
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit group")

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete group")
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .gesture(
            // Double-click to convert to native (US7, FR-047)
            TapGesture(count: 2)
                .onEnded {
                    onDoubleClick()
                }
        )
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Group \(group.name), \(tabCount) tabs, \(group.collapsed ? "collapsed" : "expanded")")
        .accessibilityHint("Double click to convert to native tab group, or use buttons to edit or delete")
        .accessibilityIdentifier("GroupHeader_\(group.id)")
    }
}

// MARK: - Color Extension

extension Color {
    /// Creates a Color from a hex string.
    ///
    /// - Parameter hex: Hex color string (e.g., "#FF0000" or "FF0000")
    /// - Returns: Color if valid hex, nil otherwise
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }

        let r, g, b: Double
        switch hex.count {
        case 6: // RGB
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Expanded State") {
    GroupHeader(
        group: TabGroup(
            id: UUID(),
            name: "Work",
            color: "#0066CC",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: ["tab-1", "tab-2", "tab-3"],
            metadata: [:]
        ),
        tabCount: 3,
        onToggleCollapse: { print("Toggle collapse") },
        onEdit: { print("Edit") },
        onDelete: { print("Delete") },
        onDoubleClick: { print("Convert to native") }
    )
    .padding()
    .frame(width: 400)
}

#Preview("Collapsed State") {
    GroupHeader(
        group: TabGroup(
            id: UUID(),
            name: "Research",
            color: "#00CC66",
            collapsed: true,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: ["tab-1", "tab-2"],
            metadata: [:]
        ),
        tabCount: 2,
        onToggleCollapse: { print("Toggle collapse") },
        onEdit: { print("Edit") },
        onDelete: { print("Delete") }
    )
    .padding()
    .frame(width: 400)
}

#Preview("Many Tabs") {
    GroupHeader(
        group: TabGroup(
            id: UUID(),
            name: "Shopping",
            color: "#FF6600",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: Array(repeating: "tab", count: 25),
            metadata: [:]
        ),
        tabCount: 25,
        onToggleCollapse: { print("Toggle collapse") },
        onEdit: { print("Edit") },
        onDelete: { print("Delete") }
    )
    .padding()
    .frame(width: 400)
}

#Preview("Multiple Headers") {
    VStack(spacing: 8) {
        GroupHeader(
            group: TabGroup(
                id: UUID(),
                name: "Work",
                color: "#0066CC",
                collapsed: false,
                createdAt: Date(),
                updatedAt: Date(),
                tabIDs: ["tab-1", "tab-2", "tab-3"],
                metadata: [:]
            ),
            tabCount: 3
        )

        GroupHeader(
            group: TabGroup(
                id: UUID(),
                name: "Research",
                color: "#00CC66",
                collapsed: true,
                createdAt: Date(),
                updatedAt: Date(),
                tabIDs: ["tab-4", "tab-5"],
                metadata: [:]
            ),
            tabCount: 2
        )

        GroupHeader(
            group: TabGroup(
                id: UUID(),
                name: "Shopping",
                color: "#FF6600",
                collapsed: false,
                createdAt: Date(),
                updatedAt: Date(),
                tabIDs: ["tab-6"],
                metadata: [:]
            ),
            tabCount: 1
        )
    }
    .padding()
    .frame(width: 400)
}
#endif
