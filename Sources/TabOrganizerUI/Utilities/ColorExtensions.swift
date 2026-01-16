//
//  ColorExtensions.swift
//  TabOrganizerUI
//
//  Color utility extensions for the TabOrganizer UI.
//

import SwiftUI

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
