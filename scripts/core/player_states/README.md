# scripts/core/player_states/

## Purpose
Player state machine states. Each file implements one state for `PlayerController`'s `StateMachine`. States are `RefCounted` — they receive the controller as context and return transition requests.

## States

| State | File | Transitions To |
|-------|------|----------------|
| Idle | `player_state_idle.gd` | Run, Jump, AttackLight, AttackHeavy, AttackLauncher, Technique, Dodge, Hurt, Dead |
| Run | `player_state_run.gd` | Idle, Jump, AttackLight, AttackHeavy, AttackLauncher, Technique, Dodge, Hurt |
| Jump | `player_state_jump.gd` | Fall, Hurt |
| Fall | `player_state_fall.gd` | Land, Hurt |
| Land | `player_state_land.gd` | Idle |
| AttackLight | `player_state_attack_light.gd` | Idle, AttackLight (chain), AttackHeavy (cancel), AttackLauncher (cancel), Dodge (cancel), Hurt |
| AttackHeavy | `player_state_attack_heavy.gd` | Idle, Dodge (cancel), Hurt |
| AttackLauncher | `player_state_attack_launcher.gd` | Idle, Dodge (cancel), Jump (cancel), Hurt |
| Technique | `player_state_technique.gd` | Idle, Hurt |
| Dodge | `player_state_dodge.gd` | Idle |
| Hurt | `player_state_hurt.gd` | Idle, Dead |
| Dead | `player_state_dead.gd` | (terminal) |

## Adding a New State
1. Create a new `player_state_*.gd` extending `State` (RefCounted)
2. Implement `enter()`, `physics_update()`, and optionally `exit()`
3. Register in `PlayerController._ready()` via `state_machine.add_state()`
4. Add transitions in source states
5. Update INDEX.md Player States table
