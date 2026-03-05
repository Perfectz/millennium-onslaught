# Hotfix Playbook — Millennium Onslaught

> **Purpose:** Emergency fix process for critical issues discovered after release.

---

## Severity Classification

| Level | Definition | Response Time |
|-------|-----------|---------------|
| SEV-1 | Crash, data loss, save corruption | Immediate |
| SEV-2 | Gameplay blocker (can't progress) | Same day |
| SEV-3 | Major bug (wrong behavior, no workaround) | 1-2 days |
| SEV-4 | Minor bug (cosmetic, has workaround) | Next planned release |

---

## Hotfix Process

### 1. Triage
- [ ] Reproduce the issue
- [ ] Classify severity (SEV-1 through SEV-4)
- [ ] Identify affected systems (use CHANGE_SCOPE.md)
- [ ] Document reproduction steps

### 2. Branch
```bash
git checkout main
git checkout -b hotfix/<issue-description>
```

### 3. Fix
- [ ] Write failing test that reproduces the bug
- [ ] Implement minimum fix
- [ ] Verify fix passes the test
- [ ] Run full test suite
- [ ] Run smoke test

### 4. Review
- [ ] Check fix doesn't introduce new issues
- [ ] Verify fix stays within scope (CHANGE_SCOPE.md)
- [ ] Update DECISIONS.md if architectural implications

### 5. Release
```bash
git checkout main
git merge hotfix/<issue-description>
git tag -a v0.X.Y -m "Hotfix: <description>"
git push origin main --tags
```

### 6. Backport
```bash
git checkout develop
git merge main
```

---

## Common Failure Scenarios

### Scenario 1: Save File Corruption
**Symptoms:** Load fails, game shows error on startup.
**Investigation:**
1. Check save file JSON validity
2. Verify checksum (SaveMigration.verify_checksum)
3. Check if backup exists (`.backup` file)
**Fix:** Restore from backup, or run migration on corrupted data.

### Scenario 2: Crash on Scene Transition
**Symptoms:** Game crashes when entering dungeon/town/overworld.
**Investigation:**
1. Check EventBus ring buffer for last events
2. Look for null references in scene cleanup
3. Check ObjectPool for leaked instances
**Fix:** Add null guards, ensure proper scene cleanup.

### Scenario 3: Enemy AI Freeze
**Symptoms:** Enemies stop moving, stand in place.
**Investigation:**
1. Check AI state (F3 debug overlay)
2. Check attack token system
3. Verify target reference validity
**Fix:** Add is_instance_valid checks, reset AI state on target loss.

### Scenario 4: Performance Degradation
**Symptoms:** FPS drops below target during combat.
**Investigation:**
1. Run stress test (tools/stress_test.gd)
2. Check frame budget monitor (F4)
3. Check allocation tracker for per-frame allocations
**Fix:** Pool leaked objects, reduce particle counts, optimize hot path.

### Scenario 5: Input Not Responding
**Symptoms:** Player controls stop working in certain contexts.
**Investigation:**
1. Check InputManager context (F5)
2. Check process_mode on scene nodes
3. Verify input action mappings
**Fix:** Ensure correct context switch on phase change, fix process_mode.

---

## Post-Hotfix Checklist

- [ ] All tests pass
- [ ] Smoke test passes
- [ ] Hotfix tested on PC
- [ ] Hotfix tested on Android (if applicable)
- [ ] ROADMAP_EXECUTION_STATE.md updated
- [ ] Bug documented in DECISIONS.md (if architectural)
- [ ] Release tagged and pushed
- [ ] Build artifacts generated
