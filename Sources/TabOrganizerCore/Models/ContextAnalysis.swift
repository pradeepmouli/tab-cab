import Foundation

/// AI-generated understanding of tab relationships and similarity
///
/// Immutable value type representing context analysis results.
/// Expires after 5 minutes to ensure freshness.
public struct ContextAnalysis: Codable, Sendable, Identifiable, Equatable {
    /// Unique identifier for the analysis
    public let id: UUID

    /// Reference to the tab being analyzed
    public let sourceTabID: String

    /// Array of similar tab identifiers
    public let relatedTabIDs: [String]

    /// Map of tab ID to similarity score (0.0-1.0)
    public let similarityScores: [String: Double]

    /// Map of tab ID to list of matching criteria
    public let matchingCriteria: [String: [String]]

    /// Extracted keywords from tab content/title
    public let keywords: [String]

    /// Optional AI-classified category
    public let category: String?

    /// Confidence score for the analysis (0.0-1.0)
    public let confidence: Double

    /// Analysis timestamp
    public let analyzedAt: Date

    /// When this analysis becomes stale (default: 5 minutes from analysis)
    public let expiresAt: Date

    // MARK: - Constants

    /// Default expiration duration (5 minutes)
    public static let defaultExpirationDuration: TimeInterval = 5 * 60

    // MARK: - Validation Errors

    public enum ValidationError: Error, LocalizedError {
        case invalidSimilarityScore(tabID: String, score: Double)
        case invalidConfidence(confidence: Double)

        public var errorDescription: String? {
            switch self {
            case .invalidSimilarityScore(let tabID, let score):
                return "Invalid similarity score for tab '\(tabID)': \(score). Must be between 0.0 and 1.0."
            case .invalidConfidence(let confidence):
                return "Invalid confidence score: \(confidence). Must be between 0.0 and 1.0."
            }
        }
    }

    // MARK: - Initialization

    /// Creates a context analysis result
    ///
    /// - Parameters:
    ///   - id: Unique identifier (default: new UUID)
    ///   - sourceTabID: Tab being analyzed
    ///   - relatedTabIDs: Similar tab identifiers
    ///   - similarityScores: Tab ID to similarity score map (0.0-1.0)
    ///   - matchingCriteria: Tab ID to matching criteria list
    ///   - keywords: Extracted keywords
    ///   - category: Optional category classification
    ///   - confidence: Analysis confidence (0.0-1.0)
    ///   - analyzedAt: Analysis timestamp (default: now)
    ///   - expiresAt: Expiration timestamp (default: 5 min from now)
    /// - Throws: `ValidationError` if validation fails
    public init(
        id: UUID = UUID(),
        sourceTabID: String,
        relatedTabIDs: [String] = [],
        similarityScores: [String: Double] = [:],
        matchingCriteria: [String: [String]] = [:],
        keywords: [String] = [],
        category: String? = nil,
        confidence: Double,
        analyzedAt: Date = Date(),
        expiresAt: Date? = nil
    ) throws {
        // Validate similarity scores
        for (tabID, score) in similarityScores {
            guard (0.0...1.0).contains(score) else {
                throw ValidationError.invalidSimilarityScore(tabID: tabID, score: score)
            }
        }

        // Validate confidence
        guard (0.0...1.0).contains(confidence) else {
            throw ValidationError.invalidConfidence(confidence: confidence)
        }

        self.id = id
        self.sourceTabID = sourceTabID
        self.relatedTabIDs = relatedTabIDs
        self.similarityScores = similarityScores
        self.matchingCriteria = matchingCriteria
        self.keywords = keywords
        self.category = category
        self.confidence = confidence
        self.analyzedAt = analyzedAt
        self.expiresAt = expiresAt ?? Date().addingTimeInterval(Self.defaultExpirationDuration)
    }

    // MARK: - Computed Properties

    /// Whether this analysis has expired
    public var isExpired: Bool {
        Date() > expiresAt
    }

    /// Whether this analysis is still valid (not expired)
    public var isValid: Bool {
        !isExpired
    }

    /// Number of related tabs found
    public var relatedTabCount: Int {
        relatedTabIDs.count
    }

    /// Whether any related tabs were found
    public var hasRelatedTabs: Bool {
        !relatedTabIDs.isEmpty
    }

    /// Average similarity score across all related tabs
    public var averageSimilarity: Double {
        guard !similarityScores.isEmpty else { return 0.0 }
        let sum = similarityScores.values.reduce(0.0, +)
        return sum / Double(similarityScores.count)
    }

    /// Time until expiration
    public var timeUntilExpiration: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }

    // MARK: - Query Methods

    /// Returns similarity score for a specific tab
    public func similarityScore(for tabID: String) -> Double? {
        similarityScores[tabID]
    }

    /// Returns matching criteria for a specific tab
    public func matchingCriteria(for tabID: String) -> [String] {
        matchingCriteria[tabID] ?? []
    }

    /// Returns related tabs sorted by similarity (highest first)
    public func sortedRelatedTabs() -> [(tabID: String, score: Double)] {
        relatedTabIDs.compactMap { tabID in
            guard let score = similarityScores[tabID] else { return nil }
            return (tabID, score)
        }
        .sorted { $0.score > $1.score }
    }

    /// Returns only highly similar tabs (score >= threshold)
    public func highlyRelatedTabs(threshold: Double = 0.7) -> [String] {
        relatedTabIDs.filter { tabID in
            (similarityScores[tabID] ?? 0.0) >= threshold
        }
    }
}

// MARK: - Convenience Extensions

extension ContextAnalysis {
    /// Common matching criteria types
    public enum MatchingCriteriaType: String {
        case sameDomain = "domain"
        case sharedKeywords = "keywords"
        case sameCategory = "category"
        case similarContent = "content"
    }

    /// Creates a simple analysis for same-domain tabs
    public static func sameDomainAnalysis(
        sourceTabID: String,
        relatedTabIDs: [String]
    ) throws -> ContextAnalysis {
        var scores: [String: Double] = [:]
        var criteria: [String: [String]] = [:]

        for tabID in relatedTabIDs {
            scores[tabID] = 1.0
            criteria[tabID] = [MatchingCriteriaType.sameDomain.rawValue]
        }

        return try ContextAnalysis(
            sourceTabID: sourceTabID,
            relatedTabIDs: relatedTabIDs,
            similarityScores: scores,
            matchingCriteria: criteria,
            keywords: [],
            confidence: 1.0
        )
    }
}
