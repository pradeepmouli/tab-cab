import Foundation

/// Represents a named collection of tabs
///
/// Immutable value type that can be safely passed across concurrency boundaries.
/// All modifications create new instances following value semantics.
public struct TabGroup: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for the group
    public let id: UUID

    /// User-defined or AI-suggested name (max 50 characters)
    public let name: String

    /// Hex color code for visual distinction (e.g., "#007AFF")
    public let color: String

    /// Whether the group is collapsed in UI
    public let collapsed: Bool

    /// Creation timestamp
    public let createdAt: Date

    /// Last modification timestamp
    public let updatedAt: Date

    /// Array of tab identifiers belonging to this group
    public let tabIDs: [String]

    /// Extensible key-value metadata
    public let metadata: [String: String]

    // MARK: - Validation Constants

    public static let maxNameLength = 50
    public static let defaultColor = "#007AFF"

    // MARK: - Validation Errors

    public enum ValidationError: Error, LocalizedError {
        case nameEmpty
        case nameTooLong(length: Int, maxLength: Int)
        case invalidColorFormat(color: String)

        public var errorDescription: String? {
            switch self {
            case .nameEmpty:
                return "Group name cannot be empty"
            case .nameTooLong(let length, let maxLength):
                return "Group name is too long (\(length) characters). Maximum is \(maxLength) characters."
            case .invalidColorFormat(let color):
                return "Invalid color format '\(color)'. Expected hex format (e.g., #007AFF) or predefined color name."
            }
        }
    }

    // MARK: - Initialization

    /// Creates a new tab group
    ///
    /// - Parameters:
    ///   - id: Unique identifier (default: new UUID)
    ///   - name: Group name (must be non-empty, max 50 chars)
    ///   - color: Hex color code (default: #007AFF)
    ///   - collapsed: Whether collapsed (default: false)
    ///   - createdAt: Creation timestamp (default: now)
    ///   - updatedAt: Update timestamp (default: now)
    ///   - tabIDs: Tab identifiers (default: empty array)
    ///   - metadata: Extensible metadata (default: empty)
    /// - Throws: `ValidationError` if validation fails
    public init(
        id: UUID = UUID(),
        name: String,
        color: String = TabGroup.defaultColor,
        collapsed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tabIDs: [String] = [],
        metadata: [String: String] = [:]
    ) throws {
        // Validate name
        guard !name.isEmpty else {
            throw ValidationError.nameEmpty
        }
        guard name.count <= TabGroup.maxNameLength else {
            throw ValidationError.nameTooLong(length: name.count, maxLength: TabGroup.maxNameLength)
        }

        // Validate color format
        guard Self.isValidColor(color) else {
            throw ValidationError.invalidColorFormat(color: color)
        }

        self.id = id
        self.name = name
        self.color = color
        self.collapsed = collapsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tabIDs = tabIDs
        self.metadata = metadata
    }

    // MARK: - Mutations (Value Semantics)

    /// Returns a new TabGroup with updated name
    public func withName(_ newName: String) throws -> TabGroup {
        try TabGroup(
            id: id,
            name: newName,
            color: color,
            collapsed: collapsed,
            createdAt: createdAt,
            updatedAt: Date(),
            tabIDs: tabIDs,
            metadata: metadata
        )
    }

    /// Returns a new TabGroup with updated color
    public func withColor(_ newColor: String) throws -> TabGroup {
        try TabGroup(
            id: id,
            name: name,
            color: newColor,
            collapsed: collapsed,
            createdAt: createdAt,
            updatedAt: Date(),
            tabIDs: tabIDs,
            metadata: metadata
        )
    }

    /// Returns a new TabGroup with toggled collapse state
    public func withCollapsedToggled() throws -> TabGroup {
        try TabGroup(
            id: id,
            name: name,
            color: color,
            collapsed: !collapsed,
            createdAt: createdAt,
            updatedAt: Date(),
            tabIDs: tabIDs,
            metadata: metadata
        )
    }

    /// Returns a new TabGroup with added tab ID
    public func withTabAdded(_ tabID: String) throws -> TabGroup {
        guard !tabIDs.contains(tabID) else {
            return self // Already contains tab, no change
        }

        return try TabGroup(
            id: id,
            name: name,
            color: color,
            collapsed: collapsed,
            createdAt: createdAt,
            updatedAt: Date(),
            tabIDs: tabIDs + [tabID],
            metadata: metadata
        )
    }

    /// Returns a new TabGroup with removed tab ID
    public func withTabRemoved(_ tabID: String) throws -> TabGroup {
        try TabGroup(
            id: id,
            name: name,
            color: color,
            collapsed: collapsed,
            createdAt: createdAt,
            updatedAt: Date(),
            tabIDs: tabIDs.filter { $0 != tabID },
            metadata: metadata
        )
    }

    /// Returns a new TabGroup with updated metadata
    public func withMetadata(_ newMetadata: [String: String]) throws -> TabGroup {
        try TabGroup(
            id: id,
            name: name,
            color: color,
            collapsed: collapsed,
            createdAt: createdAt,
            updatedAt: Date(),
            tabIDs: tabIDs,
            metadata: newMetadata
        )
    }

    // MARK: - Computed Properties

    /// Whether this group is empty (no tabs)
    public var isEmpty: Bool {
        tabIDs.isEmpty
    }

    /// Number of tabs in this group
    public var tabCount: Int {
        tabIDs.count
    }

    /// Whether this group was created by AI
    public var isAISuggested: Bool {
        metadata["aiSuggested"] == "true"
    }

    // MARK: - Validation Helpers

    /// Validates hex color format (#RRGGBB) or predefined color names
    private static func isValidColor(_ color: String) -> Bool {
        // Hex format validation
        if color.hasPrefix("#") {
            let hex = String(color.dropFirst())
            return hex.count == 6 && hex.allSatisfy { $0.isHexDigit }
        }

        // Predefined color names
        let predefinedColors = ["red", "blue", "green", "yellow", "orange", "purple", "pink", "gray", "black", "white"]
        return predefinedColors.contains(color.lowercased())
    }
}

// MARK: - Convenience Extensions

extension TabGroup {
    /// Predefined color palette
    public static let colorPalette = [
        "#007AFF", // Blue
        "#FF3B30", // Red
        "#34C759", // Green
        "#FF9500", // Orange
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#5856D6", // Indigo
        "#64D2FF"  // Cyan
    ]

    /// Creates a group with a random color from palette
    public static func withRandomColor(name: String) throws -> TabGroup {
        let randomColor = colorPalette.randomElement() ?? defaultColor
        return try TabGroup(name: name, color: randomColor)
    }
}
