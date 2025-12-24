# AI Analysis API Contract

**Purpose**: Define AI/ML analysis APIs for tab context, similarity, and grouping suggestions  
**Implementation**: `TabOrganizerAI` library

---

## ContextAnalyzer Protocol

Analyzes individual tab content and identifies related tabs.

### analyzeContext(for:allTabs:)

**Signature**:
```swift
func analyzeContext(
    for sourceTab: TabInfo,
    allTabs: [TabInfo]
) async throws -> ContextAnalysis
```

**Description**: Analyze a tab's context and identify related tabs using on-device NaturalLanguage framework.

**Parameters**:
- `sourceTab: TabInfo` - The tab to analyze
- `allTabs: [TabInfo]` - All available tabs to compare against

**Returns**: `ContextAnalysis` with similarity scores and matching criteria

**Throws**:
- `AIError.insufficientData` - Tab has no title or URL to analyze
- `AIError.analysisTimeout` - Analysis took longer than 5 seconds

**Behavior**:
- Extracts keywords from tab title and URL using `NLTagger`
- Computes similarity scores for all tabs (0.0-1.0 scale)
- Identifies matching criteria: domain, keywords, category
- Filters results to top 10 most similar tabs (or all if < 10 matches)
- Excludes source tab from results
- Results cached for 5 minutes (use cached if available)

**Similarity Scoring**:
```
finalScore = (domainMatch * 0.4) + (keywordOverlap * 0.4) + (categoryMatch * 0.2)

domainMatch: 1.0 if same domain, 0.0 otherwise
keywordOverlap: jaccard similarity of keyword sets (0.0-1.0)
categoryMatch: 1.0 if same AI category, 0.0 otherwise
```

**Performance**: <500ms for 50 tabs, <2s for 200 tabs

**Example**:
```swift
let analyzer: ContextAnalyzer = NaturalLanguageContextAnalyzer()
let analysis = try await analyzer.analyzeContext(
    for: TabInfo(url: URL(string: "https://github.com/user/repo")!, title: "GitHub Repo"),
    allTabs: allOpenTabs
)
// analysis.relatedTabIDs: ["tab-5", "tab-12"] (other GitHub tabs)
// analysis.similarityScores: ["tab-5": 0.85, "tab-12": 0.72]
```

---

## TabClassifier Protocol

Classifies tabs into semantic categories using on-device CoreML.

### classify(tab:)

**Signature**:
```swift
func classify(tab: TabInfo) async throws -> TabCategory
```

**Description**: Classify a tab into a semantic category (e.g., "documentation", "shopping", "social").

**Parameters**:
- `tab: TabInfo` - Tab to classify

**Returns**: `TabCategory` enum with confidence score

**Throws**:
- `AIError.classificationFailed` - CoreML model failed to classify
- `AIError.modelNotLoaded` - ML model not available

**Behavior**:
- Uses lightweight CoreML text classification model (~5MB)
- Input: tab title + domain + URL path
- Output: category + confidence score (0.0-1.0)
- Falls back to rule-based heuristics if ML fails
- Results cached per tab (invalidated on navigation)

**Performance**: <100ms per tab (on-device inference)

**TabCategory Enum**:
```swift
enum TabCategory: String, Codable {
    case documentation    // Dev docs, wikis, technical articles
    case news            // News sites, blogs, magazines
    case shopping        // E-commerce, product pages
    case social          // Social media, forums
    case video           // YouTube, Vimeo, streaming
    case productivity    // Email, calendars, project tools
    case development     // GitHub, GitLab, code repos
    case research        // Academic, papers, references
    case entertainment   // Games, media, fun content
    case unknown         // Couldn't classify (low confidence)
    
    var confidence: Double { get set }
}
```

**Example**:
```swift
let classifier: TabClassifier = CoreMLTabClassifier()
let category = try await classifier.classify(
    tab: TabInfo(url: URL(string: "https://docs.swift.org")!, title: "Swift Documentation")
)
// category: .documentation (confidence: 0.92)
```

---

## SimilarityEngine Protocol

Computes pairwise similarity between tabs (used by ContextAnalyzer).

### computeSimilarity(between:and:)

**Signature**:
```swift
func computeSimilarity(
    between tab1: TabInfo,
    and tab2: TabInfo
) async -> Double
```

**Description**: Compute similarity score between two tabs (0.0 = unrelated, 1.0 = identical).

**Parameters**:
- `tab1: TabInfo` - First tab
- `tab2: TabInfo` - Second tab

**Returns**: Similarity score (0.0-1.0)

**Behavior**:
- Combines domain matching, keyword overlap, and category similarity
- Synchronous computation (no async overhead for single comparison)
- Deterministic (same inputs always produce same output)

**Performance**: <1ms per comparison

**Example**:
```swift
let engine: SimilarityEngine = KeywordSimilarityEngine()
let score = await engine.computeSimilarity(
    between: githubTab1,
    and: githubTab2
)
// score: 0.85 (same domain + overlapping keywords)
```

---

## GroupingSuggester Protocol

Generates AI-powered tab grouping suggestions.

### suggestGroups(for:)

**Signature**:
```swift
func suggestGroups(for tabs: [TabInfo]) async throws -> [GroupSuggestion]
```

**Description**: Analyze tabs and suggest logical groupings.

**Parameters**:
- `tabs: [TabInfo]` - All tabs to analyze and group

**Returns**: Array of `GroupSuggestion` with recommended groups

**Throws**:
- `AIError.insufficientTabs` - Need at least 5 tabs for meaningful grouping
- `AIError.analysisTimeout` - Analysis took longer than 5 seconds

