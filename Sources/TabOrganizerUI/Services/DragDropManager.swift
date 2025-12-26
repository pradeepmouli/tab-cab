//
//  DragDropManager.swift
//  TabOrganizerUI
//
//  Manages drag-and-drop operations for tab association creation and management.
//  Implements T042 and T042.1 requirements.
//

import Foundation
import TabOrganizerCore

/// Manager for handling drag-and-drop interactions in tab association UI.
///
/// **Responsibilities**:
/// - Tab-onto-tab association creation (T042)
/// - Tab-onto-association-member addition (T042)
/// - Tab-to-empty-area removal (T042)
/// - Association merge via header drag (T042.1)
///
/// **Architecture**: Observable class for SwiftUI integration
@MainActor
@Observable
public final class DragDropManager {

    // MARK: - Types

    /// Represents an item being dragged
    public enum DragItem {
        case tab(id: String, fromAssociationID: UUID?)
        case association(id: UUID)
    }

    /// Represents a drop target
    public enum DropTarget {
        case tab(id: String, inAssociationID: UUID?)
        case association(id: UUID)
        case emptyArea
    }

    /// Result of a drag-drop operation
    public enum DropResult {
        case createNewAssociation(tab1: String, tab2: String)
        case addToAssociation(tabID: String, associationID: UUID, fromAssociationID: UUID?)
        case removeFromAssociation(tabID: String, fromAssociationID: UUID)
        case mergeAssociations(source: UUID, target: UUID)
        case noAction
    }

    // MARK: - State

    /// Currently dragged item
    public private(set) var currentDragItem: DragItem?

    /// Whether a drag is in progress
    public var isDragging: Bool {
        currentDragItem != nil
    }

    // MARK: - Drag Operations

    /// Begins dragging a tab.
    ///
    /// - Parameters:
    ///   - tabID: The tab being dragged
    ///   - fromAssociationID: The association it's currently in (nil if ungrouped)
    public func beginDragTab(tabID: String, fromAssociationID: UUID?) {
        currentDragItem = .tab(id: tabID, fromAssociationID: fromAssociationID)
    }

    /// Begins dragging an association header.
    ///
    /// - Parameter associationID: The association being dragged
    public func beginDragAssociation(associationID: UUID) {
        currentDragItem = .association(id: associationID)
    }

    /// Ends the current drag operation.
    public func endDrag() {
        currentDragItem = nil
    }

    // MARK: - Drop Operations

    /// Handles a drop operation and determines the result.
    ///
    /// **FR-001**: Create association by dragging tab onto tab
    /// **FR-004**: Add to association by dragging onto member
    /// **FR-004.1**: Remove by dragging to empty area
    /// **FR-004.2**: Merge by dragging header onto header
    ///
    /// - Parameter target: The drop target
    /// - Returns: The result of the drop operation
    public func handleDrop(on target: DropTarget) -> DropResult {
        defer { endDrag() }

        guard let dragItem = currentDragItem else {
            return .noAction
        }

        switch (dragItem, target) {

        // Tab dropped onto another tab
        case let (.tab(draggedTabID, fromAssociationID), .tab(targetTabID, targetAssociationID)):
            return handleTabOnTab(
                draggedTabID: draggedTabID,
                fromAssociationID: fromAssociationID,
                targetTabID: targetTabID,
                targetAssociationID: targetAssociationID
            )

        // Tab dropped onto an association
        case let (.tab(draggedTabID, fromAssociationID), .association(targetAssociationID)):
            // Add to existing association
            return .addToAssociation(
                tabID: draggedTabID,
                associationID: targetAssociationID,
                fromAssociationID: fromAssociationID
            )

        // Tab dropped in empty area
        case let (.tab(draggedTabID, fromAssociationID), .emptyArea):
            if let fromID = fromAssociationID {
                return .removeFromAssociation(tabID: draggedTabID, fromAssociationID: fromID)
            } else {
                return .noAction // Already ungrouped
            }

        // Association dropped onto another association
        case let (.association(sourceID), .association(targetID)):
            guard sourceID != targetID else {
                return .noAction // Can't merge with self
            }
            return .mergeAssociations(source: sourceID, target: targetID)

        // Invalid combinations
        default:
            return .noAction
        }
    }

    // MARK: - Private Helpers

    /// Handles tab-onto-tab drop logic.
    ///
    /// **FR-001**: If both tabs are ungrouped, create new association
    /// **FR-004**: If target is in an association, add dragged tab to it
    ///
    /// - Parameters:
    ///   - draggedTabID: The tab being dragged
    ///   - fromAssociationID: Where it's coming from
    ///   - targetTabID: The tab it's dropped onto
    ///   - targetAssociationID: The target's association
    /// - Returns: The appropriate drop result
    private func handleTabOnTab(
        draggedTabID: String,
        fromAssociationID: UUID?,
        targetTabID: String,
        targetAssociationID: UUID?
    ) -> DropResult {

        // Case 1: Both tabs are ungrouped - create new association
        if fromAssociationID == nil && targetAssociationID == nil {
            return .createNewAssociation(tab1: draggedTabID, tab2: targetTabID)
        }

        // Case 2: Target is in an association - add dragged tab to it
        if let targetAssocID = targetAssociationID {
            return .addToAssociation(
                tabID: draggedTabID,
                associationID: targetAssocID,
                fromAssociationID: fromAssociationID
            )
        }

        // Case 3: Dragged tab is in an association, target is not
        // Add target tab to the association
        if let fromAssocID = fromAssociationID {
            return .addToAssociation(
                tabID: targetTabID,
                associationID: fromAssocID,
                fromAssociationID: nil
            )
        }

        return .noAction
    }

    // MARK: - Validation

    /// Checks if a drop target is valid for the current drag item.
    ///
    /// - Parameter target: The proposed drop target
    /// - Returns: True if the drop is valid
    public func isValidDropTarget(_ target: DropTarget) -> Bool {
        guard let dragItem = currentDragItem else {
            return false
        }

        switch (dragItem, target) {
        // Tab can be dropped on other tabs, associations, or empty area
        case (.tab, .tab), (.tab, .association), (.tab, .emptyArea):
            return true

        // Association can only be dropped on other associations
        case let (.association(sourceID), .association(targetID)):
            return sourceID != targetID // Can't merge with self

        // Other combinations are invalid
        default:
            return false
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension DragDropManager {
    /// Creates a manager for previews with initial state.
    public static var preview: DragDropManager {
        DragDropManager()
    }
}
#endif
