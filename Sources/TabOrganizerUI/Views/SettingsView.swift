//
//  SettingsView.swift
//  TabOrganizerUI
//
//  Settings view for configuring extension behavior.
//  Implements FR-034 to FR-037 (configuration options).
//

import SwiftUI
import TabOrganizerCore

/// Settings view for extension configuration.
///
/// **Features** (FR-034 to FR-037):
/// - Feature toggles (highlighting, auto-rearrange, cleanup)
/// - Inactivity threshold configuration
/// - Keyboard shortcuts display
/// - Backup/restore (future)
/// - Privacy policy link
///
/// **TDD Approach**: See Preview at bottom for visual testing.
public struct SettingsView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(ExtensionState.self) private var state

    // MARK: - State

    @State private var settings: UserSettings
    @State private var isSaving: Bool = false

    // MARK: - Initialization

    public init() {
        // Load settings from service or use defaults
        // TODO: Load from SettingsService in Phase 4+
        _settings = State(initialValue: try! UserSettings(
            contextHighlightingEnabled: true,
            autoRearrangementEnabled: false,
            cleanupSuggestionsEnabled: true,
            inactivityThreshold: 1800, // 30 minutes
            autoCloseEnabled: false,
            autoCloseUngroupedOnly: true
        ))
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                // Feature Toggles (FR-035)
                Section {
                    Toggle("Context Highlighting", isOn: Binding(
                        get: { settings.contextHighlightingEnabled },
                        set: { newValue in
                            settings = (try? settings.withContextHighlighting(newValue)) ?? settings
                        }
                    ))
                    .accessibilityLabel("Enable context highlighting")

                    Text("Highlight related tabs when you select a tab")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Auto-Rearrangement", isOn: Binding(
                        get: { settings.autoRearrangementEnabled },
                        set: { newValue in
                            settings = (try? settings.withAutoRearrangement(newValue)) ?? settings
                        }
                    ))
                    .accessibilityLabel("Enable auto-rearrangement")

                    Text("Automatically move related tabs next to each other")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Tab Cleanup", isOn: Binding(
                        get: { settings.cleanupSuggestionsEnabled },
                        set: { newValue in
                            settings = (try? settings.withCleanupSuggestions(newValue)) ?? settings
                        }
                    ))
                    .accessibilityLabel("Enable tab cleanup")

                    Text("Suggest closing inactive tabs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Features")
                } footer: {
                    Text("Enable or disable extension features")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Cleanup Settings (FR-034)
                if settings.cleanupSuggestionsEnabled {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Inactivity Threshold")
                                Spacer()
                                Text(thresholdLabel)
                                    .foregroundStyle(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { settings.inactivityThreshold },
                                    set: { newValue in
                                        settings = (try? settings.withInactivityThreshold(newValue)) ?? settings
                                    }
                                ),
                                in: 900...14400, // 15 min to 4 hours
                                step: 900 // 15 min increments
                            )
                            .accessibilityLabel("Inactivity threshold: \(thresholdLabel)")
                        }

                        Toggle("Auto-close ungrouped tabs", isOn: Binding(
                            get: { settings.autoCloseUngroupedOnly },
                            set: { newValue in
                                settings = (try? settings.withAutoCloseUngroupedOnly(newValue)) ?? settings
                            }
                        ))
                        .accessibilityLabel("Auto-close ungrouped tabs")

                        Text("Automatically close ungrouped tabs after threshold")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Cleanup Settings")
                    } footer: {
                        Text("Configure when and how tabs are suggested for cleanup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Keyboard Shortcuts (FR-037)
                Section {
                    shortcutRow(label: "Create Group", shortcut: "⌘N")
                    shortcutRow(label: "Suggest Groups", shortcut: "⌘⇧G")
                    shortcutRow(label: "Toggle Highlighting", shortcut: "⌘H")
                    shortcutRow(label: "Settings", shortcut: "⌘,")
                } header: {
                    Text("Keyboard Shortcuts")
                }

                // Privacy & Data (FR-033)
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data Storage")
                                .font(.body)
                            Text("All data stored locally on your device")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }

                    Button {
                        // TODO: Show privacy policy
                    } label: {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("View privacy policy")
                } header: {
                    Text("Privacy")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("001")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
            .disabled(isSaving)
        }
        .frame(width: 500, height: 600)
        // MARK: - Accessibility
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("SettingsView")
    }

    // MARK: - Subviews

    /// Keyboard shortcut row.
    @ViewBuilder
    private func shortcutRow(label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                )
        }
        .accessibilityLabel("\(label): \(shortcut)")
    }

    // MARK: - Computed Properties

    /// Human-readable label for inactivity threshold.
    private var thresholdLabel: String {
        let minutes = settings.inactivityThreshold / 60
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            return "\(hours) hr"
        }
    }

    // MARK: - Actions

    /// Saves settings.
    private func save() {
        isSaving = true

        Task {
            // TODO: Save to SettingsService in Phase 4+
            try? await Task.sleep(for: .milliseconds(500)) // Simulate save

            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Default Settings") {
    SettingsView()
        .environment(ExtensionState.preview)
}

#Preview("All Features Enabled") {
    var settingsView = SettingsView()
    // Note: Can't modify @State from preview, showing default
    return settingsView
        .environment(ExtensionState.preview)
}
#endif
