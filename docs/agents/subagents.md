# Subagent orchestration contract

This document defines how the orchestrator (main Codex thread) coordinates with the custom subagent executors defined in `.codex/agents/`. There are 22 agents: each model has two variants — **medium** and **high** reasoning effort. For the tier tables and authorization gate, see `AGENTS.md` → "Subagent executors".

## Roles

- **Orchestrator** (main thread, current model): owns the issue plan, branch creation, PR workflow (`gh pr create`/`review`/`merge`), tier selection, and the authorization gate for OpenAI-tier agents. Never delegates git-push, PR creation, approval, or merge to subagents.
- **Dev executor**: receives one atomic issue, implements it, runs the acceptance command, commits on the current feature branch, and returns a summary. Does not push, open PRs, approve, or merge.
- **Test executor**: receives a diff and the originating issue/PRD, runs acceptance, and reports findings with severity tags. Does not modify code or commit.

## Per-issue workflow

1. Orchestrator ensures `gh auth status` active account is `mikeiagents`, syncs `main`, creates the feature branch, and checks out the issue body via `gh issue view <N>`.
2. Orchestrator spawns a dev executor at the selected model+effort, passing the issue number and PRD #3 reference when the issue calls for design context. The dev executor implements, verifies with the issue's acceptance command, and commits.
3. Orchestrator spawns a test executor (default `test-minimax` medium) to review `git diff main...HEAD`, run the acceptance command, and report findings with severity tags.
4. If the test executor reports BLOCKER or HIGH findings, the orchestrator first escalates effort within the same model (medium → `*-high`), then escalates model tier. Re-runs from step 2.
5. When the test executor reports no BLOCKER/HIGH findings, the orchestrator proceeds to push, open the PR, wait for `pr-only-policy`, switch to `mikesmarcos`, approve, squash-merge, delete branch, switch back to `mikeiagents`, and sync `main`.

## Tier escalation rules

- Always start at the cheapest tier matching task complexity (see AGENTS.md "Tier selection guide").
- Escalate effort first (medium → high) within the same model before jumping to a more expensive model tier.
- Escalate one model tier at a time only when the high-effort variant is still insufficient or a BLOCKER remains after a fix attempt.
- Never spawn an OpenAI-tier agent (Auth? = yes) without explicit user authorization for that run.
- Test executors start at `test-minimax` (medium). Escalate to `test-minimax-high`, then `test-glm`/`test-glm-high` for ACME/TLS/security-sensitive reviews; escalate to `test-gpt54`/`test-gpt55` only with user authorization.
- Subagents inherit the orchestrator's sandbox policy and approval overrides.

## Context hygiene

- Dev executors return a summary, not raw command output. Long logs stay in the subagent thread.
- Test executors return a structured findings list (severity: file: finding), under 400 words.
- The orchestrator does not paste full subagent output back into the main context; it summarizes and acts.
- If context degrades mid-issue, the orchestrator runs `/handoff` and continues fresh.

## Built-in agents override

If a custom agent name matches a built-in (`default`, `worker`, `explorer`), the custom agent takes precedence. The agents in `.codex/agents/` use distinct names (`dev-*`, `test-*`) so built-ins remain available as fallbacks.
