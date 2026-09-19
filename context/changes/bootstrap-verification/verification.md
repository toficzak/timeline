---
bootstrapped_at: 2026-09-19T18:01:51Z
starter_id: flutter
starter_name: Flutter
project_name: timelines
language_family: dart
package_manager: pub
cwd_strategy: subdir-then-move
bootstrapper_confidence: verified
phase_3_status: ok
audit_command: "null"
---

## Hand-off

```yaml
starter_id: flutter
package_manager: pub
project_name: timelines
hints:
  language_family: dart
  team_size: solo
  deployment_target: playstore
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: custom
  quality_override: false
  self_check_answers:
    typed: true
    from_official_starter: true
    conventions: false
    docs_current: false
    can_judge_agent: false
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: true
  has_background_jobs: false
```

## Why this stack

Flutter is a verified mobile starter suited to a solo developer delivering a small Android MVP in seven weeks. It provides a single Dart codebase, strong support for mobile UI, camera and gallery integrations, and a practical path to Google Play distribution. The project includes Google authentication and a focused AI comparison feature, so those capabilities are recorded for the bootstrapper. Kotlin/Android was considered but has no registered starter, while Flutter provides a supported scaffold and keeps Android Studio as a valid IDE. GitHub Actions with auto-build after merge supports a simple delivery workflow.

## Pre-scaffold verification

| Signal | Value | Severity | Notes |
| --- | --- | --- | --- |
| npm package | not run | n/a | non-JS starter |
| GitHub repo | not run | n/a | docs_url is https://flutter.dev/docs, not a GitHub repository URL |

## Scaffold log

**Resolved invocation**: `flutter create -e bootstrap_scaffold --org com.example --platforms android,ios,web`
**Strategy**: subdir-then-move; temporary directory override used for this run
**Exit code**: 0
**Files moved**: 97
**Conflicts (.scaffold siblings)**: `.idea/modules.xml` → `.idea/modules.xml.scaffold`, `.idea/workspace.xml` → `.idea/workspace.xml.scaffold`
**.gitignore handling**: moved silently
**.bootstrap-scaffold cleanup**: deleted; temporary directory used was `bootstrap_scaffold`

### File transfer record

The Flutter CLI reported 81 generated files. The merge moved 97 files after generated and tool metadata files were enumerated. Existing files were preserved according to the conflict policy; `context/**` was preserved without importing scaffold content.

## Post-scaffold audit

**Tool**: skipped — no built-in audit tool for dart
**Recommended external tool**: use `dart pub outdated --mode=null-safety` as the closest available stand-in, and configure a dedicated dependency/security tool separately if needed.

## Hints recorded but not acted on

| Hint | Value |
| --- | --- |
| bootstrapper_confidence | verified |
| quality_override | false |
| path_taken | custom |
| self_check_answers | typed: true; from_official_starter: true; conventions: false; docs_current: false; can_judge_agent: false |
| team_size | solo |
| deployment_target | playstore |
| ci_provider | github-actions |
| ci_default_flow | auto-deploy-on-merge |
| has_auth | true |
| has_payments | false |
| has_realtime | false |
| has_ai | true |
| has_background_jobs | false |

## Next steps

Next: a future skill will set up agent context (CLAUDE.md, AGENTS.md). For now, your project is scaffolded and verified — happy hacking.

Useful manual steps in the meantime:
- `git init` (if you have not already) to start your own repo history.
- Review `.idea/modules.xml.scaffold` and `.idea/workspace.xml.scaffold` and decide which versions to keep.
- Consider running a Dart dependency review with an external tool.
