import Foundation

/// Represents a named collection of tabs created by the user or AI suggestions.
///
/// TabGroup is the primary organizational unit in the Tab Organizer extension.
/// It provides a way to logically group related tabs together with visual distinction
/// (color coding) and UI management (collapsible/expandable).
public struct TabGroup: Identifiable, Codable, Sendable {
    /// Unique identifier for the group
    public let id: UUID
    
    /// User-defined or AI-suggested name (e.g., "Work", "Research")
    public var name: String
    
    /// Hex color code for visual distinction (e.g., "#007AFF")
    public var color: String
    
    /// Whether the group is collapsed in UI
    public var collapsed: Bool
    
    /// Creation timestamp
    public let createdAt: Date
    
    /// Last modification timestamp
    public var updatedAt: Date
    
    /// Array of tab identifiers belonging to this group
    public var tabIDs: [String]
    
    /// Extensible key-value metadata (e.g., "aiSuggested": "true")
    public var metadata: [String: String]
    
    /// Maximum allowed characters for group name
    public static let maxNameLength = 50
    
    /// Default color for new groups
    public static let defaultColor = "#007AFF"
    
    /// Creates a new TabGroup with the specified properties
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Group name
    ///   - color: Hex color code (defaults to system blue)
    ///   - collapsed: Initial collapsed state (defaults to false)
    ///   - tabIDs: Array of tab IDs to include (defaults to empty)
    ///   - metadata: Additional metadata (defaults to empty)
    public init(
        id: UUID = UUID(),
        name: String,
        color: String = TabGroup.defaultColor,
        collapsed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tabIDs: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.collapsed = collapsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tabIDs = tabIDs
        self.metadata = metadata
    }
    
    /// Validates the TabGroup against business rules
    ///
    /// - Throws: `ValidationError` if any validation rule fails
    public func validate() throws {
        // Name must be non-empty
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyName
        }
        
        // Name must not exceed max length
        guard name.count <= TabGroup.maxNameLength else {
            throw ValidationError.nameTooLong(max: TabGroup.maxNameLength)
        }
        
        // Color must be valid hex format or predefined color
        guard isValidColor(color) else {
            throw ValidationError.invalidColor(color)
        }
    }
    
    /// Checks if a color string is valid (hex format or predefined name)
    private func isValidColor(_ color: String) -> Bool {
        // Check hex format: #RGB or #RRGGBB
        let hexPattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        if let regex = try? NSRegularExpression(pattern: hexPattern),
           regex.firstMatch(in: color, range: NSRange(color.startIndex..., in: color)) != nil {
            return true
        }
        
        // Check predefined colors
        let predefinedColors = ["blue", "red", "green", "yellow", "orange", "purple", "pink", "gray"]
        return predefinedColors.contains(color.lowercased())
    }
    
    /// Creates a copy of this group with updated modification timestamp
    public func withUpdatedTimestamp() -> TabGroup {
        var copy = self
        copy.updatedAt = Date()
        return copy
    }
    
    /// Creates a copy of this group with a new name
    public func withName(_ newName: String) -> TabGroup {
        var copy = self
        copy.name = newName
        copy.updatedAt = Date()
        return copy
    }
    
    /// Creates a copy of this group with updated tab IDs
    public func withTabIDs(_ newTabIDs: [String]) -> TabGroup {
        var copy = self
        copy.tabIDs = newTabIDs
        copy.updatedAt = Date()
        return copy
    }
    
    /// Adds a tab to this group
    public func withAddedTab(_ tabID: String) -> TabGroup {
        guard !tabIDs.contains(tabID) else { return self }
        var copy = self
        copy.tabIDs.append(tabID)
        copy.updatedAt = Date()
        return copy
    }
    
    /// Removes a tab from this group
    public func withRemovedTab(_ tabID: String) -> TabGroup {
        var copy = self
        copy.tabIDs.removeAll { $0 == tabID }
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Hashable & Equatable

extension TabGroup: Hashable {
    /// Hash based on ID only for Set/Dictionary usage
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equality based on ID only
    public static func == (lhs: TabGroup, rhs: TabGroup) -> Bool {
        lhs.id == rhs.id
    }
}

/// Validation errors for TabGroup
public enum ValidationError: Error, LocalizedError, Sendable {
    case emptyName
    case nameTooLong(max: Int)
    case invalidColor(String)
    case duplicateName(String)
    
    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Group name cannot be empty"
        case .nameTooLong(let max):
            return "Group name cannot exceed \(max) characters"
        case .invalidColor(let color):
            return "Invalid color format: \(color)"
        case .duplicateName(let name):
            return "A group named '\(name)' already exists"
        }
    }
}
