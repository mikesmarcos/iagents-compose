## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues; external PRs are not a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage label names are used without overrides. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository. See `docs/agents/domain.md`.

### Branch protection

The `main` branch is protected; all changes arrive through pull requests. See `docs/agents/branch-protection.md`.

### Issue decomposition

Issues produced by `/to-issues` follow maximum atomicity for subagent compatibility. See `docs/agents/issue-decomposition.md`.
### GitHub accounts

The agent operates as two GitHub identities:

- **`mikeiagents`** (active, collaborator): the agent/developer persona. Used for pushing feature branches, opening pull requests, and day-to-day work. Token has `workflow` scope (can modify `.github/workflows/`).
- **`mikesmarcos`** (owner, admin): the repository owner. Used only for administrative commands: branch protection settings, repository visibility, merging PRs. Switch with `gh auth switch --user mikesmarcos` and switch back with `gh auth switch --user mikeiagents` after.

The default active account is `mikeiagents`. Switch to `mikesmarcos` only for admin actions, then switch back immediately.

## Subagent executors

This repo defines custom Codex subagents in `.codex/agents/` for atomic-issue implementation and review. Each model has two variants — **medium** and **high** reasoning effort — giving 22 agents total (14 dev + 8 test). Spawn by `name` (e.g. `spawn dev-deepseek-pro-medium`, `spawn dev-glm-high`).

**All agents set `model_provider = "fcc"`** — the universal proxy that serves both opencode_go and OpenAI models. Run the orchestrator via `fcc-codex` so subagents inherit the fcc provider. For non-interactive validation use `codex exec -c model_provider=fcc -m <model>`. See `docs/agents/model-providers.md` for the full provider guide and `scripts/test-subagent-models.sh` for the validation test suite.

### Dev executors (implementation)

Spawn a dev executor to implement a single atomic issue. Start at the cheapest model+effort that matches task complexity; escalate effort (medium → high) before jumping to a more expensive model. Dev executors commit on the current feature branch but do NOT push, open PRs, approve, or merge.

| Tier | Agent name (medium / high) | Model | Auth? |
|------|----------------------------|-------|-------|
| 1 (default) | `dev-deepseek-pro` / `dev-deepseek-pro-high` | `opencode_go/deepseek-v4-pro` | no |
| 1 (fast) | `dev-deepseek-flash` / `dev-deepseek-flash-high` | `opencode_go/deepseek-v4-flash` | no |
| 2 | `dev-minimax` / `dev-minimax-high` | `opencode_go/minimax-m3` | no |
| 3 | `dev-glm` / `dev-glm-high` | `opencode_go/glm-5.2` | no |
| 4 | `dev-gpt54-mini` / `dev-gpt54-mini-high` | `gpt-5.4-mini` | **yes** |
| 5 | `dev-gpt54` / `dev-gpt54-high` | `gpt-5.4` | **yes** |
| 6 | `dev-gpt55` / `dev-gpt55-high` | `gpt-5.5` | **yes** |

### Test executors (review, quality, security)

Spawn a test executor to review a diff, run the acceptance command, and report findings. Test executors never modify code; the orchestrator owns fixes.

| Tier | Agent name (medium / high) | Model | Auth? |
|------|----------------------------|-------|-------|
| 1 (default) | `test-minimax` / `test-minimax-high` | `opencode_go/minimax-m3` | no |
| 2 | `test-glm` / `test-glm-high` | `opencode_go/glm-5.2` | no |
| 3 | `test-gpt54` / `test-gpt54-high` | `gpt-5.4` | **yes** |
| 4 | `test-gpt55` / `test-gpt55-high` | `gpt-5.5` | **yes** |

### Authorization gate

Tiers labeled **yes** in Auth? use OpenAI models and may only be spawned after the user explicitly authorizes OpenAI-tier usage for the current run (e.g. "use gpt-5.4 high for dev" or "use gpt-5.5 medium for testing"). Default to the cheapest matching `opencode_go` tier first. The agent `description` and `developer_instructions` both encode the gate so the orchestrator surfaces it before spawning.

### Tier selection guide

- **Routine single-file YAML/Compose/script edits**: `dev-deepseek-pro` (or `dev-deepseek-flash`).
- **Escalate effort first**: if a medium-variant dev agent struggles, try its `*-high` sibling before jumping to a more expensive model.
- **Issues with interdependencies or cross-file refs**: `dev-minimax` (or `dev-minimax-high`).
- **Tricky multi-file, security-sensitive, or when prior tiers struggled**: `dev-glm` (or `dev-glm-high`).
- **Default for reviews**: `test-minimax`.
- **Escalate review effort for ACME/TLS/security-sensitive**: `test-minimax-high` or `test-glm`/`test-glm-high`.
- **Escalation to OpenAI tiers**: only on explicit user authorization. Reserve for cases where opencode_go tiers cannot resolve a blocker.

See `.codex/agents/` for the full agent definitions and `docs/agents/subagents.md` for the orchestration contract.
### Branch protection