**Behavior**:
- Classifies all tabs into categories
- Clusters tabs by domain similarity and keyword overlap
- Generates descriptive group names (e.g., "GitHub Projects", "News Articles")
- Suggests 2-5 groups (avoids over-grouping)
- Each suggested group has 3+ tabs (no single-tab groups)
- Confidence score indicates quality of suggestions

**Algorithm**:
1. Classify all tabs → categories
2. Extract keywords from titles → keyword sets
3. Compute pairwise similarities → similarity matrix
4. Apply clustering algorithm (hierarchical with dynamic threshold)
5. Generate group names from majority keywords + category
6. Return top 5 clusters as suggestions

**Performance**: <5s for 50 tabs, <10s for 200 tabs (acceptable with progress indicator)

**GroupSuggestion Structure**:
```swift
struct GroupSuggestion: Identifiable {
    let id: UUID
    let name: String                    // Suggested group name
    let tabIDs: [String]               // Tabs to include
    let reasoning: String              // Explanation (e.g., "Same domain")
    let confidence: Double             // 0.0-1.0 (how confident is this grouping)
    let keywords: [String]             // Key terms that define this group
}
```

**Example**:
```swift
let suggester: GroupingSuggester = ClusteringGroupingSuggester()
let suggestions = try await suggester.suggestGroups(for: allTabs)
// suggestions: [
//   GroupSuggestion(name: "GitHub Projects", tabIDs: ["tab-1", "tab-5", "tab-9"], confidence: 0.88),
//   GroupSuggestion(name: "Swift Documentation", tabIDs: ["tab-2", "tab-7"], confidence: 0.75)
// ]
```

---

## AIError Enum

```swift
enum AIError: Error, LocalizedError {
    case insufficientData
    case insufficientTabs
    case analysisTimeout
    case classificationFailed
    case modelNotLoaded
    case mlFrameworkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Not enough data to analyze tab context."
        case .insufficientTabs:
            return "Need at least 5 tabs for grouping suggestions."
        case .analysisTimeout:
            return "Analysis took too long (>5s). Try with fewer tabs."
        case .classificationFailed:
            return "Failed to classify tab category."
        case .modelNotLoaded:
            return "ML model not loaded. Check bundle resources."
        case .mlFrameworkUnavailable:
            return "CoreML or NaturalLanguage framework unavailable."
        }
    }
}
```

---

## Implementation Details

### NaturalLanguage Framework Usage

**Keyword Extraction**:
```swift
import NaturalLanguage

let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
tagger.string = tabTitle + " " + urlPath
let keywords = tagger.tags(
    in: tagger.string!.startIndex..<tagger.string!.endIndex,
    unit: .word,
    scheme: .lexicalClass,
    options: [.omitWhitespace, .omitPunctuation]
)
.compactMap { tag, range -> String? in
    guard tag == .noun || tag == .verb else { return nil }
    return String(tagger.string![range]).lowercased()
}
```

**Language Detection** (for internationalization):
```swift
let recognizer = NLLanguageRecognizer()
recognizer.processString(tabTitle)
let language = recognizer.dominantLanguage // .english, .spanish, etc.
```

### CoreML Model

**Model Specification**:
- **Input**: Text (tab title + domain + URL path, max 256 chars)
- **Output**: Category probabilities (10 classes)
- **Model Size**: ~5MB (bundled with extension)
- **Format**: `.mlmodelc` compiled CoreML model

**Training Data** (future enhancement):
- Manually labeled dataset of 5000+ URLs across categories
- Trained offline, bundled with extension (no on-device training)

**Fallback Heuristics** (if CoreML unavailable):
```swift
switch domain {
case _ where domain.contains("github.com"):
    return .development
case _ where domain.contains("youtube.com"):
    return .video
case _ where domain.hasSuffix(".edu"):
    return .research
default:
    return .unknown
}
```

---

## Performance Considerations

**Optimization Strategies**:
1. **Caching**: Context analysis cached for 5 minutes (invalidate on tab changes)
2. **Batching**: Classify tabs in parallel using `TaskGroup` (up to 4 concurrent)
3. **Lazy Analysis**: Only analyze when user triggers "Suggest Groups" (not on every tab open)
4. **Progressive Results**: Show partial suggestions as clustering completes (streaming UI)

**Memory Budget**:
- NLTagger: ~10MB per instance (reuse singleton)
- CoreML model: ~15MB loaded (lazy load on first use)
- Similarity matrix: O(n²) for n tabs (~1MB for 200 tabs)
- **Total: ~30MB** for AI features (acceptable overhead)

---

## Testing Strategy

**Unit Tests**:
- Mock `TabInfo` with known titles/URLs
- Verify similarity scores are deterministic
- Test keyword extraction edge cases (emojis, non-ASCII, empty strings)
- Verify category classification with known examples

**Integration Tests**:
- Load real ML model and verify inference works
- Test full grouping pipeline with 50+ mock tabs
- Verify performance meets <5s requirement

**Mocks for Testing**:
```swift
final class MockContextAnalyzer: ContextAnalyzer {
    var stubbedAnalysis: ContextAnalysis?
    
    func analyzeContext(for sourceTab: TabInfo, allTabs: [TabInfo]) async throws -> ContextAnalysis {
        return stubbedAnalysis ?? ContextAnalysis(/* defaults */)
    }
}
```

---

## Privacy Compliance

✅ **On-Device Only**: All ML processing happens locally (NaturalLanguage, CoreML)  
✅ **No External APIs**: Zero network requests for AI features  
✅ **No Data Transmission**: Tab titles/URLs never leave device  
✅ **Private Tab Exclusion**: Private tabs filtered before analysis  
✅ **Minimal Data Retention**: Context analysis cached for 5 min max (not persisted)

Complies with Constitution Principle II (Privacy-First Data Handling).
