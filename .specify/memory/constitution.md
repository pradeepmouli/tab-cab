<!--
SYNC IMPACT REPORT (2025-12-24)
================================
Version: 1.0.0 (NEW - initial constitution established)
Rationale: Project transitioning from generic Swift template to Safari extension development

CHANGES FROM TEMPLATE:
- All 6 principles customized for Safari extension context
- Added Technical Stack & Requirements section (Safari-specific entitlements, deployment targets)
- Added Development Workflow section (feature planning, security review gates, app store submission)
- Enhanced Governance section with version policy and compliance review requirements

PRINCIPLES ADDED:
✓ I. Swift-First, Modern APIs Required
✓ II. Privacy-First Data Handling
✓ III. Test-First Architecture (NON-NEGOTIABLE)
✓ IV. Modular Architecture with SPM
✓ V. User-Centered Security & Permissions
✓ VI. Accessibility & Internationalization Standards

TEMPLATES CHECKED:
✓ .specify/templates/plan-template.md - No updates required (generic template)
✓ .specify/templates/spec-template.md - No updates required (generic template)
✓ .specify/templates/tasks-template.md - No updates required (generic template)
✓ .specify/templates/checklist-template.md - Not reviewed (depends on features added)
✓ .specify/templates/agent-file-template.md - Not reviewed (template for agent guidance)

RUNTIME GUIDANCE FILES REFERENCED:
✓ CLAUDE.md - Contains detailed Swift/SwiftUI architecture guidance (aligned with constitution)
✓ AGENTS.md - Contains agent-specific scope and workflow (generic, no updates needed)

NO INTENTIONALLY DEFERRED PLACEHOLDERS

FOLLOW-UP ACTIONS:
1. New specs should cite the Constitution Check gate in plan-template.md
2. PR reviews should validate compliance with VI principles
3. Feature tasks should include security review approval as a gate (Principle II)
4. Consider adding Safari extension-specific testing guidelines to CLAUDE.md if features added
-->

# Safari Extension Constitution

> **Purpose**: Establish non-negotiable principles for native Safari extension development targeting modern macOS/iOS platforms. This constitution ensures quality, security, maintainability, and user trust.

## Core Principles

### I. Swift-First, Modern APIs Required
All extension code MUST use Swift 6.1+ with SwiftUI. Legacy frameworks (UIViewController, NSViewController, AppKit) are prohibited except where Safari extension APIs mandate them. Swift Concurrency (async/await, actors, @MainActor) is mandatory for all asynchronous operations. Completion handlers and GCD are forbidden. Extensions MUST target macOS 15.0+ and iOS 18.0+ to access modern Safari APIs.

**Rationale**: Modern Swift ensures type safety, maintainability, and prevents entire categories of concurrency bugs. Older API patterns create technical debt and security risks in network-facing extensions.

### II. Privacy-First Data Handling
Extensions MUST NOT collect, store, or transmit user data beyond what is essential to the stated feature. All network requests require HTTPS only; HTTP is forbidden. Sensitive data (credentials, tokens, URLs) MUST use Keychain storage, never UserDefaults or local files. User consent MUST be explicitly requested for any cross-site tracking, history access, or site interaction. Regular security audits required (quarterly minimum).

**Rationale**: Safari extensions run with elevated privileges. Misuse of data triggers user distrust, app store rejection, and potential legal liability.

### III. Test-First Architecture (NON-NEGOTIABLE)
Swift Testing framework (@Test, #expect, #require) is the only accepted testing method. Unit tests MUST cover all public APIs, error paths, and permission-gated features. Integration tests MUST validate: (a) Safari content script injection, (b) communication between extension components, (c) network requests with mocked responses. Code coverage target: 80% minimum for critical paths, 60% minimum for utility code.

**Rationale**: Extensions are difficult to debug after deployment (limited access to app store reports). Tests prevent silent failures and regressions.

### IV. Modular Architecture with SPM
All extension logic resides in Swift Package libraries (not in the extension target directly). Extensions import library products. Each major feature gets its own SPM target with isolated tests. Shared code lives in common libraries. Extension targets themselves contain only entry points (@main, content script injectors, message handlers).

**Rationale**: Testability, reusability across macOS/iOS extensions, clear dependencies, and easier maintenance.

### V. User-Centered Security & Permissions
Every permission requested MUST be documented in Info.plist with justified rationale. Over-privileged extensions are rejected from app store review. Extension must gracefully degrade when permissions are denied. Regular permission audits ensure no creep. Content script injection is sandboxed and never executes arbitrary user input.

**Rationale**: Prevents user backlash, meets Apple's privacy requirements, and maintains trust.

### VI. Accessibility & Internationalization Standards
All UI elements MUST have accessibility labels. VoiceOver support is mandatory. Strings are externalized using Localizable.strings; hard-coded strings are forbidden. Right-to-left (RTL) language support must be verified for all layouts. Accessibility tests required for UI features.

**Rationale**: Ensures usability for all users and meets app store accessibility guidelines.

## Technical Stack & Requirements

**Language**: Swift 6.1+ only; no Objective-C or hybrid code.
**UI Frameworks**: SwiftUI for all UI; AppKit/UIKit only if Safari extension APIs require it.
**Concurrency**: Swift Concurrency (async/await, actors, @MainActor); no GCD or completion handlers.
**Package Management**: Swift Package Manager (SPM); no CocoaPods or Carthage.
**Testing**: Swift Testing framework only (@Test, @Suite, #expect, #require).
**Minimum Deployment**: macOS 15.0, iOS 18.0.
**Entitlements**: Safari extension entitlements only; no keychain-access-groups, location, camera, microphone without explicit user consent.
**Build System**: Xcode 16+; no custom build scripts unless unavoidable.

## Development Workflow

1. **Feature Planning**: Every feature begins with a spec (see `plan-template.md` + Constitution Check gate).
2. **Test First**: Write Swift Testing tests before implementation. Tests must be approved by security review for permission-gated features.
3. **Implementation in SPM**: All logic in library targets; integration target stays thin.
4. **Code Review**: Every PR requires review of: (a) security implications, (b) test coverage, (c) permission usage, (d) accessibility.
5. **Integration Testing**: Run full test suite on macOS and iOS before merge.
6. **App Store Submission**: Security audit + accessibility audit before submitting to app store.

## Governance

**Constitution Supremacy**: This constitution supersedes all other practices, guidelines, and conventions.

**Amendments**: Changes to this document require:
- Written justification (why current principle is inadequate)
- Proposed new or modified principle
- Migration plan for existing code (if breaking change)
- Version bump and documented rationale

**Version Policy**: MAJOR.MINOR.PATCH
- MAJOR: Principle removal, redefinition, or new required capability
- MINOR: New principle added, non-breaking clarity expansions
- PATCH: Wording, typo, or rationale-only clarifications

**Compliance Review**: Every PR must cite which principle(s) it adheres to. No changes without clear constitution alignment.

**Runtime Guidance**: See [CLAUDE.md](CLAUDE.md) and [AGENTS.md](AGENTS.md) for implementation details, code style, and agent-specific workflows.

**Version**: 1.0.0 | **Ratified**: 2025-12-24 | **Last Amended**: 2025-12-24
