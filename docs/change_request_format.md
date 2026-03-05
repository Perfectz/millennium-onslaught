# Change Request Format — AI Development

> **Purpose:** Template for AI change requests to ensure scope discipline and prevent unintended side effects.

---

## Template

```markdown
## Change Request: [Short Title]

### Scope
- **Feature Area(s):** [From CHANGE_SCOPE.md]
- **Files to Modify:** [List specific files]
- **Files to Create:** [If any]
- **Files to Delete:** [If any]

### Description
[What change is being made and why]

### Impact
- **Signals Added/Modified:** [List any EventBus changes]
- **Constants Added/Modified:** [List any Constants changes]
- **Tests Added/Modified:** [List test files]
- **Documentation Updated:** [List doc files]

### Verification
- [ ] Tests pass
- [ ] Smoke test passes
- [ ] Changes stay within declared scope
- [ ] No hardcoded values introduced
- [ ] Event bus used for cross-system communication
- [ ] INDEX.md updated if new systems added
```

---

## Rules

1. **Declare scope before coding.** List affected files before making changes.
2. **Stay in scope.** If you need to touch files outside your declared scope, add them to the scope declaration first and explain why.
3. **One feature area per change.** Keep changes focused. Multiple features = multiple change requests.
4. **Test what you change.** Every modified system must have corresponding test updates.
5. **Document what you add.** New systems need INDEX.md entries. New signals need event_catalog.md entries.
