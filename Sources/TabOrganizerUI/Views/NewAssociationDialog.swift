//
//  NewAssociationDialog.swift
//  TabOrganizerUI
//
//  Dialog for naming a new association created via drag-to-associate.
//  Part of T042 implementation.
//

import SwiftUI
import TabOrganizerCore

/// Dialog presented when user creates a new association by dragging tabs together.
///
/// **FR-001.1**: Prompt users to name the association when tabs are dragged together
public struct NewAssociationDialog: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// The first tab in the association
    let tab1: TabInfo

    /// The second tab in the association
    let tab2: TabInfo

    /// Callback when association is created
    let onCreate: (String, String) -> Void

    /// Callback when dialog is cancelled
    let onCancel: () -> Void

    // MARK: - State

    @State private var associationName: String
    @State private var selectedColor: String = TabAssociation.defaultColor

    // MARK: - Initialization

    public init(
        tab1: TabInfo,
        tab2: TabInfo,
        onCreate: @escaping (String, String) -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.tab1 = tab1
        self.tab2 = tab2
        self.onCreate = onCreate
        self.onCancel = onCancel

        // Generate suggested name from tabs
        _associationName = State(initialValue: Self.suggestName(from: tab1, and: tab2))
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Create Association")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Name your new tab association")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Tabs being associated
            VStack(alignment: .leading, spacing: 12) {
                Text("Tabs to associate:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    tabPreview(tab1)
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                    tabPreview(tab2)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
            }

            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Association Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Enter name", text: $associationName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Association name")
            }

            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(TabAssociation.colorPalette, id: \.self) { color in
                        colorButton(color)
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Create") {
                    onCreate(associationName, selectedColor)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(associationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 450, height: 500)
    }

    // MARK: - Subviews

    /// Preview of a tab in the dialog.
    @ViewBuilder
    private func tabPreview(_ tab: TabInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tab.title)
                .font(.caption)
                .lineLimit(1)

            Text(tab.url.host ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Color selection button.
    @ViewBuilder
    private func colorButton(_ color: String) -> some View {
        Button {
            selectedColor = color
        } label: {
            Circle()
                .fill(Color(hex: color) ?? .gray)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(color)")
        .accessibilityAddTraits(selectedColor == color ? [.isSelected] : [])
    }

    // MARK: - Name Suggestion

    /// Suggests an association name based on the tabs' content.
    ///
    /// **Strategy**:
    /// 1. If both tabs are from the same domain, use domain name
    /// 2. Otherwise, suggest a generic name
    ///
    /// - Parameters:
    ///   - tab1: First tab
    ///   - tab2: Second tab
    /// - Returns: Suggested association name
    private static func suggestName(from tab1: TabInfo, and tab2: TabInfo) -> String {
        let domain1 = tab1.url.host ?? ""
        let domain2 = tab2.url.host ?? ""

        // Same domain - use domain name
        if domain1 == domain2, !domain1.isEmpty {
            // Clean up domain (remove www., .com, etc.)
            let cleanDomain = domain1
                .replacingOccurrences(of: "www.", with: "")
                .components(separatedBy: ".").first ?? domain1

            return cleanDomain.capitalized
        }

        // Different domains - suggest generic name
        return "New Association"
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NewAssociationDialog(
        tab1: TabInfo(
            id: "tab-1",
            url: URL(string: "https://github.com/apple/swift")!,
            title: "Swift Programming Language",
            windowID: "window-1",
            index: 0,
            isActive: false,
            isPinned: false
        ),
        tab2: TabInfo(
            id: "tab-2",
            url: URL(string: "https://github.com/vapor/vapor")!,
            title: "Vapor Framework",
            windowID: "window-1",
            index: 1,
            isActive: false,
            isPinned: false
        ),
        onCreate: { name, color in
            print("Created association: \(name) with color \(color)")
        }
    )
}
#endif
