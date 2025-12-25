<!--
Sync Impact Report:
Version: 0.0.0 → 1.0.0 (Initial constitution creation)
Added Sections:
  - Core Principles (I-VII): Swift/iOS native development standards
  - Development Workflow: Speckit workflow selection and quality gates
  - Governance: Amendment procedures and compliance

Templates Requiring Updates:
  ✅ plan-template.md - Constitution Check section already present
  ✅ spec-template.md - User story format aligns with TDD principle
  ✅ tasks-template.md - Task organization supports user story independence
  
Follow-up TODOs: None - all placeholders resolved

Commit Message: docs: establish Tab Cab constitution v1.0.0 (Swift 6 + speckit workflows)
-->

# Tab Cab Constitution

## Core Principles

### I. Swift Native First

All code MUST leverage Swift's modern language features and native iOS frameworks:
- Swift 6.1+ with strict concurrency mode enabled (no GCD, actor-based isolation)
- SwiftUI for all UI (no UIKit unless framework interop requires it)
- Swift Testing framework with @Test macros (no XCTest for new tests)
- Swift Package Manager for modular architecture (no CocoaPods/Carthage)
- Value types (struct/enum) by default; class only when reference semantics required

**Rationale**: Swift 6 concurrency safety prevents race conditions at compile time. Native frameworks ensure long-term maintainability and platform optimization.

### II. Model-View Architecture (No ViewModels)

SwiftUI views MUST use native state management patterns:
- @State for view-local state
- @Observable for shared model objects (replaces ObservableObject/@Published)
- @Environment for dependency injection and app-wide services
- @Binding for parent-child data flow
- Business logic belongs in services/actors, NOT in ViewModel classes

**Rationale**: SwiftUI's native observation system is optimized for fine-grained updates. ViewModels add indirection without benefit when @Observable provides the same capabilities with better performance.

### III. Test-First Development (NON-NEGOTIABLE)

