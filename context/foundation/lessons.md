# Lessons Learned

> Append-only register of recurring rules and patterns. Re-read at start by /10x-frame, /10x-research, /10x-plan, /10x-plan-review, /10x-implement, /10x-impl-review.

## Confirm manual tests are executable before requesting them

- **Context**: manual tests
- **Problem**: Asking me to perform manual tests when the current application state does not allow them—for example, checking a view with local-storage data when there is no way to add that data yet.
- **Rule**: Do not ask me to perform manual tests on things I cannot yet check due to blockers or no way of checking them. Double-check whether manual tests are meaningful before requesting them.
- **Applies to**: implement
