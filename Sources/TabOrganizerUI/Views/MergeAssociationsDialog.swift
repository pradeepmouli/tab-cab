//
//  MergeAssociationsDialog.swift
//  TabOrganizerUI
//
//  Dialog for confirming association merge via drag-and-drop.
//  Part of T042.1 implementation.
//

import SwiftUI
import TabOrganizerCore

/// Dialog presented when user attempts to merge two associations by dragging headers.
///
/// **FR-004.2**: Prompt for confirmation when merging associations
public struct MergeAssociationsDialog: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// The source association being merged
    let sourceAssociation: TabAssociation

    /// The target association to merge into
    let targetAssociation: TabAssociation

    /// Callback when merge is confirmed
    let onMerge: () -> Void

    /// Callback when merge is cancelled
    let onCancel: () -> Void

    // MARK: - Initialization

    public init(
        sourceAssociation: TabAssociation,
        targetAssociation: TabAssociation,
        onMerge: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.sourceAssociation = sourceAssociation
        self.targetAssociation = targetAssociation
        self.onMerge = onMerge
        self.onCancel = onCancel
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.triangle.merge")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Merge Associations")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("This will combine all tabs into one association")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Associations being merged
            VStack(spacing: 16) {
                // Source association
                associationCard(
                    association: sourceAssociation,
                    label: "From"
                )

                // Merge arrow
                Image(systemName: "arrow.down")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                // Target association
                associationCard(
                    association: targetAssociation,
                    label: "Into"
                )
            }
            .padding(.vertical)

            // Warning
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text("The '\(sourceAssociation.name)' association will be deleted after merging. This cannot be undone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Merge Associations") {
                    onMerge()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(24)
        .frame(width: 450, height: 550)
    }

    // MARK: - Subviews

    /// Card showing association details.
    @ViewBuilder
    private func associationCard(association: TabAssociation, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(Color(hex: association.color) ?? .gray)
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(association.name)
                        .font(.headline)

                    Text("\(association.tabIDs.count) tab\(association.tabIDs.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MergeAssociationsDialog(
        sourceAssociation: try! TabAssociation(
            id: UUID(),
            name: "Development",
            color: "FF5733",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: ["tab-1", "tab-2", "tab-3"]
        ),
        targetAssociation: try! TabAssociation(
            id: UUID(),
            name: "Research",
            color: "3357FF",
            collapsed: false,
            createdAt: Date(),
            updatedAt: Date(),
            tabIDs: ["tab-4", "tab-5"]
        ),
        onMerge: {
            print("Merge confirmed")
        },
        onCancel: {
            print("Merge cancelled")
        }
    )
}
#endif