All features MUST follow TDD:
1. Write Swift Testing tests (@Test, #expect) that FAIL
2. Get user approval on failing tests
3. Implement minimal code to make tests pass
4. Refactor while keeping tests green

Contract tests MUST verify protocol boundaries. Integration tests MUST cover cross-module interactions.

**Rationale**: Tests written first define clear success criteria. Failing tests prove the test suite catches regressions. This is the foundation of quality assurance.

**Exception**: Hotfix workflow allows implementation before tests with mandatory test addition within 48 hours of fix deployment.

### IV. Protocol-Oriented Design

Public APIs MUST be defined as Swift protocols:
- Use protocol-oriented design for testability (e.g., TabManaging, StorageAdapter)
- Provide mock implementations for every protocol used in tests
- Actors MUST conform to Sendable and use protocol abstraction for dependencies
- All protocol methods MUST have documented pre/post-conditions

**Rationale**: Protocols enable dependency injection, testing with mocks, and runtime polymorphism without inheritance complexity.

### V. Strict Concurrency & Thread Safety

All asynchronous code MUST use Swift Concurrency:
- @MainActor for all UI and SwiftUI view code
- Actors for state that needs cross-context isolation (e.g., storage, tracking services)
- async/await for asynchronous operations (no completion handlers)
- All types crossing concurrency boundaries MUST be Sendable
- Use .task { } modifier on SwiftUI views for lifecycle-bound async work (NOT Task { } in onAppear)

**Rationale**: Swift 6 strict concurrency checking eliminates data races at compile time. .task automatically cancels work when views disappear, preventing memory leaks.

### VI. Simplicity & YAGNI

Features MUST start with the simplest solution:
- No abstractions until the third use case (avoid premature generalization)
- No feature flags unless actively supporting multiple versions in production
- Delete unused code completely (no comments, no `_unused` variables)
- Prefer three lines of similar code over one premature helper function

Complexity MUST be justified in the plan.md Complexity Tracking table.

**Rationale**: Simple code is maintainable code. Premature abstraction increases cognitive load without delivering user value.

### VII. User-Centric Documentation

Every feature MUST have:
- spec.md with prioritized user stories (P1/P2/P3) that are independently testable
- plan.md with concrete file paths and justification for complexity
- tasks.md organized by user story for incremental delivery
- Each user story MUST be deliverable as a standalone MVP slice

API contracts (protocols) MUST document expected behavior, edge cases, and error conditions.

**Rationale**: Features exist to serve users. Prioritized, independently testable stories enable incremental value delivery and clear progress measurement.

## Development Workflow

### Core Workflow (Feature Development)

Full feature development cycle:
1. **Specify**: `/speckit.specify <description>` → spec.md with prioritized user stories
2. **Clarify**: `/speckit.clarify` → resolve ambiguities, update spec.md
3. **Plan**: `/speckit.plan` → plan.md with technical design, file paths, complexity justification
4. **Tasks**: `/speckit.tasks` → tasks.md organized by user story with dependencies
5. **Implement**: `/speckit.implement` → execute tasks, TDD, commit per task/logical group
6. **Review**: `/speckit.review <task_id>` → verify against spec, update task status

### Extension Workflows

Development activities SHALL use the appropriate workflow type:

- **Baseline** (`/speckit.baseline`): Project context establishment - captures architecture, tech stack, existing features
- **Bugfix** (`/speckit.bugfix "<description>"`): Defect remediation with regression test requirement
- **Enhancement** (`/speckit.enhance "<description>"`): Minor improvements with single-phase plan (≤7 tasks)
- **Modification** (`/speckit.modify <feature_num> "<description>"`): Changes to existing features with impact analysis
- **Refactoring** (`/speckit.refactor "<description>"`): Code quality improvements with behavior preservation
- **Hotfix** (`/speckit.hotfix "<incident>"`): Emergency production issues with expedited process
- **Deprecation** (`/speckit.deprecate <feature_num> "<reason>"`): Feature sunset with phased rollout

**Wrong workflow SHALL NOT be used**: Features must not bypass specification, bugs must not skip regression tests, refactorings must not alter behavior.

### Quality Gates by Workflow

**Baseline**:
- Comprehensive project analysis MUST be performed
- All major components MUST be documented in baseline-spec.md
- Current state MUST enumerate all changes by workflow type
- Swift version, iOS target, frameworks MUST be accurately captured

**Feature Development**:
- Specification MUST be complete with prioritized user stories before planning
- Plan MUST pass Principle VI complexity check before task generation
- Tests MUST be written and FAIL before implementation (Principle III)
- Each user story MUST be independently testable and deliverable as MVP increment
- Code review MUST verify Swift 6 concurrency compliance (Principle V)

**Bugfix**:
- Bug reproduction MUST be documented with exact steps to reproduce
- Regression test MUST be written and verified to FAIL before fix is applied
- Root cause MUST be identified (race condition, logic error, API misuse, etc.)
- Prevention strategy MUST be defined (new protocol contract, additional validation, architectural change)

**Enhancement**:
- Enhancement MUST be scoped to single-phase plan with ≤7 tasks
- Changes MUST fit within existing architecture (no new modules/protocols)
- Swift Testing tests MUST be added for new behavior
- If complexity exceeds single-phase scope (>7 tasks, new protocols, multiple modules), MUST use full feature workflow instead

**Modification**:
- Impact analysis MUST identify all affected files, protocols, and Sendable contracts
- Original feature spec MUST be linked in modification.md
- Backward compatibility MUST be assessed (breaking protocol changes require major version bump)
- Migration path MUST be documented if changes break existing consumers

**Refactor**:
- Baseline metrics MUST be captured before changes (test count, file LOC, cyclomatic complexity) unless explicitly exempted
- Swift Testing tests MUST pass after EVERY incremental change
- Behavior preservation MUST be guaranteed (no test logic changes, only refactoring)
- Target metrics MUST show measurable improvement (reduced complexity, improved performance) unless explicitly exempted

**Hotfix**:
- Severity MUST be assessed (P0: data loss/crashes, P1: broken core features, P2: degraded UX)
- Rollback plan MUST be prepared (git revert strategy, feature flag toggle)
- Fix MUST be deployed and verified in production before writing tests (exception to Principle III)
- Swift Testing tests MUST be added within 48 hours of deployment
- Post-mortem MUST be completed within 48 hours identifying root cause and prevention

**Deprecation**:
- Dependency scan MUST identify all code referencing deprecated feature (grep, symbol search)
- Migration guide MUST be created before Phase 1 (alternative APIs, code examples)
- Three phases MUST complete in sequence:
  - Phase 1: Add deprecation warnings (compile-time @available annotations)
  - Phase 2: Disable feature (runtime toggles, throw errors on use)
  - Phase 3: Remove code completely (delete files, update imports)
- Stakeholder approvals MUST be obtained before starting (product owner, affected teams)

## Technology Standards

### Platform Requirements

- **iOS Target**: 18.0+ (allows modern SwiftUI and Swift Concurrency APIs)
- **Swift Version**: 6.1+ with strict concurrency checking enabled
- **Xcode Version**: 16.0+ required for Swift 6 toolchain
- **Architecture**: Protocol-oriented SPM packages + thin app wrapper

### Framework Usage

- **UI**: SwiftUI exclusively (@Observable, @State, @Environment, .task modifier)
- **Concurrency**: Swift Concurrency (async/await, actors, @MainActor) - NO DispatchQueue/GCD
- **Testing**: Swift Testing (@Test, #expect, #require) - NO XCTest for new code
- **Persistence**: UserDefaults for simple data, SwiftData for complex relational data (NO CoreData)
- **Networking**: URLSession with async/await (NO Alamofire/third-party unless justified)

### Code Quality Standards

- **Sendable Conformance**: All types crossing actor boundaries MUST be Sendable (value types automatic, classes require @unchecked Sendable with thread-safety proof)
- **Error Handling**: Use Swift errors with specific error types (no String errors, no empty catch blocks)
- **Optionals**: Use guard let/if let (force unwrap ! only with compile-time guarantees)
- **Memory**: Use [weak self] in closures that escape, especially in .task or async contexts
- **Accessibility**: All interactive SwiftUI views MUST have accessibilityLabel and accessibilityIdentifier

## Governance

### Constitutional Authority

This constitution **supersedes all other development practices**. When conflicts arise:
1. Constitution principles take precedence
2. Project guidelines (CLAUDE.md) provide implementation details
3. Team conventions defer to both above

### Amendment Process

Constitution changes MUST:
1. Document the proposed change with rationale in a modification proposal
2. Identify affected workflows and quality gates
3. Obtain approval from project maintainers
4. Update constitution with semantic versioning:
   - **MAJOR**: Backward-incompatible principle removals or redefinitions
   - **MINOR**: New principles or materially expanded guidance
   - **PATCH**: Clarifications, wording improvements, typo fixes
5. Propagate changes to plan-template.md, spec-template.md, tasks-template.md
6. Update CLAUDE.md guidance file if implementation patterns change

### Compliance Review

All code reviews MUST verify:
- [ ] Principle III: Tests written first and failed before implementation
- [ ] Principle V: Swift 6 strict concurrency compliance (no data race warnings)
- [ ] Principle II: No ViewModel classes (uses @Observable or SwiftUI state)
- [ ] Principle IV: Public APIs defined as protocols with mock implementations
- [ ] Principle VI: Complexity justified in plan.md if exceeds simplicity threshold

### Workflow Enforcement

All development work MUST:
- Use appropriate speckit workflow (no ad-hoc changes without spec/plan)
- Pass quality gates for chosen workflow before proceeding to next phase
- Document any workflow deviations in tasks.md with explicit justification
- Link specs → plan → tasks for full traceability

### Runtime Development Guidance

For implementation details not covered in this constitution, consult `/Users/pmouli/GitHub.nosync/tab-cab/CLAUDE.md` which provides:
- Detailed SwiftUI patterns and @Observable usage examples
- Swift Concurrency best practices (.task vs Task, @Sendable closures)
- Swift Testing framework conventions
- Safari Extension specific requirements
- XcodeBuildMCP tool usage for build/test automation

**Version**: 1.0.0 | **Ratified**: 2025-12-24 | **Last Amended**: 2025-12-24
