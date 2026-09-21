# Repository Guidelines

This repository is an early Flutter/Dart mobile scaffold for Timelines. The current app is a minimal Material UI; product scope and delivery decisions live in the foundation documents referenced below. See @README.md and @pubspec.yaml for the project baseline.

## Hard Rules

- Never edit `context/archive/`; archived work is immutable. Start a new change under `context/changes/` instead.
- Read @CLAUDE.md before using the repository's 10x workflow or changing its agent-facing documentation.
- Before changing product scope or the stack, consult @context/foundation/prd.md, @context/foundation/mvp-notes.md, and @context/foundation/tech-stack.md.

## Project Structure

- Put Dart application code under `lib/`; the current entry point and widget scaffold are @lib/main.dart.
- `android/`, `ios/`, and `web/` contain platform targets. `context/foundation/` contains product and stack decisions; `context/changes/` contains change verification notes.
- There is no `.github/workflows/` CI configuration yet.

## Build, Test, and Development

- Run `flutter pub get` after dependency changes in @pubspec.yaml.
- Run `flutter analyze` before reporting the task complete; it currently passes using @analysis_options.yaml and `flutter_lints`.
- Run `flutter test` when Dart tests exist; the repository currently has no `test/` directory.

## Testing

Add Dart tests under `test/` so `flutter test` discovers them; platform-specific tests remain with their platform target.

## Commits

Recent history uses short, lowercase summaries such as `init app` and `new skills`; no Conventional Commits prefix is established. Report `flutter analyze` and `flutter test` results in the final task or PR description because no CI gate currently exists.
