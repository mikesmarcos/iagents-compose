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

### Branch protection
