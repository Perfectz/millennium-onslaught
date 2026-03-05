# Release Process — Millennium Onslaught

> **Purpose:** Step-by-step release checklist for producing versioned builds.

---

## Version Convention

- `v0.X.Y` — MVP X, patch Y
- `v0.1.0` — MVP 1 release
- `v0.2.1` — MVP 2, first hotfix
- Tags on main branch only

## Pre-Release Checklist

1. [ ] All tests pass (`godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd`)
2. [ ] Smoke test passes (`bash tools/smoke_test.sh`)
3. [ ] No P0 or P1 issues open
4. [ ] INDEX.md up to date
5. [ ] DECISIONS.md up to date
6. [ ] Event catalog up to date
7. [ ] All new resource types have schema docs
8. [ ] Stress test results acceptable (PC: 60fps, Android: 30fps)
9. [ ] Manual playthrough completed on PC
10. [ ] Manual playthrough completed on Android (when applicable)

## Release Steps

1. Merge feature branch to develop
2. Run full test suite on develop
3. Merge develop to main
4. Tag: `git tag -a v0.X.Y -m "MVP X release"`
5. Push tag: `git push origin v0.X.Y`
6. CI builds automatically triggered
7. Download build artifacts from CI
8. Test build artifacts on target platforms
9. Update ROADMAP_EXECUTION_STATE.md

## Hotfix Process

See `docs/hotfix_playbook.md` for emergency fix procedures.

## Build Artifacts

| Platform | Location | Format |
|----------|----------|--------|
| Linux | `export/pc/linux/` | .x86_64 |
| Windows | `export/pc/windows/` | .exe |
| Android Debug | `export/android/` | .apk (debug) |
| Android Release | `export/android/` | .apk (release) |
