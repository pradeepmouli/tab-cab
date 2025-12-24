# Agents Usage in This Swift Template

This repository is designed to work smoothly with AI coding agents (e.g., Copilot in VS Code). Agents should adhere to the following:

## Scope and Safety
- Operate surgically: keep changes minimal and focused.
- Follow project preferences from `swift.instructions.md` (Swift 6, SPM, Swift Concurrency, XCTest).
- Avoid adding heavy dependencies unless justified; prefer Apple/Swift.org packages.
- Do not add license headers unless explicitly requested.

## File Operations
- Use SPM structure: `Package.swift`, `Sources/`, `Tests/`.
- Place executable code in `Sources/App/` with entry in `main.swift`.
- Add tests in `Tests/AppTests/` using XCTest (async supported).
- Configuration in `Config/*.xcconfig`, style in `.swiftlint.yml`.

## Coding Guidelines for Agents
- Prefer `struct` over `class`; explicit access control.
- Use `async/await`, `TaskGroup`, `Actor` when suitable.
- Use `Result` for sync error flows; throw errors for clarity in async.
- Serialization via `Codable` by default.
- Logging via `swift-log` (`Logging.Logger`).

## Testing
- Add unit tests for new logic; keep deterministic.
- Use async tests when concurrency is involved.
- Run `swift test` before proposing changes that rely on new logic.

## PR/Commit Hygiene
- Keep patches small and focused; avoid unrelated refactors.
- Update README when adding non-obvious behavior or setup steps.
- Respect existing naming and folder conventions.

## Runner
- Executable target name: `App` exposed as product `SwiftTemplate`.
- Quick run: `swift run SwiftTemplate`.
