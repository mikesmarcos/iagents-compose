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

Issues produced by `/to-issues` follow maximum atomicity for agent compatibility. See `docs/agents/issue-decomposition.md`.

### Personal harness configuration

This repo documents project invariants, not personal harness preferences. Keep model/provider choices, authentication, account switching, agent roles, MCPs, skills, commands, plugins, and local permissions outside the repo. See `docs/adr/0004-keep-personal-harness-configuration-out-of-the-repo.md`.
