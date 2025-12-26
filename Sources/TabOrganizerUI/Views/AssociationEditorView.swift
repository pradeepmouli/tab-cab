//
//  GroupEditorView.swift
//  TabOrganizerUI
//
//  Sheet view for creating or editing tab associations.
//  Supports name, color selection, and validation.
//

import SwiftUI
import TabOrganizerCore

/// View for creating or editing a tab association.
///
/// **Features**:
/// - Create new group or edit existing (FR-001, FR-005)
/// - Name input with validation
/// - Color picker
/// - Real-time validation feedback
/// - Accessibility support
///
/// **TDD Approach**: See Preview at bottom for visual testing.
public struct GroupEditorView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(ExtensionState.self) private var state

    // MARK: - Properties

    /// The group being edited (nil = create new)
    let group: TabAssociation?

    /// The window ID
    let windowID: String

    // MARK: - State

    @State private var name: String
    @State private var selectedColor: String
    @State private var isSaving: Bool = false
    @State private var validationError: String?

    // Predefined color options
    private let colorOptions = [
        "#0066CC", // Blue
        "#00CC66", // Green
        "#FF6600", // Orange
        "#CC00CC", // Purple
        "#FF0000", // Red
        "#00CCCC", // Cyan
        "#CCCC00", // Yellow
        "#666666"  // Gray
    ]

    // MARK: - Initialization

    public init(group: TabAssociation?, windowID: String) {
        self.group = group
        self.windowID = windowID

        // Initialize state from group or defaults
        _name = State(initialValue: group?.name ?? "")
        _selectedColor = State(initialValue: group?.color ?? "#0066CC")
    }

    // MARK: - Computed Properties

    private var isEditing: Bool {
        group != nil
    }

    private var title: String {
        isEditing ? "Edit Group" : "New Group"
    }

    private var saveButtonLabel: String {
        isEditing ? "Save" : "Create"
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                // Name section
                Section {
                    TextField("Group Name", text: $name)
                        .textFieldStyle(.plain)
                        .accessibilityLabel("Group name")
                        .accessibilityIdentifier("GroupNameField")

                    if let error = validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityLabel("Validation error: \(error)")
                    }
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your group a descriptive name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Color section
                Section {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { colorHex in
                            colorButton(colorHex)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                } footer: {
                    Text("Choose a color to identify this group")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Preview section
                Section {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: selectedColor) ?? .blue)
                            .frame(width: 4, height: 32)

                        Text(name.isEmpty ? "Group Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.05))
                    )
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonLabel) {
                        save()
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(saveButtonLabel)
                    .accessibilityIdentifier("SaveButton")
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
        .frame(width: 400, height: 500)
        // MARK: - Accessibility
        .accessibilityLabel(title)
        .accessibilityIdentifier("GroupEditorView")
    }

    // MARK: - Subviews

    /// Color selection button.
    @ViewBuilder
    private func colorButton(_ colorHex: String) -> some View {
        Button {
            selectedColor = colorHex
        } label: {
            Circle()
                .fill(Color(hex: colorHex) ?? .gray)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: selectedColor == colorHex ? 3 : 0)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(selectedColor == colorHex ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(colorHex)")
        .accessibilityAddTraits(selectedColor == colorHex ? [.isSelected] : [])
    }

    // MARK: - Actions

    /// Saves the group (create or update).
    private func save() {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "Group name cannot be empty"
            return
        }

        validationError = nil
        isSaving = true

        Task {
            do {
                if let existingGroup = group {
                    // Update existing group
                    let updatedGroup = try existingGroup
                        .withName(trimmedName)
                        .withColor(selectedColor)

                    try await state.associationService.updateAssociation(
                        updatedGroup,
                        windowID: windowID
                    )
                } else {
                    // Create new group
                    _ = try await state.associationService.createAssociation(
                        name: trimmedName,
                        color: selectedColor,
                        windowID: windowID
                    )
                }

                await MainActor.run {
                    isSaving = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isSaving = false
                    validationError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Create New Group") {
    GroupEditorView(group: nil, windowID: "window-1")
        .environment(ExtensionState.preview)
}

#Preview("Edit Existing Group") {
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

    GroupEditorView(group: sampleGroup, windowID: "window-1")
        .environment(ExtensionState.preview)
}

#Preview("With Long Name") {
    let longNameGroup = try! TabAssociation(
        id: UUID(),
        name: "Work Projects and Documentation for Q4 2025",
        color: "#00CC66",
        collapsed: false,
        createdAt: Date(),
        updatedAt: Date(),
        tabIDs: [],
        metadata: [:]
    )

    GroupEditorView(group: longNameGroup, windowID: "window-1")
        .environment(ExtensionState.preview)
}
#endif
